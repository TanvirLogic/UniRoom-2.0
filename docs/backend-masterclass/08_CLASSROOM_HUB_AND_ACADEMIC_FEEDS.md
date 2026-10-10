# 🎓 UniRoom-Live 2.0 Backend Masterclass
## Chapter 8: Virtual Classroom Hub, Dynamic Cross-Cohort Fan-Out & Course Archives

In a university setting, academic communication between teachers and students is notoriously fragmented:
- Faculty post homework in random WhatsApp groups that students mute.
- Presentation slide links get lost in endless chat histories.
- Multiple sections taking the same course with the same professor have no shared, synchronized notice board.

UniRoom-Live 2.0 solves this with the **Virtual Classroom Hub** (`src/modules/classrooms/`).
This chapter breaks down `classrooms.controller.ts`, `classrooms.service.ts`, DTOs, and the **Dynamic Cross-Cohort Fan-Out Algorithm** line by line.

---

## 1. REST API Contract: `src/modules/classrooms/classrooms.controller.ts`

Let's inspect how the controller exposes endpoints and secures them with Swagger documentation and JWT authorization:

```typescript
1: import { Controller, Post, Get, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
2: import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
3: import { ClassroomsService } from './classrooms.service';
4: import { CreateNoticeDto } from './dto/create-notice.dto';
5: import { CreateLectureDto } from './dto/create-lecture.dto';
6: import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
7: import { CurrentUser } from '../../common/decorators/current-user.decorator';
8: 
9: @ApiTags('Classrooms')
10: @Controller('classrooms')
11: @UseGuards(JwtAuthGuard)
12: @ApiBearerAuth('JWT-auth')
13: export class ClassroomsController {
14:   constructor(private readonly classroomsService: ClassroomsService) {}
```
- **Line 9 (`@ApiTags('Classrooms')`)**: Groups these endpoints under a dedicated "Classrooms" section in the interactive Swagger UI (`/api/docs`).
- **Line 10 (`@Controller('classrooms')`)**: Base URL prefix. When mounted under `/api/v1`, full URLs become `/api/v1/classrooms/...`.
- **Line 11 (`@UseGuards(JwtAuthGuard)`)**: **Zero-Trust Security**. Every single route in this controller requires a valid, unexpired Bearer JWT token in the `Authorization` header.
- **Line 14**: Injects `ClassroomsService` via NestJS Dependency Injection.

---

### Route 1: Post Notice (`POST /api/v1/classrooms/notices`)
```typescript
31: @Post('notices')
32: @ApiOperation({ summary: 'Publish a new classroom notice and trigger FCM push notifications to students' })
33: @ApiResponse({ status: 201, description: 'Notice published and push notifications dispatched' })
34: async createNotice(
35:   @CurrentUser('sub') userId: string,
36:   @Body() dto: CreateNoticeDto,
37: ) {
38:   return this.classroomsService.createNotice(userId, dto);
39: }
```
- **`@CurrentUser('sub') userId: string`**: Uses our custom parameter decorator to extract the authenticated user's database ID directly from the decrypted JWT payload, preventing client-side spoofing.
- **`@Body() dto: CreateNoticeDto`**: Automatically validates the JSON request body against class-validator rules before the method runs.

---

### Route 2: Query Notices (`GET /api/v1/classrooms/notices`)
```typescript
43: @Get('notices')
44: @ApiOperation({ summary: 'Get all published notices for a course classroom' })
45: @ApiQuery({ name: 'courseCode', required: true, example: 'CSE-412' })
46: @ApiQuery({ name: 'department', required: false, example: 'CSE' })
47: @ApiQuery({ name: 'batch', required: false, example: '61' })
48: @ApiQuery({ name: 'section', required: false, example: 'D' })
49: async getNotices(
50:   @Query('courseCode') courseCode: string,
51:   @Query('department') department?: string,
52:   @Query('batch') batch?: string,
53:   @Query('section') section?: string,
54: ) {
55:   return this.classroomsService.getNotices({
56:     courseCode: courseCode || '',
57:     department,
58:     batch,
59:     section,
60:   });
61: }
```
- Retrieves published notices filtered by course code. If a student is in Batch 61 Section D, passing `batch` and `section` returns notices specifically for their section *plus* global notices addressed to all cohorts!

---

### Route 3: Delete Notice (`DELETE /api/v1/classrooms/notices/:id`)
```typescript
64: @Delete('notices/:id')
65: @ApiOperation({ summary: 'Delete a classroom notice' })
66: async deleteNotice(
67:   @CurrentUser('sub') userId: string,
68:   @Param('id') id: string,
69: ) {
70:   return this.classroomsService.deleteNotice(userId, id);
71: }
```
- Deletes a notice by ID. Enforces strict role and ownership checks in the service layer.

