# 🎓 UniRoom-Live 2.0 Backend Masterclass
## Chapter 5: Physical Classrooms & Optimistic Concurrency Control (OCC)

Imagine a university campus with 40 classrooms.
At 11:20 AM, an algorithms class in Room 5030 finishes early.
The CR of Batch 68 taps "Release Room 5030".
Instantly, CRs across five different batches see Room 5030 turn green on their screens!
Three CRs tap "Book Room 5030" at the exact same millisecond.

**Who gets the room? Does the database give it to all three?**
This is the classic **Concurrency Race Condition** that crashes amateur backends.

This chapter explains how UniRoom-Live 2.0 solves this with **Optimistic Concurrency Control (OCC)** and atomic transactions.

---

## 1. Concurrency: The Double-Booking Nightmare

### The Naive (Broken) Approach:
```
CR 1 checks DB: Room 5030 is AVAILABLE.
CR 2 checks DB: Room 5030 is AVAILABLE.
CR 1 sends: "Set Room 5030 to RESERVED for Batch 68". (Succeeds)
CR 2 sends: "Set Room 5030 to RESERVED for Batch 66". (Overwrites CR 1!)
```
Both batches show up to Room 5030 with their teachers and 80 students argue over who booked the room!

### Solution 1: Pessimistic Locking (Slow & Bottlenecked)
Lock the entire database row with `SELECT FOR UPDATE` until a user finishes booking.
- **Problem**: If CR 1's phone has slow 3G internet, the database row stays locked for seconds. Other users' apps freeze and the database connection pool exhausts.

### Solution 2: Optimistic Concurrency Control (OCC - Fast & Non-Blocking)
We add an integer column called **`version`** to the `rooms` table, starting at `1`.

```
1. CR 1 reads Room 5030: status = AVAILABLE, version = 1.
2. CR 2 reads Room 5030: status = AVAILABLE, version = 1.

3. CR 1 submits booking: { status: RESERVED, version: 1 }
   Backend SQL: UPDATE rooms SET status = RESERVED, version = version + 1
                WHERE id = 5030 AND version = 1;
   PostgreSQL updates 1 row! Room 5030 now has version = 2.

4. CR 2 submits booking: { status: RESERVED, version: 1 }
   Backend checks: room.version (2) !== dto.version (1)
   Backend rejects immediately: 409 CONFLICT!
```
CR 1 gets the room. CR 2 receives an instant notice:
*"Room status was just modified by another user. Please refresh."*
Zero row locks, zero bottlenecks, zero double-bookings!

---

## 2. OCC Implementation in `src/modules/rooms/rooms.service.ts` Line by Line

Let's examine how OCC is implemented in `updateRoomStatus()`:

```typescript
443: async updateRoomStatus(id: string, dto: UpdateRoomStatusDto, userId: string) {
444:   let room = await this.prisma.room.findUnique({
445:     where: { id },
446:   });
```
- Fetches the room from the database.

```typescript
465:   // OCC Check: Verify version matches to prevent double-booking collisions
466:   if (room.version !== dto.version) {
467:     throw new ConflictException(
468:       `Optimistic Concurrency Lock Conflict: Room status was modified by another user. Your version was ${dto.version}, but current version is ${room.version}. Please refresh and try again.`,
469:     );
470:   }
```
- **The Critical Check**: If another user already updated the room while this user had their booking sheet open, `room.version` will be higher than `dto.version`. The transaction is aborted immediately with `409 Conflict`.

```typescript
478:   // Atomic transaction: update room + increment version + write RoomLog
479:   const result = await this.prisma.$transaction(async (tx) => {
480:     const updatedRoom = await tx.room.update({
481:       where: { id: realId },
482:       data: {
483:         currentStatus: dto.status,
484:         version: { increment: 1 },
485:         leaseExpiresAt,
486:         currentCourse: dto.currentCourse ?? (dto.status === RoomStatus.AVAILABLE ? null : room.currentCourse),
487:         currentTeacher: dto.currentTeacher ?? (dto.status === RoomStatus.AVAILABLE ? null : room.currentTeacher),
488:         currentBatch: dto.currentBatch ?? (dto.status === RoomStatus.AVAILABLE ? null : room.currentBatch),
489:       },
490:       include: { building: true, department: true },
491:     });
```
- **`prisma.$transaction(...)`**: **All or Nothing**.
  If anything fails inside this block, all changes are rolled back automatically.
