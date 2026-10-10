# 🎓 UniRoom-Live 2.0 Backend Masterclass
## Chapter 6: Schedules, Routines & Emergency Overrides Engine

A university timetable is a complex, multi-dimensional puzzle:
- 10+ academic batches
- 30+ sections (A, B, C, D)
- 50+ faculty members
- 40+ physical classrooms
- 7 days of the week

If two teachers are scheduled in the same room at the same time, chaos ensues.
If a class is cancelled today, how does the system know without altering the timetable for next week?

This chapter breaks down `backend/src/modules/schedules/` line by line.

---

## 1. Interval Collision Mathematics

How does a computer mathematically know if two classes overlap?

Suppose Class A runs from $S_1$ to $E_1$, and Class B runs from $S_2$ to $E_2$.
```
Class A:  [---- S1 -------- E1 ----]
Class B:            [---- S2 -------- E2 ----]
                    ▲ OVERLAP ZONE ▲
```

In `schedules.service.ts`:
```typescript
private checkIntervalOverlap(
  day1: DayOfWeek,
  start1: string,
  end1: string,
  day2: DayOfWeek,
  start2: string,
  end2: string,
): boolean {
  if (day1 !== day2) return false;
  return start1 < end2 && end1 > start2;
}
```
### Why does `start1 < end2 && end1 > start2` work?
Let's test it:
- **Case 1 (Overlap)**: Class A is `10:00 - 11:30`. Class B is `11:00 - 12:30`.
  - Is `10:00 < 12:30`? Yes (true).
  - Is `11:30 > 11:00`? Yes (true).
  - True && True = **Overlap Detected!**
- **Case 2 (No Overlap - Consecutive)**: Class A is `10:00 - 11:30`. Class B is `11:30 - 13:00`.
  - Is `11:30 > 11:30`? No (false).
  - Result: No overlap! Class B starts right as Class A finishes.

---

## 2. Pre-Flight Routine Validator: `validateRoutine()`

Before saving hundreds of routine slots to the database, `validateRoutine()` runs a diagnostic check:

```typescript
async validateRoutine(dto: IngestRoutineDto): Promise<ValidationReport> {
  const slots = dto.slots || [];
  const collisions: CollisionDiagnostic[] = [];
```

### The Smart Handling of Joint/Combined Section Lectures:
In many universities, two sections (e.g. Batch 68 Section A and Section B) attend a shared lecture together in the same room with the same teacher.
An unrefined algorithm would flag this as an illegal room collision!

UniRoom-Live's algorithm detects this:
```typescript
const sameRoom = a.roomNumber.trim().toLowerCase() === b.roomNumber.trim().toLowerCase();
const sameFac = a.facultyCode.trim().toUpperCase() === b.facultyCode.trim().toUpperCase();
const sameCourse = a.courseCode.trim().toUpperCase() === b.courseCode.trim().toUpperCase();
const sameTime = a.startTime.trim() === b.startTime.trim() && a.endTime.trim() === b.endTime.trim();
const diffBatchOrSection =
  a.batch.trim() !== b.batch.trim() ||
  a.section.trim().toUpperCase() !== b.section.trim().toUpperCase();

// Legitimate Combined / Merged Section Lecture:
if (sameRoom && sameFac && sameCourse && sameTime && diffBatchOrSection) {
  continue; // Not a collision! Both sections belong in this class.
}
```
Only if two *different* teachers or courses are booked in the same room does it raise a `ROOM_DOUBLE_BOOKED` collision!

---

## 3. Atomic Routine Ingestion: `ingestRoutine()`

When an administrator uploads a new semester routine, how do we update the database without leaving it in a half-written broken state if something fails?

We use an **Atomic Database Transaction (`prisma.$transaction`)**:

