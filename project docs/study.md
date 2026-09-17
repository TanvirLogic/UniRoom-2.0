# 🎓 UniRoom-Live 2.0: Backend Engineering Master Study Guide & Q&A Notebook
> **A complete, beginner-friendly handbook designed to teach you backend development from zero to software engineering excellence.**
>
> *Author / Pair Programmer: Antigravity AI & Tanvir*  
> *Project: UniRoom-Live 2.0*  
> *Location: `project docs/study.md`*

---

## 📌 Table of Contents
1. [Module 1: The Core Mental Model of Backend Engineering](#module-1-the-core-mental-model-of-backend-engineering)
2. [Module 2: Web APIs, HTTP & REST Architecture](#module-2-web-apis-http--rest-architecture)
3. [Module 3: Databases Demystified (Why PostgreSQL?)](#module-3-databases-demystified-why-postgresql)
4. [Module 4: What is an ORM and Why Prisma?](#module-4-what-is-an-orm-and-why-prisma)
5. [Module 5: NestJS Framework Architecture Explained Simply](#module-5-nestjs-framework-architecture-explained-simply)
6. [Module 6: The Request-Response Lifecycle in NestJS](#module-6-the-request-response-lifecycle-in-nestjs)
7. [Module 7: Database Migrations & Seeding in Plain English](#module-7-database-migrations--seeding-in-plain-english)
8. [Module 8: Multi-Tenancy Architecture (SaaS Model)](#module-8-multi-tenancy-architecture-saas-model)
9. [Module 9: Living Student Q&A Journal (Your Questions Answered)](#module-9-living-student-qa-journal)

---

# Module 1: The Core Mental Model of Backend Engineering

### What is Backend Development? (The Restaurant Analogy)
Think of an app like a restaurant:
* **The Frontend (Client / Mobile App):** The Dining Area. It is what the customer sees: comfortable tables, nice menus, beautiful lighting, and buttons they can press.
* **The Backend (Server):** The Kitchen. The customer cannot enter the kitchen, but all the real work happens here: cooking meals, managing ingredients, checking recipes, and ensuring food hygiene.
* **The Database:** The Cold Storage / Pantry. This is where ingredients (data) are stored safely so they don't spoil.
* **The API (Application Programming Interface):** The Waiter. The waiter takes your order from the dining table, carries it to the kitchen, and brings back your food on a clean plate.

```
┌──────────────────┐           HTTP Request (Order)          ┌──────────────────┐
│  Mobile App / UI │  ─────────────────────────────────────► │  NestJS Backend  │
│    (Frontend)    │  ◄───────────────────────────────────── │     (Server)     │
└──────────────────┘          HTTP Response (Plate)          └────────┬─────────┘
                                                                      │ SQL Query
                                                                      ▼
                                                             ┌──────────────────┐
                                                             │    PostgreSQL    │
                                                             │    (Database)    │
                                                             └──────────────────┘
```

### Why Do We Need a Backend at All?
Can't the Flutter mobile app just connect directly to the database?  
**Never! Here is why:**
1. **Security:** If your mobile app directly connected to the database, a hacker could decompile the Flutter APK, extract your database password, and delete all university data.
2. **Business Logic & Validation:** If a student tries to book Room 5030, only the backend can check if they are an approved CR and whether another class is already running there.
3. **Single Source of Truth:** If 500 students are checking the routine simultaneously, the backend coordinates them so everyone sees the exact same real-time data.

---

# Module 2: Web APIs, HTTP & REST Architecture

### What is HTTP?
**HTTP (HyperText Transfer Protocol)** is the standard language computers use to talk across the internet. When your Flutter app talks to our NestJS server, it sends an **HTTP Request** and receives an **HTTP Response**.

### The 5 Most Important HTTP Methods (Verbs):
Whenever a client talks to the backend, it must specify **what action** it wants to perform:

| HTTP Verb | What it Means | Real-World UniRoom Example |
| :--- | :--- | :--- |
| **`GET`** | "Read / Fetch data" | `GET /api/v1/rooms` (Get list of all classrooms) |
| **`POST`** | "Create new data" | `POST /api/v1/auth/login` (Submit login credentials) |
| **`PUT`** | "Replace an entire record" | `PUT /api/v1/rooms/503` (Update all details of Room 503) |
| **`PATCH`** | "Partially update a record" | `PATCH /api/v1/rooms/503/status` (Change status to RESERVED) |
| **`DELETE`** | "Remove data" | `DELETE /api/v1/schedule/slot-99` (Delete an old class slot) |

### HTTP Status Codes (The Universal Feedback System):
Every response the server sends back includes a 3-digit number called a **Status Code**:

* **`2xx` = Success (All good!)**
  * `200 OK`: Request succeeded (e.g., routine data fetched).
  * `201 Created`: New data was created (e.g., user registered successfully).
* **`4xx` = Client Error (The app or user made a mistake)**
  * `400 Bad Request`: The input was invalid (e.g., empty password sent).
  * `401 Unauthorized`: Not logged in (no JWT token provided).
  * `403 Forbidden`: Logged in, but not allowed (e.g., a student trying to ingest master routine).
  * `404 Not Found`: The requested resource does not exist (e.g., Room 9999 doesn't exist).
  * `409 Conflict`: Business rule conflict (e.g., Room already booked for that time).
* **`5xx` = Server Error (The backend crashed or broke)**
  * `500 Internal Server Error`: An unhandled bug or crash in backend code.

---

# Module 3: Databases Demystified (Why PostgreSQL?)

### Relational Database (SQL) vs Document Database (NoSQL)
* **NoSQL (like MongoDB):** Stores data like loose JSON folders. Great for blogs or simple chats where data doesn't have strict relationships.
* **Relational / SQL (like PostgreSQL):** Stores data in structured tables with strict columns, data types, and **foreign key relationships**.

### Why PostgreSQL is Mandatory for University Routine Systems:
A university routine is **deeply interconnected**:
* A **University** has many **Departments**.
* A **Department** has many **Buildings** and **Rooms**.
* A **Room** has many **ScheduleSlots**.
* A **ScheduleSlot** is taught by a **Faculty** and attended by a **Batch & Section**.

If someone deletes a Room, what happens to the classes scheduled in that room? In PostgreSQL, **Foreign Key Constraints** enforce safety rules (like `onDelete: Cascade` or preventing accidental deletion), ensuring data corruption is mathematically impossible.

### ACID Properties (The Financial-Grade Guarantee):
PostgreSQL guarantees **ACID**:
* **A (Atomicity):** All or nothing. If a booking requires 3 steps and step 3 fails, steps 1 and 2 are rolled back automatically.
* **C (Consistency):** Data must strictly follow all rules and types.
* **I (Isolation):** Multiple users doing things at the exact same time don't corrupt each other's data.
* **D (Durability):** Once saved, data survives power outages and server reboots.

---

# Module 4: What is an ORM and Why Prisma?

### The Old Way: Raw SQL Queries
Without an ORM, backend developers had to write raw SQL strings in their code:
```typescript
// ❌ Old, Dangerous Way:
const result = await db.query("SELECT * FROM users WHERE email = '" + req.body.email + "'");
```
**Problems with raw SQL:**
1. **SQL Injection:** A hacker can type `' OR '1'='1` in the email box and access all accounts.
2. **Zero Autocomplete / Typo Disasters:** If you misspell a column name as `emial`, TypeScript won't warn you. It crashes at runtime in production.

### The Modern Way: Prisma ORM
Prisma is an **Object-Relational Mapper**. It reads your database schema and automatically generates a **100% type-safe TypeScript client**:
```typescript
// ✅ Modern, Safe Prisma Way:
const user = await prisma.user.findUnique({
  where: { email: dto.email }
});
// TypeScript knows exactly what fields 'user' has: user.fullName, user.role, etc.
```
* **Autocomplete:** As soon as you type `user.`, VS Code shows every single database field.
* **Security:** Prisma automatically sanitizes and parameterizes all SQL queries, preventing SQL injection attacks completely.

---

# Module 5: NestJS Framework Architecture Explained Simply

### Why NestJS Instead of Plain Express.js?
In plain Express, every developer organizes files differently. As a project grows to 50+ files, Express codebases turn into unmaintainable "spaghetti code."

**NestJS brings architectural discipline.** It uses the exact same patterns used by Google, Angular, and Spring Boot:

```
                  ┌──────────────────────┐
                  │      AppModule       │
                  └──────────┬───────────┘
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   ┌─────────────────┐               ┌─────────────────┐
   │   AuthModule    │               │   RoomsModule   │
   └────────┬────────┘               └────────┬────────┘
     ┌──────┴──────┐                   ┌──────┴──────┐
     ▼             ▼                   ▼             ▼
Controller      Service             Controller    Service
```

### The 3 Core Building Blocks of NestJS:

#### 1. Controllers (The Receptionists / Waiters)
* **Role:** Listen for incoming HTTP requests, read parameters, and send responses.
* **Rule:** Controllers must be **thin**. They should NEVER do complex database math or heavy logic directly. They delegate to Services.
* **Example:**
  ```typescript
  @Controller('rooms')
  export class RoomsController {
    constructor(private readonly roomsService: RoomsService) {}

    @Get()
    getAllRooms() {
      return this.roomsService.findAll();
    }
  }
  ```

#### 2. Services / Providers (The Chefs / Business Logic)
* **Role:** Contain the real business logic. They interact with Prisma, validate business rules, calculate available rooms, and encrypt passwords.
* **Example:**
  ```typescript
  @Injectable()
  export class RoomsService {
    constructor(private readonly prisma: PrismaService) {}

    async findAll() {
      return this.prisma.room.findMany({
        where: { currentStatus: 'AVAILABLE' }
      });
    }
  }
  ```

#### 3. Modules (The Organized Boxes)
* **Role:** Package closely related Controllers and Services together into a self-contained unit (e.g., `AuthModule`, `RoomsModule`, `ScheduleModule`).
* **Benefit:** Keeps the codebase clean, modular, and easy to test.

#### 4. Dependency Injection (DI)
Instead of manually doing `const service = new RoomsService()`, NestJS automatically creates instances and injects them wherever needed via constructors (`constructor(private readonly prisma: PrismaService)`). This decouples code and makes automated testing simple.

---

# Module 6: The Request-Response Lifecycle in NestJS

When a request arrives from the internet, it passes through a pipeline of guards, pipes, interceptors, and filters before reaching your controller:

```
[ Incoming HTTP Request from Mobile / Web ]
                   │
                   ▼
       1. Middleware (CORS, Request Logging)
                   │
                   ▼
       2. Guards (Security Check: Is user logged in? Are they a CR?)
                   │
                   ▼
       3. Interceptors (Before handler: log timing)
                   │
                   ▼
       4. Pipes (Validation: Check DTO types, strip bad fields)
                   │
                   ▼
       5. Controller & Service (Execute Business Logic & Database Query)
                   │
                   ▼
       6. Interceptors (After handler: Wrap response in standard envelope)
                   │
                   ▼
       7. Exception Filters (If anything crashed: Catch and format error JSON)
                   │
                   ▼
[ Standardized Clean JSON Response sent back to Client ]
```

### The 2 Superheroes We Already Built:
1. **`TransformInterceptor` (`backend/src/common/interceptors/transform.interceptor.ts`):**
   * Automatically wraps every single successful API response in:
     ```json
     {
       "success": true,
       "statusCode": 200,
       "data": { ... },
       "timestamp": "2026-09-17T08:00:00.000Z"
     }
     ```
2. **`AllExceptionsFilter` (`backend/src/common/filters/http-exception.filter.ts`):**
   * If any error occurs anywhere in the backend, it catches it and formats it into:
     ```json
     {
       "success": false,
       "statusCode": 404,
       "error": "Not Found",
       "message": "Room AI Lab 5210 does not exist",
       "timestamp": "2026-09-17T08:00:00.000Z",
       "path": "/api/v1/rooms/AI-5210"
     }
     ```

---

# Module 7: Database Migrations & Seeding in Plain English

### What is a Database Migration? (Git for Databases)
* When you write code, you use `git commit` to save changes over time.
* But what happens when you change a database table (e.g., add a new column `capacity` to the `Room` table)?
* If you just manually run an SQL command on your laptop, your production cloud database and other developers won't have that change.
* **Prisma Migrations (`prisma migrate dev`):**
  * Prisma compares your `schema.prisma` file with the actual database.
  * It automatically creates a timestamped SQL file inside `backend/prisma/migrations/`.
  * It executes that SQL file on the target database.
  * Any server running this migration will end up with the exact same database structure!

### What is Database Seeding? (`seed.ts`)
* When you set up a fresh database, it is completely empty.
* You cannot test room bookings, login, or routine schedules without baseline data.
* A **Seeder** is an automated script that populates the database with realistic initial data (Uttara University, CSE Department, Building B, Rooms AI Lab 5210, demo users, routine slots) in one command: `npm run prisma:seed`.

---

# Module 8: Multi-Tenancy Architecture (SaaS Model)

### What does "Multi-Tenant" mean?
* **Single-Tenant App:** Building an app that only works for Uttara University. If another university wants it, you have to buy a new server, deploy a new database, and maintain two separate systems.
* **Multi-Tenant SaaS App (UniRoom-Live):** One single backend and one database that can serve hundreds of universities simultaneously!
* **The Golden Rule of Multi-Tenancy:**
  * Every single query must filter by `universityId`.
  * A student or CR from Uttara University can **never** see or modify rooms or routines belonging to another university. Data isolation is strictly enforced at the database and query levels.

---

# Module 9: Living Student Q&A Journal

> *💡 Note: Whenever you have a question while we build the project, ask it! We will add your question and its full explanation directly here so this file becomes your personalized textbook.*

---

### Q1: "Why did we use Neon.tech instead of installing local PostgreSQL with Docker?"
**Answer:**
1. **Hardware Constraint:** Running Docker Desktop on Windows requires Intel Hardware Virtualization (VT-x) enabled in your computer's BIOS. Your CPU currently has VT-x turned off in firmware.
2. **Serverless & Zero-Cost:** Neon.tech provides a 100% free cloud PostgreSQL database hosted on AWS. It gives us a real cloud connection string immediately without consuming your laptop's CPU or RAM.
3. **Production Simulation:** Connecting to a real cloud database over SSL (`sslmode=require`) teaches you how real-world distributed production backends operate.

---

### Q2: "What is the difference between `npm install` and `npx`?"
**Answer:**
* **`npm install <package>`:** Downloads the package and saves it permanently into your project's `node_modules/` folder.
* **`npx <package>`:** "Node Package Execute". It is used to **run a CLI command or tool** directly (e.g., `npx prisma migrate dev` executes the Prisma CLI without needing to install it globally on your Windows machine).

---

### Q3: "What is Swagger (`/api/docs`) and why do frontend developers love it?"
**Answer:**
Before Swagger, backend developers had to manually write Word or PDF documents explaining every endpoint to mobile developers. These documents were always outdated and buggy.  
**Swagger (OpenAPI)** automatically reads your NestJS code and generates an interactive, live web dashboard at `http://localhost:3000/api/docs`.  
From this webpage, you and your frontend teammates can:
1. See every available API endpoint.
2. View the exact input fields and data types required.
3. Click **"Try it out"** to send real live HTTP requests and see the database responses directly in the browser!

---

### Q4: "What does Optimistic Concurrency Control (OCC) mean in our Room booking?"
**Answer:**
Imagine two Class Representatives (CR 1 and CR 2) both see that **Room 5030** is free at 11:00 AM. Both click "Book Room" at the exact same second.  
* Without OCC, a "race condition" happens: both requests succeed, and two classes show up to the same physical room!
* With OCC, our `Room` table has a `version Int @default(1)` column.
  * CR 1's request says: *"Update Room 5030 to RESERVED where version = 1, and set version = 2"*. (Succeeds!)
  * CR 2's request arrives 10 milliseconds later saying: *"Update Room 5030 where version = 1"*. But the version is now 2! PostgreSQL finds 0 rows matching `version = 1`, and rejects CR 2's booking with a `409 Conflict` error: *"This room was just booked by another user. Please choose another room."*
  * This is how enterprise distributed systems prevent double-booking without slow database locks.

---

### Q5: "আমরা কেন প্রিজমা (Prisma) ব্যবহার করেছি? (Why Prisma?)"
**Answer (বাংলা):**
প্রিজমা হলো একটি **Next-Generation ORM (Object-Relational Mapping)** টুল যা টাইপস্ক্রিপ্ট এবং পোস্টগ্রেস্কেল ডাটাবেজের মধ্যে স্মার্ট ব্রিজ হিসেবে কাজ করে।
1. **১০০% টাইপ-সেফটি:** কোডে টেবিলের নাম বা কলামে টাইপো হলে কোড কম্পাইলই হবে না, ফলে বাগ আগেই ধরা পড়ে।
2. **অটোকমপ্লিট:** কোড লেখার সময় VS Code নিজে থেকেই সব ফিল্ড সাজেস্ট করে।
3. **এসকিউএল ইনজেকশন থেকে শতভাগ সুরক্ষা:** প্রিজমা সব ডেটা প্যারামিটারাইজড কুয়েরি আকারে পাঠায়, কোনো হ্যাকার র' এসকিউএল ইঞ্জেক্ট করতে পারে না।
4. **মাইগ্রেশন সিস্টেম (`prisma migrate`):** ডাটাবেজে টেবিল তৈরি বা পরিবর্তনের হিস্ট্রি গিট (Git) এর মতো ট্র্যাক করে রাখে।
5. **প্রিজমা স্টুডিও (`prisma studio`):** ব্রাউজারেই এক্সেল শিটের মতো ডাটাবেজের সব ডেটা দেখা ও এডিট করা যায়।

---

### Q6: "`src` ফোল্ডারে এ পর্যন্ত কী কী কোড লেখা হয়েছে? (Source Code Breakdown)"
**Answer (বাংলা):**
[`backend/src/`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src) ফোল্ডারে আমাদের ব্যাকএন্ড আর্কিটেকচারের ফাউন্ডেশন কোড রয়েছে:
* **`main.ts`**: অ্যাপ্লিকেশন বুটস্ট্র্যাপ ফাইল। CORS, গ্লোবাল `/api/v1` প্রিফিক্স, ভ্যালিডেশন পাইপ, এরর ফিল্টার, রেসপন্স ইন্টারসেপ্টর এবং Swagger API ডক (`/api/docs`) চালু করে।
* **`app.module.ts`**: রুট মডিউল। পুরো প্রোজেক্টের ডিপেনডেন্সি ও কনফিগারেশন (`.env`, PrismaModule, HealthModule) পরিচালনা করে।
* **`prisma/prisma.service.ts`**: ডাটাবেজের সাথে সংযোগ তৈরি (`onModuleInit`) এবং সার্ভার বন্ধ হলে মেমরি লিক ছাড়া ডিসকানেক্ট (`onModuleDestroy`) করে।
* **`prisma/prisma.module.ts`**: গ্লোবাল মডিউল, যাতে পুরো অ্যাপ্লিকেশনের যেকোনো সার্ভিস ডাটাবেজ ব্যবহার করতে পারে।
* **`common/filters/http-exception.filter.ts`**: কোনো এরর হলে তাকে স্ট্যান্ডার্ড JSON ফরম্যাটে রূপান্তর করে (`{ success: false, statusCode, message, timestamp, path }`)।
* **`common/interceptors/transform.interceptor.ts`**: যেকোনো সফল এপিআই রেসপন্সকে স্ট্যান্ডার্ড খামে মোড়ায় (`{ success: true, statusCode, data, timestamp }`)।
* **`health/health.controller.ts` & `health.module.ts`**: সিস্টেম হেলথ চেক। ডাটাবেজে `SELECT 1` পিং পাঠিয়ে চেক করে এবং বর্তমান বিশ্ববিদ্যালয়, রুম ও রুটিন স্লটের সংখ্যা প্রদর্শন করে।

---

### 🚀 How to Use This File:
* Keep this file open in your IDE whenever we are working.
* Whenever we introduce a new concept (like JWT, Guards, DTOs, Redis, Riverpod), we will add a dedicated section and Q&A entry here.
* Review this guide before any varsity viva or technical job interview!
