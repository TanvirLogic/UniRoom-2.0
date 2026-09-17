# 📘 Milestone 1: Engineering Architecture & Code Deep-Dive Guide (English)
> **UniRoom-Live 2.0 — Milestone 1 Comprehensive Technical Learning Guide**  
> *Target Audience: Tanvir (Full-Stack SWE Mastery)*  
> *Language: English*  
> *Location: `project explanation/milestone_one_learning_english.md`*

---

## 📑 Table of Contents
1. [Milestone 1 Objective & Architectural Overview](#1-milestone-1-objective--architectural-overview)
2. [Task 1.1: Backend Project Setup & Monorepo Tooling](#2-task-11-backend-project-setup--monorepo-tooling)
   - [package.json Dependencies Explained](#packagejson-dependencies-explained)
   - [tsconfig.json: Enterprise TypeScript Strictness](#tsconfigjson-enterprise-typescript-strictness)
   - [nest-cli.json](#nest-clijson)
3. [Task 1.2: Multi-Tenant Database Architecture (`schema.prisma`)](#3-task-12-multi-tenant-database-architecture-schemaprisma)
   - [What is Multi-Tenancy and Why Do We Need It?](#what-is-multi-tenancy-and-why-do-we-need-it)
   - [Line-by-Line Breakdown of the 8 Database Models](#line-by-line-breakdown-of-the-8-database-models)
   - [Database Indexes: Why B-Tree Composite Indexes Matter](#database-indexes-why-b-tree-composite-indexes-matter)
   - [Optimistic Concurrency Control (OCC)](#optimistic-concurrency-control-occ)
4. [Task 1.3: Cloud Database Setup (Neon Serverless PostgreSQL)](#4-task-13-cloud-database-setup-neon-serverless-postgresql)
   - [Understanding the Connection String & Pooling](#understanding-the-connection-string--pooling)
5. [Task 1.4: Database Migrations & Seeding Deep-Dive](#5-task-14-database-migrations--seeding-deep-dive)
   - [What Happens During `prisma migrate dev`?](#what-happens-during-prisma-migrate-dev)
   - [Deep-Dive: `prisma/seed.ts` Line-by-Line](#deep-dive-prismaseedts-line-by-line)
6. [Task 1.5: Core NestJS Infrastructure (`src/` folder)](#6-task-15-core-nestjs-infrastructure-src-folder)
   - [Prisma Database Service & Global Module](#prisma-database-service--global-module)
   - [Global HTTP Exception Filter](#global-http-exception-filter)
   - [Global Transform Interceptor (Response Envelope)](#global-transform-interceptor-response-envelope)
   - [Application Bootstrap & Pipeline (`main.ts`)](#application-bootstrap--pipeline-maints)
   - [Health & Diagnostics Controller](#health--diagnostics-controller)
7. [Milestone 1 Interview & Thesis Defense Q&A](#7-milestone-1-interview--thesis-defense-qa)

---

# 1. Milestone 1 Objective & Architectural Overview

### The Goal of Milestone 1
The objective of Milestone 1 is to construct a **bulletproof backend foundation**. Before writing any business logic (like user logins or room bookings), an enterprise software engineer establishes:
1. **A strictly-typed TypeScript backend runtime** (NestJS).
2. **A scalable, relational multi-tenant database schema** (PostgreSQL via Prisma ORM).
3. **Automated migrations and realistic seed data** (Uttara University routines).
4. **Global architectural safety nets** (Strict DTO validation, uniform error handling, and response envelopes).
5. **Interactive API documentation** (Swagger OpenAPI).

```
┌────────────────────────────────────────────────────────────────────────┐
│                        MILESTONE 1 ARCHITECTURE                        │
├───────────────────────────────┬────────────────────────────────────────┤
│           INCOMING            │ HTTP Requests from Client              │
│               │               │ (Flutter Mobile / Web)                 │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │  CORS & Prefix    │     │ Global prefix: /api/v1                 │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │  ValidationPipe   │     │ Strips unwanted fields, types input    │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │ HealthController  │     │ Runs live SELECT 1 ping on database    │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │   PrismaService   │     │ Handles connect/disconnect lifecycle   │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │ Neon PostgreSQL   │     │ 8 Multi-Tenant Tables on AWS Cloud     │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │TransformIntercept.│     │ Wraps output: { success: true, ... }   │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │AllExceptionsFilter│     │ Catches crashes: { success: false, ...}│
│     └───────────────────┘     │                                        │
└───────────────────────────────┴────────────────────────────────────────┘
```

---

# 2. Task 1.1: Backend Project Setup & Monorepo Tooling

### `package.json` Dependencies Explained
In `backend/package.json`, every single package was chosen with deliberate architectural intent:

| Package | Purpose in UniRoom-Live | Architectural Role |
| :--- | :--- | :--- |
| `@nestjs/core` & `@nestjs/common` | The core NestJS framework engine. | Provides controllers, services, modules, dependency injection, and decorators (`@Injectable()`, `@Get()`). |
| `@nestjs/config` | Configuration service. | Loads environment variables from `.env` securely throughout the app. |
| `@prisma/client` | Query builder engine. | Auto-generated, 100% type-safe database query builder. |
| `class-validator` & `class-transformer` | Input sanitization & validation. | Validates incoming JSON payloads using decorators (e.g. `@IsEmail()`, `@MinLength(6)`). |
| `rxjs` | Reactive programming library. | Reactive Extensions library used by NestJS interceptors to transform asynchronous response streams. |
| `@nestjs/swagger` & `swagger-ui-express` | Documentation engine. | Automatically generates visual OpenAPI documentation at `/api/docs`. |

---

### `tsconfig.json`: Enterprise TypeScript Strictness
File: [`backend/tsconfig.json`](file:///e:/Varsity%20Project/UniRoom-Live/backend/tsconfig.json)

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "ES2021",
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "strictBindCallApply": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

#### Why These Flags Are Critical:
1. **`emitDecoratorMetadata: true` & `experimentalDecorators: true`**:
   * NestJS relies heavily on decorators (like `@Injectable()`, `@Controller()`, `@Body()`).
   * When TypeScript compiles to JavaScript, decorators normally lose their type information. This flag tells TypeScript to save metadata so NestJS's Dependency Injection container knows what service to inject into what controller!
2. **`strictNullChecks: true`**:
   * Prevents the infamous *"Cannot read properties of undefined"* crash. If a room can be `null`, TypeScript forces you to handle the `if (!room)` case before accessing `room.roomNumber`.
3. **`noImplicitAny: true`**:
   * Disallows un-typed variables. Every parameter must have an explicit type (e.g. `roomId: string`). This prevents hidden runtime bugs.

---

# 3. Task 1.2: Multi-Tenant Database Architecture (`schema.prisma`)
File: [`backend/prisma/schema.prisma`](file:///e:/Varsity%20Project/UniRoom-Live/backend/prisma/schema.prisma)

### What is Multi-Tenancy and Why Do We Need It?
* **Single-Tenant:** You build an app hard-coded for Uttara University. If Dhaka University wants it, you must launch a whole new server and a whole new database. Maintenance becomes a nightmare.
* **Multi-Tenant (Our Architecture):** One single application and database serves **multiple universities**.
  * **Tenant Boundary:** The `University` table is the root tenant.
  * **Data Isolation:** Every department, room, user, and schedule slot stores a `universityId`.
  * When a CR from Uttara University logs in, every SQL query is automatically scoped with `WHERE universityId = '...'`. They can **never** see or modify data from another university.

---

### Line-by-Line Breakdown of the 8 Database Models

#### 1. `University` (Root Tenant)
```prisma
model University {
  id            String      @id @default(uuid())
  name          String      // e.g. "Uttara University"
  code          String      @unique // e.g. "UU"
  domain        String?     // e.g. "uttara.edu.bd"
  operatingDays DayOfWeek[] @default([MON, TUE, WED, THU])
  isActive      Boolean     @default(true)
  ...
}
```
* **`id @default(uuid())`**: We use UUIDs (Universally Unique Identifiers like `e13f9b15-d393-...`) instead of auto-incrementing integers (`1, 2, 3`). Integers allow attackers to guess URLs (e.g., `/api/v1/users/2`). UUIDs are cryptographically random and impossible to guess.
* **`operatingDays`**: Uttara University operates Monday through Thursday for regular classes, while other universities might operate Sunday through Thursday. Storing this allows the routine engine to adapt dynamically.

#### 2. `Department` (Sub-Tenant)
```prisma
model Department {
  id           String     @id @default(uuid())
  universityId String
  name         String     // e.g. "Computer Science & Engineering"
  code         String     // e.g. "CSE"
  university   University @relation(fields: [universityId], references: [id], onDelete: Cascade)
  ...
  @@unique([universityId, code])
}
```
* **`onDelete: Cascade`**: If a university is removed, all its departments are deleted automatically, preventing orphaned records.
* **`@@unique([universityId, code])`**: Ensures that within Uttara University there is only one "CSE" department, but another university can also have a "CSE" department without conflict.

#### 3. `Building` & `Room` (Physical Infrastructure & OCC)
```prisma
model Room {
  id             String     @id @default(uuid())
  universityId   String
  departmentId   String
  buildingId     String
  roomNumber     String     // e.g. "AI Lab 5210 (514)", "5030 (508)"
  floor          Int        @default(1)
  capacity       Int        @default(40)
  currentStatus  RoomStatus @default(AVAILABLE) // AVAILABLE, RUNNING_CLASS, RESERVED, MAINTENANCE
  version        Int        @default(1) // Optimistic Concurrency Control (OCC)
  ...
  @@unique([buildingId, roomNumber])
  @@index([universityId, departmentId, currentStatus])
}
```
* **`currentStatus` Enum**: Tracks real-time state. If a teacher cancels a class, this flips to `AVAILABLE`.
* **`version Int @default(1)`**: The secret weapon for solving race conditions.

#### 4. `RoomLog` (Audit Trail)
* Every time a room's status changes, a record is inserted into `room_logs` recording:
  * `roomId`: Which room.
  * `changedByUserId`: Who changed it.
  * `previousStatus` & `newStatus`: What it was before vs now.
  * `createdAt`: The exact millisecond it happened.
* **Why?** Accountability. If a class was moved and students are confused, the Super Admin can see exactly which CR or Faculty changed it and when.

#### 5. `User` (Identity & 4-Role RBAC)
```prisma
enum Role {
  STUDENT
  CR
  FACULTY
  SUPER_ADMIN
}
```
* Role hierarchy:
  * `SUPER_ADMIN`: Ingests master routine, creates rooms, manages departments.
  * `FACULTY`: Can override their own classes and view schedules.
  * `CR`: Can shift, cancel, or book rooms for their specific `batch` (e.g. 68) and `section` (e.g. A).
  * `STUDENT`: Read-only access to live routine and room statuses.

#### 6. `ScheduleSlot` vs `ScheduleOverride` (The Master-Override Pattern)
* **`ScheduleSlot`**: The static weekly master routine. (e.g. "Every Monday 09:30 - 10:50, AI Lab 5210 is used by Batch 68A for Algorithms").
* **`ScheduleOverride`**: When a class is cancelled for a single day (e.g. teacher is sick on Sept 22), we **never delete** the `ScheduleSlot`! Instead, we create a `ScheduleOverride` record for that specific date.
* **Why this is genius architecture:** Next Monday, the master routine remains intact! You never have to manually restore the schedule.

---

### Database Indexes: Why B-Tree Composite Indexes Matter
Notice this line in `schema.prisma`:
```prisma
@@index([universityId, departmentId, currentStatus])
```
* **Without an index:** If there are 10,000 rooms across 20 universities, a query `SELECT * FROM rooms WHERE status = 'AVAILABLE'` scans all 10,000 rows one by one (a **Full Table Scan**, $O(N)$ time complexity).
* **With a composite index:** PostgreSQL builds an ordered B-Tree on disk. It jumps directly to the matching university and department in $O(\log N)$ time (less than 2 milliseconds).

---

### Optimistic Concurrency Control (OCC)
**The Problem:** Two CRs (CR A and CR B) see Room 5030 is `AVAILABLE`. Both press "Book Room" at the exact same millisecond.
* **Pessimistic Locking (Slow):** The database locks the entire row, making all other users wait.
* **Optimistic Concurrency Control (Fast):**
  1. Room 5030 has `version = 1`.
  2. Both CR A and CR B read `version = 1`.
  3. CR A sends: `UPDATE rooms SET currentStatus = 'RESERVED', version = 2 WHERE id = 'room-5030' AND version = 1;`
     * PostgreSQL finds 1 matching row. Version becomes 2. CR A gets the room!
  4. CR B sends the same update 5 milliseconds later: `WHERE version = 1`.
     * But the room's version is already 2! PostgreSQL updates 0 rows.
     * The backend immediately catches this and responds to CR B: `409 Conflict: Room was just booked by another user.`
  5. **Result:** No double bookings, zero database deadlocks, maximum speed!

---

# 4. Task 1.3: Cloud Database Setup (Neon Serverless PostgreSQL)

### Understanding the Connection String & Pooling
In `backend/.env`:
```env
DATABASE_URL="postgresql://neondb_owner:npg_...ep-snowy-surf-...-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require"
```
* `postgresql://`: The protocol scheme.
* `neondb_owner`: The database username.
* `npg_...`: The cryptographically generated password.
* `ep-snowy-surf-...-pooler`: **The Connection Pooler (PgBouncer)**. Reuses existing TCP connections when hundreds of users connect.
* `us-east-2.aws.neon.tech`: Hosted in AWS Ohio data center on NVMe SSDs.
* `sslmode=require`: All data moving between your server and the cloud is encrypted using TLS/SSL.

---

# 5. Task 1.4: Database Migrations & Seeding Deep-Dive

### What Happens During `prisma migrate dev`?
When we ran `npx prisma migrate dev --name init_multitenant_schema`:
1. Prisma checked `schema.prisma`.
2. It created a migration file: `backend/prisma/migrations/20260916044320_init_multitenant_schema/migration.sql`.
3. It executed the raw SQL `CREATE TABLE`, `CREATE INDEX`, and `ALTER TABLE ADD CONSTRAINT` queries directly on Neon PostgreSQL.
4. It created a special tracking table in PostgreSQL called `_prisma_migrations` so it knows which migrations have already run.

---

### Deep-Dive: `prisma/seed.ts` Line-by-Line
File: [`backend/prisma/seed.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/prisma/seed.ts)

```typescript
// 1. Dependency Cleanup (Order matters!)
await prisma.emergencyAnnouncement.deleteMany();
await prisma.scheduleOverride.deleteMany();
await prisma.scheduleSlot.deleteMany();
await prisma.roomLog.deleteMany();
await prisma.room.deleteMany();
await prisma.building.deleteMany();
await prisma.user.deleteMany();
await prisma.department.deleteMany();
await prisma.university.deleteMany();
```
* **Why in this exact order?** Foreign Key Constraints! If you try to delete `University` first, PostgreSQL throws an error: *"Cannot delete university because departments still reference it!"* We delete child tables first, then parent tables.

```typescript
// 2. Realistic Uttara University Demo Data
const university = await prisma.university.create({
  data: {
    name: 'Uttara University',
    code: 'UU',
    domain: 'uttara.edu.bd',
    operatingDays: [DayOfWeek.MON, DayOfWeek.TUE, DayOfWeek.WED, DayOfWeek.THU],
  },
});
```
* Populates Uttara University with its real-world 4-day academic schedule.

```typescript
// 3. Seed Users with Bcrypt Hashes
const dummyHash = '$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW'; // "Password123!"
```
* We never store plaintext passwords like `"123456"`. We use a deterministic Bcrypt hash so accounts can be authenticated immediately.

---

# 6. Task 1.5: Core NestJS Infrastructure (`src/` folder)

### Prisma Database Service & Global Module
Files: [`backend/src/prisma/prisma.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/prisma/prisma.service.ts) and [`backend/src/prisma/prisma.module.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/prisma/prisma.module.ts)

```typescript
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect(); // Opens database connection when NestJS starts
  }

  async onModuleDestroy() {
    await this.$disconnect(); // Closes pool cleanly when NestJS stops
  }
}
```
* **Senior SWE Principle:** In amateur code, developers instantiate `new PrismaClient()` inside every file. That creates hundreds of open database connections and crashes PostgreSQL. Our `PrismaService` is a **Singleton** managed cleanly by NestJS.

---

### Global HTTP Exception Filter
File: [`backend/src/common/filters/http-exception.filter.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/filters/http-exception.filter.ts)

```typescript
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    ...
    response.status(status).json({
      success: false,
      statusCode: status,
      error,
      message,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
```
* **Why this matters:** When an error occurs (e.g. database disconnects or invalid input), Express normally sends an ugly HTML error page or raw stack trace.
* Our `AllExceptionsFilter` catches **all** errors and formats them into a clean, predictable JSON envelope that your Flutter app can easily parse and display in a friendly alert dialog!

---

### Global Transform Interceptor (Response Envelope)
File: [`backend/src/common/interceptors/transform.interceptor.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/interceptors/transform.interceptor.ts)

```typescript
@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => ({
        success: true,
        statusCode: context.switchToHttp().getResponse().statusCode,
        data,
        timestamp: new Date().toISOString(),
      })),
    );
  }
}
```
* **The Magic of RxJS `map()`:** Every single controller output is intercepted and automatically wrapped inside `{ success: true, statusCode, data, timestamp }`. You never have to manually type `return { success: true }` in your controllers!

---

### Application Bootstrap & Pipeline (`main.ts`)
File: [`backend/src/main.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/main.ts)

```typescript
// 1. Strict DTO stripping
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,              // Strips fields that are not in the DTO
    forbidNonWhitelisted: true,   // Throws an error if extra fields are sent
    transform: true,              // Automatically converts string '123' to number 123
  }),
);

// 2. Global Exception Filter
app.useGlobalFilters(new AllExceptionsFilter());

// 3. Global Response Envelope
app.useGlobalInterceptors(new TransformInterceptor());

// 4. Swagger OpenAPI UI
const config = new DocumentBuilder()
  .setTitle('UniRoom-Live 2.0 API')
  .setVersion('2.0')
  .addBearerAuth(...)
  .build();
SwaggerModule.setup('api/docs', app, document);
```

---

### Health & Diagnostics Controller
File: [`backend/src/health/health.controller.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/health/health.controller.ts)

```typescript
@Get()
async checkHealth() {
  await this.prisma.$queryRaw`SELECT 1`; // Pings PostgreSQL
  const universityCount = await this.prisma.university.count();
  const roomCount = await this.prisma.room.count();
  const slotCount = await this.prisma.scheduleSlot.count();

  return {
    status: 'ok',
    stats: { universities: universityCount, rooms: roomCount, scheduleSlots: slotCount },
  };
}
```
* **Why `SELECT 1`?** It is the fastest possible database query (takes 1 millisecond). It verifies that network connectivity, SSL certificates, and authentication credentials with Neon PostgreSQL are 100% operational.

---

# 7. Milestone 1 Interview & Thesis Defense Q&A

### ❓ Question 1: "Why did you choose PostgreSQL over MongoDB for a timetable system?"
**Answer:**
"A university timetable is intrinsically relational and requires ACID guarantees. A schedule slot links a specific department, room, teacher, batch, and section. In MongoDB, data would be denormalized across documents. If a room number or teacher changes, you would have to update thousands of duplicate documents, leading to data inconsistency. PostgreSQL's foreign keys (`onDelete: Cascade`), relational joins, and ACID transactions guarantee zero data corruption."

### ❓ Question 2: "How does your system prevent two Class Representatives from booking the same room at the same time?"
**Answer:**
"We implemented Optimistic Concurrency Control (OCC) at the database level. Each room record includes an integer `version` field. When a booking request arrives, the SQL UPDATE statement checks `WHERE id = :roomId AND version = :expectedVersion`. If another CR updated the room 5 milliseconds earlier, the version number increments, causing the second query to affect 0 rows. The backend detects this and safely rejects the second request with an HTTP 409 Conflict."

### ❓ Question 3: "What is the purpose of the Master-Override pattern in your routine design?"
**Answer:**
"In traditional systems, cancelling or moving a single class mutates the permanent routine, requiring manual restoration next week. In UniRoom-Live, we separate static and dynamic data: `ScheduleSlot` represents the immutable weekly semester routine, while `ScheduleOverride` represents single-day ad-hoc changes (cancellations, room shifts). The client queries the merged projection of both tables. Once the override date passes, the master schedule automatically resumes with zero manual intervention."

---