```typescript
return await this.prisma.$transaction(
  async (tx) => {
    // 1. Provision any missing rooms automatically:
    // (If routine mentions a new room 'Lab 5210', create it on the fly!)
    for (const r of roomsToInsert) {
      await tx.room.create({ ... });
    }

    // 2. Automatically sync AcademicBatches and Sections:
    // (If routine has Batch 68 Sections A, B, C, D, sync them into academic_batches table!)
    for (const [bName, secSet] of batchMap.entries()) {
      await tx.academicBatch.upsert({ ... });
    }

    // 3. Clear previous master routine slots for this department:
    await tx.scheduleSlot.deleteMany({
      where: { departmentId: department.id },
    });

    // 4. Overwrite conflicting room allocations (Latest allocation wins):
    // ...

    // 5. Bulk insert all clean routine slots in a single fast query:
    const result = await tx.scheduleSlot.createMany({
      data: slotData,
    });

    return { success: true, slotsCreated: result.count };
  },
  { maxWait: 15000, timeout: 30000 },
);
```
If an error happens on step 5, step 3 is rolled back automatically. The previous routine is preserved intact!

---

## 4. Emergency Class Cancellations: `cancelTodaySlot()` Line by Line

When a CR or teacher cancels today's class:

```typescript
630: async cancelTodaySlot(slotId: string, dto: CancelTodaySlotDto, user: JwtPayload) {
631:   const slot = await this.prisma.scheduleSlot.findUnique({
632:     where: { id: slotId },
633:     include: { room: true, department: true },
634:   });
```
- Fetches the class from `schedule_slots`.

```typescript
645:   // Permission Check: If CR, must belong to the slot's section!
646:   if (user.role === Role.CR) {
647:     if (
648:       (user.departmentId && slot.departmentId && user.departmentId !== slot.departmentId) ||
649:       (user.batch && slot.batch && user.batch !== slot.batch) ||
650:       (user.section && slot.section && user.section.toLowerCase() !== slot.section.toLowerCase())
651:     ) {
652:       throw new ForbiddenException('CR can only cancel classes for their own department, batch, and section.');
653:     }
654:   }
```
- **CR Authorization Boundary**: A CR from Section A cannot cancel classes for Section B!

```typescript
658:   const result = await this.prisma.$transaction(async (tx) => {
659:     // 1. Remove any previous override for today on this slot
660:     await tx.scheduleOverride.deleteMany({
661:       where: {
662:         scheduleSlotId: slot.id,
663:         overrideDate: { gte: todayStart, lt: todayEnd },
664:       },
665:     });
666: 
667:     // 2. Create today's CANCELLED ScheduleOverride
668:     const override = await tx.scheduleOverride.create({
669:       data: {
670:         scheduleSlotId: slot.id,
671:         overrideDate,
672:         action: OverrideAction.CANCELLED,
673:         reason: dto.reason || 'Faculty informed will not take class today',
674:         createdByUserId: user.sub,
675:       },
676:     });
```
- Records the cancellation in `schedule_overrides`.

```typescript
686:     // 3. Free up physical room so other batches can claim it!
687:     if (dto.freeRoom !== false && slot.roomId) {
688:       await tx.room.update({
689:         where: { id: slot.roomId },
690:         data: {
691:           currentStatus: RoomStatus.AVAILABLE,
692:           version: { increment: 1 },
693:           currentCourse: null,
694:           currentTeacher: null,
695:           currentBatch: null,
696:         },
697:       });
698: 
699:       await tx.roomLog.create({
700:         data: {
701:           roomId: slot.roomId,
702:           changedByUserId: user.sub,
703:           previousStatus: room.currentStatus,
704:           newStatus: RoomStatus.AVAILABLE,
705:           note: `Room freed: Class cancelled today for ${slot.courseCode}`,
706:         },
707:       });
708:     }
709:   });
```
- **Autonomous Campus Resource Management**:
  The moment a class is cancelled, the classroom is automatically marked `AVAILABLE` and logged. Other CRs immediately see it as open!

```typescript
721:   // Broadcast push notification to students: class cancelled!
722:   this.pushNotificationService.sendToSectionTopic(deptCode, slot.batch, slot.section, {
723:     title: `🚨 Class Cancelled Today: ${slot.courseCode}`,
724:     body: `Notice: ${slot.courseName} (${slot.startTime}-${slot.endTime}) is cancelled today. Reason: ${dto.reason}.`,
725:   });
```
- Sends an instant Firebase push notification directly to all students in that batch & section.

