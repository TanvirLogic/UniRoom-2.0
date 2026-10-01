# 📘 Milestone 1: Backend Core, Cloud DB & Prisma Multi-Tenant Architecture
> **Language:** 🇬🇧 English | **বাংলা সংস্করণ:** [`milestone_one_bangla.md`](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_one_bangla.md)  
> **Target Audience:** Tanvir (Full-Stack SWE & Academic Defense Candidate)  
> **Status:** `[x]` COMPLETED  
> **File Location:** `project explanation/milestone_one.md`

---

## 📑 Table of Contents
1. [Milestone 1 Objective & Architectural Overview](#1-milestone-1-objective--architectural-overview)
2. [Task 1.1: Backend Project Setup & Monorepo Tooling](#2-task-11-backend-project-setup--monorepo-tooling)
   - [package.json Dependencies Explained](#packagejson-dependencies-explained)
   - [tsconfig.json: Enterprise TypeScript Strictness](#tsconfigjson-enterprise-typescript-strictness)
   - [nest-cli.json](#nest-clijson)
3. [Task 1.2: Multi-Tenant Database Architecture (`schema.prisma`)](#3-task-12-multi-tenant-database-architecture-schemaprisma)
   - [What is Multi-Tenancy and Why Do We Need It?](#what-is-multi-tenancy-and-why-do-we-need-it)
   - [Line-by-Line Breakdown of the Database Models](#line-by-line-breakdown-of-the-database-models)
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

```mermaid
flowchart TD
    Client["Client (Mobile / Web)"] --> CORS["CORS & Global Prefix (/api/v1)"]
    CORS --> Validation["ValidationPipe (class-validator DTOs)"]
    Validation --> Controller["HealthController / Route Controllers"]
    Controller --> Prisma["PrismaService (Lifecycle Management)"]
    Prisma --> NeonDB[("Neon Serverless PostgreSQL (AWS Cloud)")]
    Controller --> Transform["TransformInterceptor ({ success: true, ... })"]
    Controller -.-> ExceptionFilter["AllExceptionsFilter ({ success: false, ... })"]
    Transform --> Response["Uniform HTTP JSON Response"]
    ExceptionFilter --> Response
```

---

# 2. Task 1.1: Backend Project Setup & Monorepo Tooling

### `package.json` Dependencies Explained
In [`backend/package.json`](file:///e:/Varsity%20Project/UniRoom-Live/backend/package.json), every single package was chosen with deliberate architectural intent:

| Package | Purpose in UniRoom-Live | Architectural Role |
| :--- | :--- | :--- |
| `@nestjs/core` & `@nestjs/common` | The core NestJS framework engine. | Provides controllers, services, modules, dependency injection, and decorators (`@Injectable()`, `@Get()`). |
| `@nestjs/config` | Configuration service. | Loads environment variables from `.env` securely throughout the app. |
| `@prisma/client` | Query builder engine. | Auto-generated, 100% type-safe database query builder. |
| `class-validator` & `class-transformer` | Input sanitization & validation. | Validates incoming JSON payloads using decorators (e.g. `@IsEmail()`, `@MinLength(6)`). |
| `rxjs` | Reactive programming library. | Used by NestJS interceptors to transform asynchronous response streams. |
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
   - NestJS relies heavily on decorators (like `@Injectable()`, `@Controller()`, `@Body()`).
   - When TypeScript compiles to JavaScript, decorators normally lose their type information. This flag tells TypeScript to save metadata so NestJS's Dependency Injection container knows what service to inject into what controller!
2. **`strictNullChecks: true`**:
   - Prevents the infamous *"Cannot read properties of undefined"* crash. If a room can be `null`, TypeScript forces you to handle the `if (!room)` case before accessing `room.roomNumber`.
3. **`noImplicitAny: true`**:
   - Disallows un-typed variables. Every parameter must have an explicit type (e.g. `roomId: string`). This prevents hidden runtime bugs.

---

# 3. Task 1.2: Multi-Tenant Database Architecture (`schema.prisma`)
File: [`backend/prisma/schema.prisma`](file:///e:/Varsity%20Project/UniRoom-Live/backend/prisma/schema.prisma)

### What is Multi-Tenancy and Why Do We Need It?
* **Single-Tenant:** You build an app hard-coded for Uttara University. If Dhaka University wants it, you must launch a whole new server and a whole new database. Maintenance becomes a nightmare.
* **Multi-Tenant (Our Architecture):** One single application and database serves **multiple universities**.
  - **Tenant Boundary:** The `University` table is the root tenant.
  - **Data Isolation:** Every department, room, user, and schedule slot stores a `universityId`.
  - When a CR from Uttara University logs in, every SQL query is automatically scoped with `WHERE universityId = '...'`. They can **never** see or modify data from another university.

---

### Line-by-Line Breakdown of Core Database Models

#### 1. `University` (Root Tenant)
```prisma
model University {
  id            String      @id @default(uuid())
  name          String      // e.g. "Uttara University"
  code          String      @unique // e.g. "UU"
  domain        String?     // e.g. "uttara.edu.bd"
  logoUrl       String?
  isActive      Boolean     @default(true)
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt

  campuses      Campus[]
  departments   Department[]
  users         User[]

  @@map("universities")
}
```
* **`id String @id @default(uuid())`**: Primary key. Uses UUID v4 (36 characters) instead of auto-incrementing integers (`1, 2, 3`). Why? Auto-incrementing IDs allow attackers to guess URLs (e.g. `/api/university/1`, `/api/university/2`). UUIDs are cryptographically random and impossible to enumerate.
* **`code String @unique`**: Enforces that no two universities can register with the same code (e.g. only one `"UU"`).
* **`@@map("universities")`**: In TypeScript we use CamelCase (`University`), but in PostgreSQL the table is named `universities` (snake_case) to follow SQL standards.

#### 2. `Campus` & `Building`
```prisma
model Campus {
  id            String      @id @default(uuid())
  universityId  String
  university    University  @relation(fields: [universityId], references: [id], onDelete: Cascade)
  name          String      // e.g. "Main Campus"
  address       String?
  buildings     Building[]
  
  @@unique([universityId, name])
  @@map("campuses")
}
```
* **`onDelete: Cascade`**: If a university account is deleted, PostgreSQL automatically deletes all its campuses and buildings. You never get "orphan" records corrupting your database.
* **`@@unique([universityId, name])`**: Composite unique index. UU can have a "Main Campus", and DU can also have a "Main Campus", but UU cannot have two campuses named "Main Campus".

#### 3. `Room` (Optimistic Concurrency Control OCC)
```prisma
model Room {
  id          String      @id @default(uuid())
  buildingId  String
  building    Building    @relation(fields: [buildingId], references: [id], onDelete: Cascade)
  roomNumber  String      // e.g. "501"
  name        String?     // e.g. "Software Engineering Lab"
  floor       Int
  capacity    Int
  type        RoomType    @default(THEORY)
  facilities  String[]    // PostgreSQL native array: ["PROJECTOR", "AC", "WIFI"]
  isActive    Boolean     @default(true)
  version     Int         @default(1) // OCC Lock Version
  createdAt   DateTime    @default(now())
  updatedAt   DateTime    @updatedAt

  scheduleSlots    ScheduleSlot[]
  scheduleOverrides ScheduleOverride[]
  roomLogs         RoomLog[]

  @@unique([buildingId, roomNumber])
  @@index([buildingId, type, isActive])
  @@map("rooms")
}
```
* **`facilities String[]`**: PostgreSQL native string array. Eliminates the need for a separate `RoomFacilities` join table, drastically speeding up queries.
* **`version Int @default(1)`**: Used for **Optimistic Concurrency Control (OCC)**. When two users try to book Room 501 at the same exact second, this version number prevents double-booking without expensive database row locks!

---

# 4. Task 1.3: Cloud Database Setup (Neon Serverless PostgreSQL)

### Connection String & Pooling
In [`backend/.env`](file:///e:/Varsity%20Project/UniRoom-Live/backend/.env):
```env
DATABASE_URL="postgresql://neondb_owner:npg_secret@ep-cool-fog-a1bc2de.us-east-2.aws.neon.tech/neondb?sslmode=require"
```
* **`postgresql://`**: Protocol standard.
* **`sslmode=require`**: Enforces end-to-end TLS/SSL encryption between the NestJS app and AWS servers. Attackers cannot sniff SQL queries on the network.
* **Neon Serverless Pooling:** Neon automatically scales PostgreSQL connections using PgBouncer, preventing connection exhaustion under heavy load.

---

# 5. Task 1.4: Database Migrations & Seeding Deep-Dive

### What Happens During `prisma migrate dev`?
1. Prisma reads `prisma/schema.prisma`.
2. It compares your schema against the current database state.
3. It generates a pure SQL file in `prisma/migrations/20260916044320_init_multitenant_schema/migration.sql`.
4. It executes the SQL transaction against Neon PostgreSQL.
5. It runs `prisma generate` to update `@prisma/client` types in TypeScript.

### Deep-Dive: `prisma/seed.ts` Line-by-Line
File: [`backend/prisma/seed.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/prisma/seed.ts)
```typescript
// Upsert ensures seeding is idempotent (safe to run multiple times without duplicating)
const uu = await prisma.university.upsert({
  where: { code: 'UU' },
  update: {},
  create: {
    name: 'Uttara University',
    code: 'UU',
    domain: 'uttara.edu.bd',
  },
});
```
* **`upsert`**: If `"UU"` already exists, update nothing. If it does not exist, create it. This guarantees that running `npm run seed` 10 times will never create duplicate rows.

---

# 6. Task 1.5: Core NestJS Infrastructure (`src/` folder)

### 1. Prisma Service & Global Module
File: [`backend/src/prisma/prisma.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/prisma/prisma.service.ts)
```typescript
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect(); // Connects to Neon PostgreSQL on app startup
  }

  async onModuleDestroy() {
    await this.$disconnect(); // Gracefully closes database pool when app shuts down
  }
}
```

### 2. Global Transform Interceptor (Uniform Response Envelope)
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
* Every successful response from your controllers automatically transforms into:
```json
{
  "success": true,
  "statusCode": 200,
  "data": { ... },
  "timestamp": "2026-09-24T03:28:31.629Z"
}
```

### 3. Global Exception Filter
File: [`backend/src/common/filters/http-exception.filter.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/filters/http-exception.filter.ts)
* Catches all unhandled errors and formats them into a clean JSON structure, preventing raw server crashes from reaching the user.

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
*Next Step: Explore [Milestone 2 Handbook](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_two.md) (Authentication, RBAC & Cohort Engine).*