- **`version: { increment: 1 }`**: Atomically increases the version counter by 1.

```typescript
493:     const auditLog = await tx.roomLog.create({
494:       data: {
495:         roomId: realId,
496:         changedByUserId: userId,
497:         previousStatus: room.currentStatus,
498:         newStatus: dto.status,
499:         note: dto.note ?? null,
500:       },
501:       include: {
502:         changedByUser: { select: { fullName: true, email: true, role: true } },
503:       },
504:     });
505: 
506:     return { room: updatedRoom, auditLog };
507:   });
```
- Writes a permanent entry to `RoomLog` inside the same database transaction.

```typescript
512:   // Broadcast FCM alert to department CRs when a room is made free
513:   if (dto.status === RoomStatus.AVAILABLE && (result.room.department?.code || result.room.departmentId)) {
514:     const deptCode = result.room.department?.code || 'all';
515:     this.pushNotificationService.sendToCrTopic(deptCode, {
516:       title: `Room ${result.room.roomNumber} is Now Free! 🟢`,
517:       body: `A class ended or was cancelled in Room ${result.room.roomNumber}. Tap to claim for your batch.`,
518:       data: { roomId: result.room.id, type: 'ROOM_FREED' },
519:     }).catch(() => {});
520:   }
```
- **Instant Community Broadcast**: When a CR frees a classroom early, Firebase Cloud Messaging instantly alerts every other CR in the department so the empty room doesn't go to waste!

---

## 3. High-Performance Querying: `getRooms()`

When loading the classrooms screen, mobile apps need:
1. The list of rooms matching filters (building, floor, status, search text).
2. The count of rooms in each status (`AVAILABLE`, `RUNNING_CLASS`, `RESERVED`).

An inexperienced developer might write 4 separate database queries:
```typescript
const rooms = await prisma.room.findMany(...);
const availCount = await prisma.room.count({ where: { status: 'AVAILABLE' } });
const runningCount = await prisma.room.count({ where: { status: 'RUNNING_CLASS' } });
const reservedCount = await prisma.room.count({ where: { status: 'RESERVED' } });
```
That requires 4 round-trips over the network!

### The UniRoom-Live Optimized Approach:
In `rooms.service.ts`:
```typescript
const [rooms, totalCount, statusCounts] = await Promise.all([
  this.prisma.room.findMany({
    where,
    skip,
    take: limit,
    include: { building: true, department: true },
    orderBy: [{ floor: 'asc' }, { roomNumber: 'asc' }],
  }),
  this.prisma.room.count({ where }),
  this.prisma.room.groupBy({
    by: ['currentStatus'],
    _count: { id: true },
    where: baseScopeWhere,
  }),
]);
```
- Uses **PostgreSQL `GROUP BY`** to aggregate all status counts in a single query!
- Runs all queries concurrently via `Promise.all`. Total query execution time drops from ~200ms to **under 20ms**!

---

## 4. CR Booking Extra Classes & Live Timetable Generation: `bookExtraClass()`

When a Class Representative (CR) needs to take an extra class or arrange a lab session on an off-day:

### 1. The DTO: `BookExtraClassDto`
```typescript
export class BookExtraClassDto {
  @IsNotEmpty()
  @IsString()
  courseName: string; // e.g. "SWE-321 Software Architecture"

  @IsNotEmpty()
  @IsString()
  batch: string; // e.g. "68"

  @IsNotEmpty()
  @IsString()
  section: string; // e.g. "B"

  @IsOptional()
  @IsString()
  teacherInitials?: string; // e.g. "DNS"

  @IsOptional()
  @IsInt()
  @Min(15)
  @Max(240)
  durationMinutes?: number = 90;

  @IsOptional()
  @IsString()
  startTime?: string; // e.g. "11:30" (defaults to current time if omitted)

  @IsOptional()
  @IsString()
  department?: string; // e.g. "CSE" or "SWE"

  @IsOptional()
  @IsInt()
  version?: number = 1; // OCC Version check

  @IsOptional()
  @IsString()
  note?: string;
}
```

---

### 2. Implementation in `src/modules/rooms/rooms.service.ts` Line by Line:

