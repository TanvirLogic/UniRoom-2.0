# 🎓 UniRoom-Live 2.0 Backend Masterclass
## Chapter 2: PostgreSQL Relational Database & Prisma Schema Line-by-Line

The database is the heart and permanent memory of any backend application.
If the server crashes or restarts, all memory in RAM vanishes—but the database on disk preserves every user, classroom, schedule, and override.

In UniRoom-Live 2.0, we use **PostgreSQL 16** hosted on **Neon.tech Serverless PostgreSQL**, paired with **Prisma ORM**.

---

## 1. What is an ORM? (Object-Relational Mapping)

In traditional SQL, to find a user you would write:
```sql
SELECT id, full_name, role FROM users WHERE email = 'student@uttara.edu.bd';
```
While powerful, raw SQL strings don't give you compile-time type-safety or autocomplete in TypeScript. If you typo a column name (`full_nme`), you only find out when a user experiences a crash in production!

An **ORM (Object-Relational Mapper)** bridges the world of TypeScript objects and PostgreSQL tables:
```typescript
const user = await prisma.user.findUnique({
  where: { email: 'student@uttara.edu.bd' },
});
console.log(user.fullName); // Full autocomplete & type checked!
```
Prisma reads our `schema.prisma` file and automatically writes the exact, optimized SQL queries under the hood.

---

## 2. The Entity-Relationship Architecture (ERD Diagram)

Here is how all the tables in UniRoom-Live 2.0 connect together:

```
┌─────────────────────────┐
│       University        │
└────────────┬────────────┘
             │ 1:N
             ├─────────────────────────────────────────────────┐ 1:N
             ▼                                                 ▼
┌─────────────────────────┐       1:N       ┌─────────────────────────┐   ┌─────────────────────────┐
│       Department        ├────────────────►│      AcademicBatch      │   │  EmergencyAnnouncement  │
└────────────┬────────────┘                 └─────────────────────────┘   └─────────────────────────┘
             │ 1:N
             ├────────────────────────┐
             │ 1:N                    │ 1:N
             ▼                        ▼
┌─────────────────────────┐   ┌─────────────────────────┐
│        Building         │   │          User           │ (Student, CR, Faculty, Admin)
└────────────┬────────────┘   └───────┬────────┬────────┘
             │ 1:N                    │        │
             ▼                        │ 1:N    │ 1:N
┌─────────────────────────┐           ▼        ▼
│          Room           │◄──┤  ┌──────────┐  ┌──────────┐
└────────────┬────────────┘   │  │Classroom │  │Classroom │
             │ 1:N            │  │ Notice   │  │ Lecture  │
             ▼                │  └──────────┘  └──────────┘
┌─────────────────────────┐   │ (Logs, Overrides & Authors)
│      ScheduleSlot       │   │
└────────────┬────────────┘   │
             │ 1:N            ▼
             ▼          ┌─────────────────────────┐
     ┌──────────────────┤    ScheduleOverride     │
     │                  └─────────────────────────┘
```

---

## 3. `prisma/schema.prisma` Line by Line Breakdown

Let's read the schema from line 1 to 303.

### Section A: Generator & Datasource
```prisma
1: generator client {
2:   provider = "prisma-client-js"
3: }
4: 
5: datasource db {
6:   provider = "postgresql"
7:   url      = env("DATABASE_URL")
8: }
```
- **Line 1-3 (`generator client`)**: Tells Prisma to generate the TypeScript library (`@prisma/client`) so our NestJS services can import typed database methods.
- **Line 5-8 (`datasource db`)**: Specifies that our database engine is PostgreSQL and reads the connection string (`DATABASE_URL`) from our `.env` file.

---

### Section B: Enums (Restricted Word Sets)

An **Enum** restricts a database column to only allow specific predefined words, preventing typos or invalid states.