---

### Route 4 & 5: Post & Query Lectures (`POST & GET /api/v1/classrooms/lectures`)
```typescript
74: @Post('lectures')
75: @ApiOperation({ summary: 'Publish a new classroom lecture material and trigger FCM push notifications' })
76: async createLecture(
77:   @CurrentUser('sub') userId: string,
78:   @Body() dto: CreateLectureDto,
79: ) {
80:   return this.classroomsService.createLecture(userId, dto);
81: }
82: 
83: @Get('lectures')
84: @ApiOperation({ summary: 'Get all published lecture materials for a course classroom' })
85: async getLectures(
86:   @Query('courseCode') courseCode: string,
87:   @Query('department') department?: string,
88:   @Query('batch') batch?: string,
89:   @Query('section') section?: string,
90: ) {
91:   return this.classroomsService.getLectures({ courseCode, department, batch, section });
92: }
```
- Allows teachers to catalog sequential class notes (`Lecture 01`, `Lecture 02`), outline topic bullets, and provide presentation slide links.

---

## 2. Data Validation DTOs: `CreateNoticeDto` & `CreateLectureDto`

Before data reaches the database, DTOs enforce strict formatting:

### `CreateNoticeDto`:
```typescript
export class CreateNoticeDto {
  @IsNotEmpty()
  @IsString()
  courseCode: string; // e.g. "CSE-412"

  @IsNotEmpty()
  @IsString()
  title: string; // e.g. "Quiz 2 on Dijkstra & Bellman-Ford"

  @IsNotEmpty()
  @IsString()
  content: string; // Detailed instructions or syllabus

  @IsOptional()
  @IsString()
  department?: string; // e.g. "CSE"

  @IsOptional()
  @IsString()
  batch?: string; // e.g. "61"

  @IsOptional()
  @IsString()
  section?: string; // e.g. "D"

  @IsOptional()
  @IsString()
  targetCohort?: string; // e.g. "Batch 61 (D)" or "All Sections"
}
```

### `CreateLectureDto`:
```typescript
export class CreateLectureDto {
  @IsNotEmpty()
  @IsString()
  courseCode: string;

  @IsOptional()
  @IsString()
  lectureNumber?: string; // e.g. "Lecture 04" (Auto-generated if blank)

  @IsNotEmpty()
  @IsString()
  title: string; // e.g. "Dynamic Programming: 0/1 Knapsack"

  @IsOptional()
  @IsString()
  date?: string; // e.g. "2026-10-10"

  @IsOptional()
  @IsString()
  topics?: string; // Bullet summary of discussed topics

  @IsOptional()
  @IsString()
  link?: string; // Google Drive / GitHub repository link
}
```

---

## 3. The Notice Engine & Fan-Out Algorithm: `classrooms.service.ts`

Now let's examine the heart of `classrooms.service.ts`:

### 1. Role-Based Publishing Guard
```typescript
25: async createNotice(userId: string, dto: CreateNoticeDto) {
26:   const user = await this.prisma.user.findUnique({
27:     where: { id: userId },
28:     include: { department: true },
29:   });
30:   if (!user) throw new NotFoundException('User profile not found');
31: 
32:   // Notice publishing permission: Faculty, CR, or Super Admin
33:   const allowedRoles: Role[] = [Role.FACULTY, Role.CR, Role.SUPER_ADMIN];
34:   if (!allowedRoles.includes(user.role)) {
35:     throw new ForbiddenException('Only faculty members and CRs can post classroom notices');
36:   }
```
- Regular students cannot spam the course bulletin. Only authenticated teachers (`FACULTY`), section representatives (`CR`), or administrators (`SUPER_ADMIN`) are authorized to publish.

---

### 2. Regular Expression Cohort Parsing
```typescript
41:   const department = dto.department || user.department?.code || 'CSE';
42:   let targetBatch = dto.batch?.trim() || null;
43:   let targetSection = dto.section?.trim() || null;
44: 
45:   // Parse target cohort string if batch/section were not explicitly passed (e.g. "Batch 61 (D)")
46:   if ((!targetBatch || !targetSection) && dto.targetCohort) {
47:     const match = dto.targetCohort.match(/Batch\s*(\w+)\s*\(([A-Za-z0-9]+)\)/i);
48:     if (match) {
49:       targetBatch = match[1];
50:       targetSection = match[2];
51:     }
52:   }
```
- In mobile UI dropdowns, users often pick labels like `"Batch 68 (B)"`.
- The regex `/Batch\s*(\w+)\s*\(([A-Za-z0-9]+)\)/i` extracts:
  - `match[1]` ──► `"68"` (Batch)
  - `match[2]` ──► `"B"` (Section)
  Clean, resilient, and immune to whitespace variations.