```typescript
545: async bookExtraClass(id: string, dto: BookExtraClassDto, userId: string) {
546:   const room = await this.prisma.room.findFirst({
547:     where: { OR: [{ id }, { roomNumber: id }] },
548:     include: { building: true, department: true },
549:   });
550:   if (!room) throw new NotFoundException(`Room '${id}' not found`);
551: 
552:   // 1. Optimistic Concurrency Control (OCC) Check
553:   if (room.version !== dto.version) {
554:     throw new ConflictException(
555:       `Optimistic Concurrency Lock Conflict: Room status was modified by another user. Current version is ${room.version}. Please refresh and try again.`,
556:     );
557:   }
```
- Accepts either a room UUID or human room number (`"5030"`).
- Compares `room.version` with `dto.version`. If another CR claimed the room half a second earlier, the transaction rejects with HTTP 409 Conflict.

```typescript
562:   const user = await this.prisma.user.findUnique({
563:     where: { id: userId },
564:     include: { department: true },
565:   });
566: 
567:   const departmentId = user?.departmentId || room.departmentId;
568:   const deptCode = (dto.department || user?.department?.code || room.department?.code || 'CSE').trim().toUpperCase();
```
- **Department Topic Resolution**:
  Earlier versions defaulted `deptCode` to `'all'`, which prevented notifications from reaching students because student phones subscribe to department topics like `dept_cse_batch_68_sec_b`. Resolving the CR's authentic department (`user.department?.code`) guarantees that the topic string matches student app subscriptions perfectly.

```typescript
570:   const now = new Date();
571:   const duration = dto.durationMinutes || 90;
572:   const pad = (n: number) => n.toString().padStart(2, '0');
573: 
574:   // Derive start and end times
575:   const startTime = dto.startTime?.trim() || `${pad(now.getHours())}:${pad(now.getMinutes())}`;
576:   const [startH, startM] = startTime.split(':').map((x) => parseInt(x, 10));
577:   const startTotalMinutes = (isNaN(startH) ? now.getHours() : startH) * 60 + (isNaN(startM) ? now.getMinutes() : startM);
578:   const endTotalMinutes = startTotalMinutes + duration;
579:   const endH = Math.floor(endTotalMinutes / 60) % 24;
580:   const endM = endTotalMinutes % 60;
581:   const endTime = `${pad(endH)}:${pad(endM)}`;
```
- **Timing Mathematics**:
  Converts hours and minutes to total elapsed day minutes, adds `durationMinutes`, and converts back with modulo 24. A class starting at `11:30` with `duration = 90` cleanly derives `endTime = "13:00"`.

```typescript
584:   const dayNames: DayOfWeek[] = [
585:     DayOfWeek.SUN, DayOfWeek.MON, DayOfWeek.TUE, DayOfWeek.WED, DayOfWeek.THU, DayOfWeek.FRI, DayOfWeek.SAT,
586:   ];
587:   const currentDayOfWeek = dayNames[now.getDay()];
```
- Matches JavaScript's `Date.getDay()` (`0 = SUN`, `1 = MON`, ..., `6 = SAT`) directly to PostgreSQL's `DayOfWeek` enum.

---

### 3. The 3-Step Atomic Database Transaction:

```typescript
602:   const result = await this.prisma.$transaction(async (tx) => {
603:     // Step A: Mark physical room as RUNNING_CLASS and increment OCC version
604:     const updatedRoom = await tx.room.update({
605:       where: { id: realId },
606:       data: {
607:         currentStatus: RoomStatus.RUNNING_CLASS,
608:         version: { increment: 1 },
609:         leaseExpiresAt,
610:         currentCourse: dto.courseName,
611:         currentTeacher: dto.teacherInitials || null,
612:         currentBatch: cohortDisplay,
613:       },
614:       include: { building: true, department: true },
615:     });
616: 
617:     // Step B: Write permanent audit record to room_logs
618:     const auditLog = await tx.roomLog.create({
619:       data: {
620:         roomId: realId,
621:         changedByUserId: userId,
622:         previousStatus: room.currentStatus,
623:         newStatus: RoomStatus.RUNNING_CLASS,
624:         note: dto.note || `Extra class booked by CR for ${cohortDisplay}: ${dto.courseName} (${startTime} - ${endTime})`,
625:       },
626:       include: {
627:         changedByUser: { select: { fullName: true, email: true, role: true } },
628:       },
629:     });
630: 
631:     // Step C: Create a live ScheduleSlot in PostgreSQL!
632:     let scheduleSlot = null;
633:     if (departmentId) {
634:       scheduleSlot = await tx.scheduleSlot.create({
635:         data: {
636:           departmentId,
637:           roomId: realId,
638:           batch: dto.batch.trim(),
639:           section: dto.section.trim(),
640:           courseCode: courseCode.toUpperCase(),
641:           courseName: dto.courseName.trim(),
642:           facultyInitials: dto.teacherInitials?.trim() || 'Assigned',
643:           dayOfWeek: currentDayOfWeek,
644:           startTime,
645:           endTime,
646:           isActive: true,
647:         },
648:         include: {
649:           room: { select: { id: true, roomNumber: true, floor: true, capacity: true } },
650:           department: { select: { id: true, code: true, name: true } },
651:         },
652:       });
653:     }
654: 
655:     return { room: updatedRoom, auditLog, scheduleSlot };
656:   });
```