```prisma
enum Role {
  STUDENT
  CR
  FACULTY
  SUPER_ADMIN
}
```
- **`Role`**: Identifies who a user is.
  - `STUDENT`: Normal student who views today's timetable and free rooms.
  - `CR`: Class Representative authorized to cancel today's classes, reschedule times, free rooms, and take section attendance.
  - `FACULTY`: Teacher who conducts lectures and can shift class times.
  - `SUPER_ADMIN`: Institutional authority with global management permissions.

```prisma
enum RoomStatus {
  AVAILABLE
  RUNNING_CLASS
  RESERVED
  MAINTENANCE
}
```
- **`RoomStatus`**: The real-time physical state of a classroom.
  - `AVAILABLE`: Empty and ready for students or extra classes.
  - `RUNNING_CLASS`: An active routine class or lecture is happening right now.
  - `RESERVED`: Booked by a CR or faculty for an extra class or seminar.
  - `MAINTENANCE`: Room locked for cleaning, projector repairs, or exams.

```prisma
enum DayOfWeek {
  MON
  TUE
  WED
  THU
  FRI
  SAT
  SUN
}
```
- **`DayOfWeek`**: 3-letter standard representation of the routine days.

```prisma
enum OverrideAction {
  CANCELLED
  RESCHEDULED
  ROOM_SHIFTED
}
```
- **`OverrideAction`**: What kind of temporary change is happening to today's timetable without modifying the permanent master routine.

---

### Section C: Multi-Tenant Core Models

Multi-tenancy means multiple independent universities can share the same database while keeping their data completely separate and secure.

#### 1. Model: `University`
```prisma
model University {
  id            String      @id @default(uuid())
  name          String      // e.g. "Uttara University"
  code          String      @unique // e.g. "UU"
  domain        String?     // e.g. "uttara.edu.bd"
  logoUrl       String?
  operatingDays DayOfWeek[] @default([MON, TUE, WED, THU])
  isActive      Boolean     @default(true)
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt

  departments   Department[]
  rooms         Room[]
  users         User[]
  announcements EmergencyAnnouncement[]

  @@map("universities")
}
```
- **`id String @id @default(uuid())`**: A universally unique identifier (UUID) generated automatically (e.g. `c7a2b918-4e89-4d62-8172-ef19a86e7362`). Unlike integer IDs (`1, 2, 3`), UUIDs cannot be guessed by hackers.
- **`code String @unique`**: A short identifier like `"UU"`. `@unique` ensures no two universities can have the same code.
- **`operatingDays DayOfWeek[]`**: PostgreSQL array of days when the university conducts academic classes (e.g., Sunday-Thursday).
- **`createdAt`, `updatedAt`**: Automatically tracked audit timestamps.
- **`@@map("universities")`**: Tells PostgreSQL to name the actual SQL table `universities` (lowercase plural) while keeping the TypeScript model name `University`.

#### 2. Model: `Department`
```prisma
model Department {
  id           String      @id @default(uuid())
  universityId String
  name         String      // e.g. "Computer Science & Engineering"
  code         String      // e.g. "CSE"
  createdAt    DateTime    @default(now())
  updatedAt    DateTime    @updatedAt

  university   University  @relation(fields: [universityId], references: [id], onDelete: Cascade)
  buildings    Building[]
  rooms        Room[]
  users        User[]
  scheduleSlots ScheduleSlot[]
  academicBatches AcademicBatch[]

  @@unique([universityId, code])
  @@index([universityId])
  @@index([code])
  @@map("departments")
}
```
- **`universityId String`**: Foreign key linking this department to its parent University.
- **`@relation(fields: [universityId], references: [id], onDelete: Cascade)`**: If a university is deleted, all its departments are automatically deleted (`onDelete: Cascade`), avoiding orphan records.
- **`@@unique([universityId, code])`**: A **compound unique constraint**. Multiple universities can have a "CSE" department, but University "UU" can only have ONE department with code "CSE".
- **`@@index([code])`**: Creates a B-Tree index in PostgreSQL so searching for a department by code happens in $O(\log N)$ time instead of scanning millions of rows.