---

### 3. PostgreSQL Database Persistence
```typescript
54:   const notice = await this.prisma.classroomNotice.create({
55:     data: {
56:       courseCode: dto.courseCode.trim().toUpperCase(),
57:       title: dto.title.trim(),
58:       content: dto.content.trim(),
59:       authorId: user.id,
60:       authorName: user.fullName,
61:       authorRole: user.role,
62:       department: department.trim().toUpperCase(),
63:       batch: targetBatch,
64:       section: targetSection,
65:       targetCohort: dto.targetCohort?.trim() || 'All Sections',
66:     },
67:   });
```
- Writes the notice into `classroom_notices`.
- Preserves author attribution (`authorName`, `authorRole`) so students know immediately whether a notice was issued by their teacher or their CR.

---

### 4. The Dynamic Cross-Cohort Fan-Out Algorithm

Here is one of the most elegant architectural patterns in UniRoom-Live 2.0:
**How do you broadcast a push notification to every student taking a course when multiple different batches and sections are enrolled?**

```typescript
96:   const targetTopics: Array<{ dept: string; batch: string; section: string }> = [];
97: 
98:   if (targetBatch && targetSection) {
99:     // Case 1: Specific section target
100:    targetTopics.push({
101:      dept: department,
102:      batch: targetBatch,
103:      section: targetSection,
104:    });
105:  } else {
106:    // Case 2: General Course Notice -> Auto-discover all enrolled cohorts!
107:    const slots = await this.prisma.scheduleSlot.findMany({
108:      where: {
109:        courseCode: { equals: notice.courseCode, mode: 'insensitive' },
110:      },
111:      select: {
112:        batch: true,
113:        section: true,
114:        department: { select: { code: true } },
115:      },
116:    });
117: 
118:    const seen = new Set<string>();
119:    for (const slot of slots) {
120:      const d = slot.department?.code || department;
121:      const key = `${d}_${slot.batch}_${slot.section}`;
122:      if (!seen.has(key)) {
123:        seen.add(key);
124:        targetTopics.push({
125:          dept: d,
126:          batch: slot.batch,
127:          section: slot.section,
128:        });
129:      }
130:    }
131: 
132:    // Fallback: If no routine slots found, fallback to author's cohort
133:    if (targetTopics.length === 0 && user.batch && user.section) {
134:      targetTopics.push({
135:        dept: department,
136:        batch: user.batch,
137:        section: user.section,
138:      });
139:    }
140:  }
```

#### Why this is brilliant:
1. When a professor posts: `"Midterm Exam will cover chapters 1 to 5"`, they don't have to manually select 4 different sections one by one.
2. The backend scans `schedule_slots` where `courseCode = 'CSE-412'`.
3. It finds:
   - Batch 61 Section A
   - Batch 61 Section B
   - Batch 62 Section C
4. It deduplicates with a `Set<string>`.
5. It then loops over all discovered cohorts and fires FCM topic broadcasts in parallel!

```typescript
143:   for (const t of targetTopics) {
144:     try {
145:       await this.pushNotificationService.sendToSectionTopic(
146:         t.dept,
147:         t.batch,
148:         t.section,
149:         payload,
150:       );
151:       this.logger.log(`FCM Notice broadcast sent to topic dept_${t.dept}_batch_${t.batch}_sec_${t.section}`);
152:     } catch (err: any) {
153:       this.logger.warn(`Failed to send FCM notice to ${t.dept}-${t.batch}-${t.section}: ${err.message}`);
154:     }
155:   }
```
Every single student across all enrolled sections receives the notification on their phone in under a second!

---

### 5. Smart Notice Querying: `getNotices()`
```typescript
167: async getNotices(params: { courseCode: string; department?: string; batch?: string; section?: string }) {
168:   const cleanCourse = params.courseCode.trim().toUpperCase();
169:   const whereClause: any = { courseCode: cleanCourse };
170: 
171:   // If specific cohort requested, return cohort notices OR global notices!
172:   if (params.batch && params.section) {
173:     whereClause.OR = [
174:       {
175:         batch: { equals: params.batch.trim(), mode: 'insensitive' },
176:         section: { equals: params.section.trim(), mode: 'insensitive' },
177:       },
178:       { batch: null },
179:       { targetCohort: { equals: 'All Cohorts', mode: 'insensitive' } },
180:       { targetCohort: { equals: 'All Sections', mode: 'insensitive' } },
181:     ];
182:   }
183: 
184:   return this.prisma.classroomNotice.findMany({
185:     where: whereClause,
186:     orderBy: { createdAt: 'desc' },
187:     include: {
188:       author: { select: { id: true, fullName: true, role: true, facultyId: true, studentId: true } },
189:     },
190:   });
191: }
```
- **The Logical `OR` Clause**:
  A student in Section D sees:
  1. Notices specifically tagged for Section D.
  2. Notices tagged for "All Sections".
  3. Notices with `batch = null` (general announcements).
  They will **never** see private notices posted exclusively for Section A or Section B!