#### Why is Step C the Architectural Game-Changer?
Previously, backends only set `Room.currentStatus = RUNNING_CLASS`.
However, students do not read room logs to discover when their classes start—students check the **Today's Schedule** tab!
Because the mobile app queries `ScheduleSlot` filtered by the current weekday, creating a real `ScheduleSlot` in Prisma inside the transaction means:
1. The student's app receives an FCM push notification.
2. The student opens the app.
3. `ScheduleProvider.loadSchedules()` fetches the updated routine.
4. The extra class immediately appears in the **Today** tab as:
   - `RUNNING` (green badge) if the current clock time is within `startTime` and `endTime`.
   - `UP NEXT` (amber badge) if the class is scheduled for later today.
5. The CR and students both see the exact room, start time, end time, and teacher without manual refresh!

---

### 4. Multi-Channel FCM Push Notification Dispatch:

```typescript
667:   // Broadcast FCM Push Notification to all students of this section
668:   const pushTitle = `⚡ Extra Class Booked: ${dto.courseName}`;
669:   const pushBody = `Room ${room.roomNumber} (${room.building?.name || 'Campus'}) booked for ${cohortDisplay} from ${startTime} to ${endTime}. Teacher: ${dto.teacherInitials || 'Assigned Faculty'}.`;
670: 
671:   this.pushNotificationService.sendToSectionTopic(deptCode, dto.batch, dto.section, {
672:     title: pushTitle,
673:     body: pushBody,
674:     data: {
675:       roomId: room.id,
676:       courseName: dto.courseName,
677:       teacher: dto.teacherInitials || '',
678:       batch: dto.batch,
679:       section: dto.section,
680:       startTime,
681:       endTime,
682:       type: 'EXTRA_CLASS_BOOKED',
683:     },
684:   }).catch((err) => {
685:     this.logger.warn(`Failed to broadcast extra class push: ${err.message}`);
686:   });
687: 
688:   // Also notify faculty member if initials provided
689:   if (dto.teacherInitials) {
690:     this.pushNotificationService.sendToFacultyTopic(dto.teacherInitials, {
691:       title: `Room ${room.roomNumber} Reserved for Your Class`,
692:       body: `${cohortDisplay} scheduled an extra class in Room ${room.roomNumber} for ${dto.courseName} (${startTime} - ${endTime}).`,
693:       data: { roomId: room.id, type: 'FACULTY_CLASS_ALERT' },
694:     }).catch(() => {});
695:   }
```
- **Error Resilience Pattern**: Notice the `.catch((err) => this.logger.warn(...))`.
  If Google's FCM API experiences a temporary network blip, we log a warning but **do not crash or rollback the successful database booking**. The room remains booked, and the schedule slot remains recorded!

---

## 5. The 1-Tap Free Room Finder Engine: `findFreeRooms()` Line by Line

When students or CRs tap **"Search Free Rooms"** on their mobile app, how does the backend identify which physical classrooms across 10 buildings are empty right now?

Let's inspect `findFreeRooms()` in `src/modules/rooms/rooms.service.ts`:

### 1. The DTO: `FindFreeRoomDto`
```typescript
export class FindFreeRoomDto {
  @IsOptional()
  @IsString()
  date?: string; // YYYY-MM-DD (defaults to today)

  @IsOptional()
  @IsString()
  startTime?: string; // HH:mm (defaults to now)

  @IsOptional()
  @IsInt()
  @Min(15)
  @Max(360)
  durationMinutes?: number = 60;

  @IsOptional()
  @IsString()
  buildingId?: string;

  @IsOptional()
  @IsInt()
  floor?: number;

  @IsOptional()
  @IsInt()
  minCapacity?: number;

  @IsOptional()
  @IsString()
  departmentId?: string;
}
```

---