#### 3. Model: `AcademicBatch`
```prisma
model AcademicBatch {
  id           String      @id @default(uuid())
  departmentId String
  name         String      // e.g. "68"
  sections     String[]    // e.g. ["A", "B", "C"]
  isActive     Boolean     @default(true)
  createdAt    DateTime    @default(now())
  updatedAt    DateTime    @updatedAt

  department   Department  @relation(fields: [departmentId], references: [id], onDelete: Cascade)

  @@unique([departmentId, name])
  @@index([departmentId, isActive])
  @@map("academic_batches")
}
```
- Holds batch numbers (e.g., Batch 68) and an array of all active sections (`["A", "B", "C", "D"]`). This powers the dynamic dropdowns on registration and profile screens so users never have to guess valid sections.

---

### Section D: Physical Campus & Concurrency Control (OCC)

#### 4. Model: `Room`
```prisma
model Room {
  id             String      @id @default(uuid())
  universityId   String
  departmentId   String
  buildingId     String
  roomNumber     String      // e.g. "5030 (508)"
  floor          Int         @default(1)
  capacity       Int         @default(40)
  currentStatus  RoomStatus  @default(AVAILABLE)
  currentCourse  String?
  currentTeacher String?
  currentBatch   String?
  leaseExpiresAt DateTime?
  version        Int         @default(1) // Optimistic Concurrency Control (OCC)
  createdAt      DateTime    @default(now())
  updatedAt      DateTime    @updatedAt

  university     University  @relation(fields: [universityId], references: [id], onDelete: Cascade)
  department     Department  @relation(fields: [departmentId], references: [id], onDelete: Cascade)
  building       Building    @relation(fields: [buildingId], references: [id], onDelete: Cascade)
  scheduleSlots  ScheduleSlot[]
  overriddenSlots ScheduleOverride[] @relation("OverrideNewRoom")
  roomLogs       RoomLog[]

  @@unique([buildingId, roomNumber])
  @@index([universityId, departmentId, currentStatus])
  @@map("rooms")
}
```
- **`version Int @default(1)`**: **The Concurrency Armor**.
  Imagine two CRs tap "Book Room 5030" at the exact same millisecond. Without `version`, both might succeed (Double Booking!). With OCC, both send `version: 1`. The first request updates the room and increments `version` to 2. The second request arrives with `version: 1`, but the database now has `version: 2`. The server rejects the second request with `409 Conflict`!
- **`leaseExpiresAt`**: When a room is booked for an extra class (e.g. 90 minutes), this timestamp marks when the room will automatically revert to `AVAILABLE`.

#### 5. Model: `RoomLog`
```prisma
model RoomLog {
  id              String      @id @default(uuid())
  roomId          String
  changedByUserId String
  previousStatus  RoomStatus
  newStatus       RoomStatus
  note            String?
  createdAt       DateTime    @default(now())

  room            Room        @relation(fields: [roomId], references: [id], onDelete: Cascade)
  changedByUser   User        @relation(fields: [changedByUserId], references: [id], onDelete: Cascade)

  @@index([roomId, createdAt])
  @@map("room_logs")
}
```
- **Audit Trail**: Every time a room changes status (from `AVAILABLE` to `RESERVED` or `RUNNING_CLASS`), a permanent audit log entry is recorded with who changed it, why, previous status, and timestamp.

---

### Section E: User Identity & Verification