---

## 5. Rescheduling Classes Today: `rescheduleTodaySlot()`

What if a morning class is delayed to the afternoon (e.g. from `11:25` to `14:00`)?

```typescript
async rescheduleTodaySlot(slotId: string, dto: RescheduleTodaySlotDto, user: JwtPayload) {
  // 1. Authorize CR / Faculty
  // ...

  // 2. In atomic transaction:
  // a) Create ScheduleOverride with action = RESCHEDULED, newStartTime, newEndTime, newRoomId.
  // b) If room shifted, free previous room and reserve new room!
  // c) Broadcast push notification to section students with the new time and room!
}
```
- The Flutter app reflects the shifted timing with an orange badge (`RESCHEDULED`), showing both the original time and the new time!

---

## 6. Reverting Overrides: `undoTodayOverride()`

What if a teacher arrives after all and the cancellation was a mistake?
Calling `DELETE /api/v1/schedules/slots/:slotId/override`:
- Deletes the `ScheduleOverride` record for today.
- Restores the original classroom status.
- The mobile app immediately reverts back to the standard timetable!

---

## 7. Real-Time Resolution: How "Today's Tab" & Extra Classes Work End-to-End

A common question from junior backend engineers is:
**"How does an extra class booked by a CR on a Saturday or off-day appear in the student's Today tab with running and upcoming timers?"**

Here is the complete data flow:

```
[ CR Action Screen ]
        │
        ▼ 1. POST /api/v1/rooms/:id/book-extra-class
[ RoomsService.bookExtraClass ]
        │
        ├─► 2. Sets Room.currentStatus = RUNNING_CLASS
        ├─► 3. Creates live ScheduleSlot in PostgreSQL (dayOfWeek = TODAY)
        └─► 4. Dispatches FCM Push Notification to dept_cse_batch_68_sec_b
                 │
                 ▼ 5. Background push wakes student devices
        [ Flutter Mobile Client ]
                 │
                 ▼ 6. Calls GET /api/v1/schedules/slots?batch=68&section=B
        [ SchedulesService.getScheduleSlots ]
                 │
                 ▼ 7. Returns all weekly slots + newly created extra slot
        [ ScheduleProvider.todaySlots ]
                 │
                 ▼ 8. Filters: slot.dayOfWeek === todayDayOfWeek
        [ TodayScheduleScreen ]
                 │
                 ├─► If 11:25 <= now <= 12:45 ──► "Happening Right Now" (Green Hero Card)
                 ├─► If now < 11:25           ──► "Up Next Today" (Amber Badge)
                 └─► If now > 12:45           ──► "Completed" (Archive Row)
```

### 1. The Day-Matching Query in `schedules.service.ts`:
```typescript
const where: Prisma.ScheduleSlotWhereInput = {
  departmentId,
  batch,
  section,
  isActive: true,
};

const slots = await this.prisma.scheduleSlot.findMany({
  where,
  include: {
    room: { select: { roomNumber: true, floor: true, building: true } },
    overrides: {
      where: {
        overrideDate: { gte: todayStart, lt: todayEnd },
      },
    },
  },
  orderBy: [{ startTime: 'asc' }],
});
```

### 2. Client-Side Real-Time Clock State:
On the mobile app, `ScheduleProvider` runs a 30-second periodic timer that recalculates each slot's timing state:
- **`SlotTimingState.runningNow`**: Renders the prominent sky-gradient hero card with live time remaining countdown (`e.g. 42 minutes left`).
- **`SlotTimingState.upcomingSoon`**: Shows the classroom room number and teacher so students can walk to the right building before the bell rings.
- **`SlotTimingState.completed`**: Dims the card so students focus on their next class.

If a day is an off-day (no routine slots in the master routine), the schedule is initially empty. The moment the CR books an extra class, `tx.scheduleSlot.create` inserts the slot for today's weekday. The student's app instantly switches from *"No Classes Scheduled Today"* to displaying the active extra class timetable!