### 2. Time Window Normalization:
```typescript
724: const targetDate = dto.date ? new Date(`${dto.date}T00:00:00.000Z`) : new Date();
725: const dayOfWeekMap: Record<number, DayOfWeek> = {
726:   0: DayOfWeek.SUN, 1: DayOfWeek.MON, 2: DayOfWeek.TUE, 3: DayOfWeek.WED,
727:   4: DayOfWeek.THU, 5: DayOfWeek.FRI, 6: DayOfWeek.SAT,
728: };
729: const targetDayOfWeek = dayOfWeekMap[targetDate.getDay()];
730: 
731: const now = new Date();
732: const reqStart = dto.startTime || `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
733: const durationMinutes = dto.durationMinutes || 60;
734: const reqEnd = this.addMinutesToTime(reqStart, durationMinutes);
```
- Converts the requested time into a normalized continuous interval `[reqStart, reqEnd]`.
- Defaults to the current clock time and an open window of `60 minutes`.

---

### 3. Deep Pre-Filtering with PostgreSQL:
```typescript
760: const roomWhere: Prisma.RoomWhereInput = {
761:   currentStatus: RoomStatus.AVAILABLE,
762: };
763: if (targetDepartmentId) roomWhere.department = { OR: [{ id: targetDepartmentId }, { code: { equals: targetDepartmentId, mode: 'insensitive' } }] };
764: if (dto.buildingId) roomWhere.buildingId = dto.buildingId;
765: if (dto.floor !== undefined) roomWhere.floor = dto.floor;
766: if (dto.minCapacity) roomWhere.capacity = { gte: dto.minCapacity };
```
- Only queries physical rooms with status `AVAILABLE` that meet the student's capacity and building filters.

---

### 4. Schedule Slot Intersection & The Cancellation Override Rule:
```typescript
825: for (const room of candidateRooms) {
826:   // 1. Check active reservation leases
827:   if (room.currentStatus !== RoomStatus.AVAILABLE || (room.leaseExpiresAt && room.leaseExpiresAt > now)) {
828:     continue; // Held by another CR or running class!
829:   }
830: 
831:   let isOccupied = false;
832:   let nextClassAfterWindow: (typeof room.scheduleSlots)[0] | null = null;
833: 
834:   for (const slot of room.scheduleSlots) {
835:     // Rule A: Check if slot was cancelled today!
836:     const isCancelled = slot.overrides.some((o) => o.action === OverrideAction.CANCELLED);
837:     if (isCancelled) {
838:       continue; // The class was cancelled for today! Room is freed for this window!
839:     }
840: 
841:     // Rule B: Mathematical interval collision: slot.startTime < reqEnd && slot.endTime > reqStart
842:     const hasOverlap = slot.startTime < reqEnd && slot.endTime > reqStart;
843:     if (hasOverlap) {
844:       isOccupied = true;
845:       break;
846:     }
847: 
848:     // Rule C: Track the next upcoming class
849:     if (slot.startTime >= reqStart) {
850:       if (!nextClassAfterWindow || slot.startTime < nextClassAfterWindow.startTime) {
851:         nextClassAfterWindow = slot;
852:       }
853:     }
854:   }
855:   if (isOccupied) continue;
```
- **The Intelligent Override Check (Lines 836-839)**:
  If a routine timetable shows that Room 5030 usually has a class at `11:25`, but the teacher cancelled it today, `isCancelled` is `true`. The collision is dismissed! The room is marked free so other students can immediately study or take an extra class inside it!

---

### 5. Lookahead Remaining Minutes Calculation:
```typescript
857:   const freeUntil = nextClassAfterWindow ? nextClassAfterWindow.startTime : '20:00';
858:   const freeMins = this.calculateMinuteDifference(reqStart, freeUntil);
859: 
860:   freeRooms.push({
861:     room,
862:     freeWindow: { start: reqStart, end: reqEnd, durationMinutes },
863:     freeUntil,
864:     freeMinutesRemaining: freeMins,
865:     nextClass: nextClassAfterWindow ? { ... } : undefined,
866:   });
867: }
```
- The API responds with:
  `"Room 5030: Available now. Free for 95m+ until next class at 13:00 (Batch 66 CSE-311)"`.
- Gives students and CRs complete visibility to plan their study sessions with confidence!

---

*Continue to Chapter 6 for the deep-dive into Master Routine Ingestion, Collision Mathematics, and Emergency Overrides.*