#### 6. Model: `User`
```prisma
model User {
  id            String      @id @default(uuid())
  universityId  String?
  departmentId  String?
  fullName      String
  email         String      @unique
  passwordHash  String
  role          Role        @default(STUDENT)
  studentId     String?     // e.g. "2241081422"
  facultyId     String?     // e.g. "DNS"
  batch         String?     // e.g. "68"
  section       String?     // e.g. "A"
  isApprovedCr  Boolean     @default(false)
  isEmailVerified Boolean   @default(false)
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt

  university    University? @relation(fields: [universityId], references: [id], onDelete: SetNull)
  department    Department? @relation(fields: [departmentId], references: [id], onDelete: SetNull)
  taughtSlots   ScheduleSlot[] @relation("FacultyClasses")
  roomLogs      RoomLog[]
  createdOverrides ScheduleOverride[] @relation("UserOverrides")

  @@unique([universityId, studentId])
  @@index([universityId, departmentId, role])
  @@index([universityId, departmentId, batch, section])
  @@map("users")
}
```
- **`passwordHash`**: We **NEVER** store plain-text passwords. We store a 60-character bcrypt hash (e.g. `$2b$10$wK4p...`). Even if a hacker dumps the database, they cannot read user passwords.
- **`@@unique([universityId, studentId])`**: Ensures that two students within the same university cannot register with the identical student roll number.
- **`isEmailVerified`**: Starts as `false`. A user cannot log in until they verify their email with a 6-digit cryptographic PIN.

#### 7. Models: `EmailVerificationPin` & `PasswordResetPin`
```prisma
model EmailVerificationPin {
  id        String   @id @default(uuid())
  email     String
  pinHash   String
  expiresAt DateTime
  attempts  Int      @default(0)
  createdAt DateTime @default(now())

  @@index([email])
  @@map("email_verification_pins")
}
```
- Stores temporary 6-digit PINs hashed with bcrypt.
- **`attempts Int @default(0)`**: Defends against brute-force attacks! If someone tries guessing the 6-digit PIN more than 5 times, the PIN is invalidated immediately.

---

### Section F: Master Timetable & Overrides

#### 8. Model: `ScheduleSlot` (The Master Timetable)
```prisma
model ScheduleSlot {
  id              String      @id @default(uuid())
  departmentId    String
  roomId          String
  facultyUserId   String?     // Linked when faculty signs up
  facultyInitials String      // e.g. "DNS", "AMU"
  batch           String      // e.g. "68"
  section         String      // e.g. "A"
  courseCode      String      // e.g. "CSE06131"
  courseName      String      // e.g. "Algorithms"
  dayOfWeek       DayOfWeek
  startTime       String      // e.g. "11:25"
  endTime         String      // e.g. "12:45"
  isActive        Boolean     @default(true)
  createdAt       DateTime    @default(now())
  updatedAt       DateTime    @updatedAt

  department      Department  @relation(fields: [departmentId], references: [id], onDelete: Cascade)
  room            Room        @relation(fields: [roomId], references: [id], onDelete: Cascade)
  facultyUser     User?       @relation("FacultyClasses", fields: [facultyUserId], references: [id], onDelete: SetNull)
  overrides       ScheduleOverride[]

  @@index([departmentId, batch, section, dayOfWeek])
  @@index([roomId, dayOfWeek])
  @@map("schedule_slots")
}
```
- Represents a recurring weekly class in the university routine.
- Every Monday from `11:25` to `12:45`, Batch 68 Section A has Algorithms with teacher "DNS" in Room 5030.

#### 9. Model: `ScheduleOverride` (Daily Exceptions)
```prisma
model ScheduleOverride {
  id              String         @id @default(uuid())
  scheduleSlotId  String
  overrideDate    DateTime       // Date on which the override applies
  action          OverrideAction // CANCELLED, RESCHEDULED, ROOM_SHIFTED
  newRoomId       String?
  newStartTime    String?
  newEndTime      String?
  reason          String?
  createdByUserId String
  createdAt       DateTime       @default(now())

  scheduleSlot    ScheduleSlot   @relation(fields: [scheduleSlotId], references: [id], onDelete: Cascade)
  newRoom         Room?          @relation("OverrideNewRoom", fields: [newRoomId], references: [id], onDelete: SetNull)
  createdByUser   User           @relation("UserOverrides", fields: [createdByUserId], references: [id], onDelete: Cascade)

  @@index([scheduleSlotId, overrideDate])
  @@map("schedule_overrides")
}
```
- **The Magic of UniRoom-Live**:
  What happens when a teacher gets sick or informs CR that class is cancelled today?
  We don't destroy the master routine! Instead, we record an **override** for today's date.
  The master schedule stays pure for next week, but for today, the app shows "CANCELLED" and the classroom is automatically marked `AVAILABLE` for other batches!