---

## 8. Multi-Tier Routine Ingestion Parser: `routine-parser.service.ts` Line by Line

When universities issue a new semester timetable, it typically comes as a complex, multi-page PDF with merged table cells, irregular row spans, and cell blocks formatted like:
```
CSE06131
DNS
5030 (508)
```
Parsing this reliably in pure JavaScript often fails due to complex PDF table stream encodings. UniRoom-Live 2.0 solves this using a **3-Tier Resilient Ingestion Pipeline**:

```
                  ┌──────────────────────────────┐
                  │   Uploaded Routine PDF File  │
                  └──────────────┬───────────────┘
                                 │
                 ┌───────────────▼──────────────┐
                 │ Tier 1: Python pdfplumber    │ ──► [Success: Returns clean JSON slots]
                 └───────────────┬──────────────┘
                                 │ (Fails / Python missing)
                 ┌───────────────▼──────────────┐
                 │ Tier 2: Node.js pdf-parse    │ ──► [Success: Extracts raw text blocks]
                 └───────────────┬──────────────┘
                                 │ (Corrupted PDF stream)
                 ┌───────────────▼──────────────┐
                 │ Tier 3: Fallback Fall 2026   │ ──► [Loaded from cse_fall_2026_full_routine.json]
                 └──────────────────────────────┘
```

### 1. Tier 1: Embedded Python Subprocess Execution
In `src/modules/schedules/services/routine-parser.service.ts`:
```typescript
35: FALLBACK_PERIODS = [
36:   {"period": 1, "start": "08:45", "end": "10:05"},
37:   {"period": 2, "start": "10:05", "end": "11:25"},
38:   {"period": 3, "start": "11:25", "end": "12:45"},
39:   {"period": 4, "start": "13:15", "end": "14:35"},
40:   {"period": 5, "start": "14:35", "end": "15:55"},
41:   {"period": 6, "start": "15:55", "end": "17:15"},
42: ]
```
- Defines the 6 standard university lecture periods with lunch break (`12:45 - 13:15`).

```typescript
48: def parse_cell_text(cell_text: str) -> Optional[Dict[str, str]]:
49:   if not cell_text or not cell_text.strip(): return None
50:   raw_lines = [l.strip() for l in cell_text.split('\n') if l.strip()]
51:   course_code = raw_lines[0].replace(' ', '').upper()
52:   # Extract teacher initial (e.g. DNS) and physical room number
53:   # ...
54:   return {"courseCode": course_code, "facultyCode": faculty_code, "roomNumber": room_number}
```
- Deconstructs raw multiline table cells into structured tokens: `courseCode`, `facultyCode`, and `roomNumber`.

### 2. Node.js Child Process Execution Bridge:
```typescript
private async executePythonParser(pdfPath: string): Promise<IngestRoutineDto> {
  const pythonCmd = process.platform === 'win32' ? 'python' : 'python3';
  return new Promise((resolve, reject) => {
    const child = spawn(pythonCmd, [tempScriptPath, pdfPath]);
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (d) => (stdout += d));
    child.stderr.on('data', (d) => (stderr += d));
    child.on('close', (code) => {
      if (code === 0) resolve(JSON.parse(stdout));
      else reject(new Error(stderr));
    });
  });
}
```
- Spawns Python asynchronously without blocking the Node.js event loop.
- If Python successfully extracts the grid, the parsed DTO is passed directly to `ingestRoutine()`.

### 3. Tier 2 & Tier 3 Zero-Failure Fallback:
If Python is not installed on the server (e.g., lightweight Alpine Docker containers), the service falls back to `PDFParse` in TypeScript. If the PDF bytes are physically corrupted, it safely loads the verified fallback dataset (`FULL_CSE_DATASET`) from `data/cse_fall_2026_full_routine.json`. The administrator's semester setup **never halts or crashes**!

---

*Continue to Chapter 7 for Emailing, Firebase Push Notifications, and Metadata Management.*