---

### 6. Delete Authorization: `deleteNotice()`
```typescript
232:   const canDelete =
233:     notice.authorId === user.id ||
234:     user.role === Role.SUPER_ADMIN ||
235:     user.role === Role.FACULTY;
236: 
237:   if (!canDelete) {
238:     throw new ForbiddenException('You do not have permission to delete this notice');
239:   }
```
- **Permission Hierarchy**:
  - The original author can delete their own notice.
  - Faculty can delete any notice (e.g. if a CR posted incorrect quiz timing).
  - Super Admins can moderate all content.
  - Regular students or other CRs are rejected with `403 Forbidden`.

---

## 4. The Lecture Engine: `createLecture()` & Auto-Numbering

When a teacher uploads lecture materials, `createLecture()` automatically tracks lecture counts:

```typescript
281:   // Auto-generate lecture number if not supplied by user
282:   let lectureNum = dto.lectureNumber?.trim();
283:   if (!lectureNum) {
284:     const existingCount = await this.prisma.classroomLecture.count({
285:       where: { courseCode: { equals: dto.courseCode.trim(), mode: 'insensitive' } },
286:     });
287:     lectureNum = `Lecture ${existingCount + 1 < 10 ? '0' : ''}${existingCount + 1}`;
288:   }
```
- If the teacher types nothing in the "Lecture #" field, the backend queries `classroomLecture.count(...)`.
- If 3 lectures already exist for this course, it formats `Lecture 04`.
- Zero manual numbering mistakes!

### Structured Push Payload for Lectures:
```typescript
const payload = {
  title: `📚 [${lecture.courseCode}] ${lecture.lectureNumber}: ${lecture.title}`,
  body: lecture.topics ? lecture.topics : `New lecture material published by ${lecture.authorName}.`,
  data: {
    type: 'classroom_lecture',
    courseCode: lecture.courseCode,
    lectureId: lecture.id,
    lectureNumber: lecture.lectureNumber,
    title: lecture.title,
    topics: lecture.topics || '',
    link: lecture.link || '',
    authorName: lecture.authorName,
    createdAt: lecture.createdAt.toISOString(),
  },
};
```
- When students tap the push notification banner on Android or iOS, the mobile app reads `data.type = 'classroom_lecture'` and deep-links directly to the lecture details modal, where tapping the link opens the presentation slides in Chrome!

---

## 5. Summary: The Complete Backend Architecture Checklist

You have now mastered all **8 core pillars** of the UniRoom-Live 2.0 backend:

1. **Chapter 1: Architecture & Bootstrap** (`main.ts`, `app.module.ts`, `prisma.service.ts`)
2. **Chapter 2: Relational Database Schema** (PostgreSQL 16, Neon.tech, Prisma ORM, 12 Relational Models)
3. **Chapter 3: Security & Interceptors** (Bcrypt, JWT Strategies, RBAC `@Roles()`, Tenant Isolation, Transform Interceptors)
4. **Chapter 4: Authentication Engine** (Dual Token Issuing, Refresh Token Rotation, Cryptographic CSPRNG PINs)
5. **Chapter 5: Physical Rooms & OCC** (Double-Booking Race Conditions, Version Check OCC, Atomic Transactions, Extra Class Generation)
6. **Chapter 6: Timetable & Overrides Engine** (Collision Mathematics, Routine Parser, Daily Overrides, Today's Routine Resolution)
7. **Chapter 7: Email, FCM & Metadata Feeds** (SMTPS TLS Delivery, Firebase Cloud Messaging Topics, Cascading Dropdowns)
8. **Chapter 8: Classroom Hub Engine** (Course Notices, Sequential Lectures, Cross-Cohort Fan-Out Broadcasting)

### 💡 Golden Rules for Junior Backend Engineers:
- **Never trust client input**: Always validate with DTOs and `class-validator`.
- **Never use raw row locks when OCC is sufficient**: Use integer `version` columns to prevent double-booking without blocking other queries.
- **Always isolate third-party I/O**: Use `.catch(...)` on push notifications and email deliveries so network drops never roll back successful database transactions.
- **Never hardcode tenant IDs**: Derive departments, batches, and roles directly from the validated JWT token.
- **Always design atomic transactions**: If updating two related tables (e.g. `Room` and `ScheduleSlot`), bundle them inside `prisma.$transaction(...)`.

You are now equipped with the complete theoretical and practical knowledge to build, maintain, and scale enterprise backend systems!