---

### Section G: Real-Time Academic Broadcasts & Virtual Classrooms

#### 10. Model: `EmergencyAnnouncement` (Campus-Wide Bulletins)
```prisma
model EmergencyAnnouncement {
  id           String      @id @default(uuid())
  universityId String
  title        String
  message      String
  isActive     Boolean     @default(true)
  expiresAt    DateTime?
  createdAt    DateTime    @default(now())

  university   University  @relation(fields: [universityId], references: [id], onDelete: Cascade)

  @@map("emergency_announcements")
}
```
- **Real-World Purpose**: When sudden campus closures, severe weather warnings, or semester break alerts occur, the administration publishes a top-level alert banner.
- **Relational Integrity**: Linked to `University` with `onDelete: Cascade`. If a university tenant is deactivated or deleted, all historical bulletins purge cleanly without orphan records.
- **`expiresAt`**: An optional timestamp allowing self-expiring emergency alerts that disappear from student dashboards automatically once the deadline passes.

#### 11. Model: `ClassroomNotice` (Course Notice Boards)
```prisma
model ClassroomNotice {
  id           String      @id @default(uuid())
  courseCode   String
  title        String
  content      String
  authorId     String
  authorName   String
  authorRole   String
  department   String
  batch        String?
  section      String?
  targetCohort String?
  createdAt    DateTime    @default(now())
  updatedAt    DateTime    @updatedAt

  author       User        @relation("UserClassroomNotices", fields: [authorId], references: [id], onDelete: Cascade)

  @@index([courseCode])
  @@index([department, batch, section])
  @@map("classroom_notices")
}
```
- **Real-World Purpose**: Digital replacement for scattered WhatsApp and Telegram group chats. Teachers and CRs post assignment deadlines, quiz dates, and room relocations directly into the course hub.
- **`targetCohort` & Flexible Scoping**:
  - If a faculty member wants to broadcast to **only Batch 61 Section D**, `batch: "61"`, `section: "D"`.
  - If they want to post a global exam notice for **all sections taking Algorithms**, `batch: null`, `section: null`, `targetCohort: "All Sections"`.
- **Relational Integrity**:
  `author User @relation(..., onDelete: Cascade)` ensures author accountability while maintaining database consistency.
- **Compound Query Indexes**:
  - `@@index([courseCode])`: Extremely fast lookup when students open a course room (e.g., `WHERE courseCode = 'CSE-412'`).
  - `@@index([department, batch, section])`: Instant cohort-specific filtering so students only see notices meant for their section.

#### 12. Model: `ClassroomLecture` (Course Archives & Resource Hub)
```prisma
model ClassroomLecture {
  id            String      @id @default(uuid())
  courseCode    String
  lectureNumber String
  title         String
  date          String?
  topics        String?
  link          String?
  authorId      String
  authorName    String
  authorRole    String
  department    String
  batch         String?
  section       String?
  targetCohort  String?
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt

  author        User        @relation("UserClassroomLectures", fields: [authorId], references: [id], onDelete: Cascade)

  @@index([courseCode])
  @@index([department, batch, section])
  @@map("classroom_lectures")
}
```
- **Real-World Purpose**: Tracks the pedagogical progress of the semester: Lecture 01, Lecture 02, Lecture 03...
- **`lectureNumber`**: Auto-incremented human-readable identifier (`Lecture 01`, `Lecture 02`, etc.) generated by the backend service if omitted.
- **`topics`**: Bullet-point summary of algorithms, formulas, or slides covered in that class.
- **`link`**: Direct Google Drive, OneDrive, or GitHub repository URL where presentation slides or code repositories are hosted.
- **`@@index([courseCode])` & `@@index([department, batch, section])`**: Optimizes concurrent queries when hundreds of students view course lecture archives before midterms.

---

*Continue to Chapter 3 for the deep-dive into Security, Guards, Roles, and Interceptors.*
