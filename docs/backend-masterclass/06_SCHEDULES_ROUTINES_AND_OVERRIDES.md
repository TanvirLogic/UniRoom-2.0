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

*Continue to Chapter 7 for Emailing, Firebase Push Notifications, and Metadata Management.*
