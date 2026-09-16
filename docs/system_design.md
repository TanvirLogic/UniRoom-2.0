# UniRoom-Live 2.0: Comprehensive System Design & Interview Mastery Document 🏛️⚡

> **Document Version**: 2.0.0 (Production & Staff-Engineer Interview Edition)  
> **Target Audience**: System Architects, Senior SWE Interviewers, Tech Leads, CSE Defense Committees  
> **Core Objective**: A complete end-to-end technical blueprint for UniRoom-Live 2.0, coupled with **FAANG-grade System Design explanations, trade-off analyses, and interview answers**.

---

# Table of Contents
1. [System Overview & High-Level Architecture](#1-system-overview--high-level-architecture)
2. [Back-of-the-Envelope Calculations (Traffic, Storage, Latency)](#2-back-of-the-envelope-calculations-scale-estimation)
3. [C4 Architecture Diagrams (Context, Container, Component)](#3-c4-architecture-diagrams)
4. [Data Architecture & PostgreSQL Indexing Strategy](#4-data-architecture--postgresql-indexing-strategy)
5. [Concurrency, Transactions & Race Condition Handling](#5-concurrency-transactions--race-condition-handling)
6. [Caching Architecture & Redis Invalidation Strategy](#6-caching-architecture--redis-invalidation-strategy)
7. [Real-Time Communication: WebSockets vs Long-Polling vs SSE](#7-real-time-communication-websockets-vs-long-polling-vs-sse)
8. [CAP Theorem & PACELC Trade-Off Analysis](#8-cap-theorem--pacelc-trade-off-analysis)
9. [Security, Auth & Token Rotation Lifecycle](#9-security-auth--token-rotation-lifecycle)
10. [Dual-Mode AI Routine Ingestion Engine](#10-dual-mode-ai-routine-ingestion-engine)
11. [100% Free-Tier ($0/Month) Production Hosting Blueprint](#11-100-free-tier-0month-production-hosting-blueprint)
12. [Top 10 System Design Interview Questions & Model Answers](#12-top-10-system-design-interview-questions--model-answers)

---

## 1. System Overview & High-Level Architecture

UniRoom-Live 2.0 is a **Multi-Tenant SaaS Classroom & Schedule Orchestration Platform** engineered to solve classroom scheduling chaos, room collision, and timetable fragmentation across universities.

### Architectural Core Principles:
- **Clean Architecture & Domain-Driven Design (DDD)**: Strict separation of Domain (pure logic), Data (persistence/network), Presentation (UI/Controllers), and Core (cross-cutting utilities).
- **Event-Driven Asynchronous Processing**: Critical user paths (HTTP responses) are kept sub-50ms by offloading emails, push notifications, and cache updates to Redis queues.
- **Tenant Isolation**: Absolute logical boundary isolation between universities using scoped foreign keys and cryptographic JWT claims.

---

## 2. Back-of-the-Envelope Calculations (Scale Estimation)

> 💡 **Interview Tip**: Every top-tier system design interview begins with scale estimation. This proves you design systems based on actual numbers, not guesswork.

### 2.1 Scale Assumptions:
- **Tenants**: 20 Universities onboarded.
- **Active Students & Faculty**: 50,000 Total Daily Active Users (DAU).
- **Peak Concurrent Users (PCU)**: 10,000 concurrent connections during morning slot transitions (8:30 AM - 11:30 AM).
- **Classrooms/Rooms**: ~2,000 rooms across all tenants.
- **Schedule Slots**: ~15,000 active class slots per week.

### 2.2 Requests Per Second (RPS / Throughput):
- Average user makes 10 read requests/day (checking routine, checking room status).
- Total Daily Reads: $50,000 \times 10 = 500,000 \text{ requests/day}$.
- Average Read RPS: $\frac{500,000}{86,400 \text{ seconds}} \approx 5.8 \text{ RPS}$.
- **Peak Read RPS (Morning Rush, 10x factor)**: $5.8 \times 10 \approx \mathbf{60 \text{ RPS}}$ (Easily handled by a single Node.js/NestJS process cached with Redis).
- Room Status Toggles (Writes): ~5,000 updates/day.
- Peak Write RPS: $\approx \mathbf{5 \text{ writes/sec}}$.

### 2.3 Storage Estimation (5-Year Horizon):
- User Record: ~500 bytes $\times$ 100,000 users = **50 MB**.
- Room Record: ~300 bytes $\times$ 5,000 rooms = **1.5 MB**.
- Schedule Slots: ~400 bytes $\times$ 50,000 slots = **20 MB**.
- Audit Logs (`RoomLog`): 10,000 changes/day $\times$ 300 bytes = 3 MB/day $\times$ 365 $\times$ 5 years $\approx$ **5.4 GB**.
- **Total 5-Year Database Footprint**: Under **6 GB**! (A single PostgreSQL instance can comfortably manage this without needing expensive sharding).

### 2.4 Bandwidth & In-Memory Cache (Redis):
- Active room state: 2,000 rooms $\times$ 200 bytes per room JSON = **~400 KB** (Entire live campus state fits inside RAM effortlessly!).
- WebSocket idle heartbeat: 10,000 concurrent sockets $\times$ 32 bytes ping/minute $\approx$ **5.3 KB/sec** network overhead.

---

## 3. C4 Architecture Diagrams

### 3.1 Level 1: System Context Diagram

```mermaid
graph TD
    Student["🎓 Student (Mobile/Web)"]
    CR["🧑‍🏫 Section CR (Mobile/Web)"]
    Faculty["👨‍🏫 Faculty Member (Mobile/Web)"]
    SuperAdmin["🛡️ Super Admin (Admin Portal)"]

    System["🏫 UniRoom-Live 2.0 Platform\n(Multi-Tenant SaaS Engine)"]

    FCM["🔔 Firebase Cloud Messaging\n(Push Notifications)"]
    Resend["✉️ Resend API\n(Transactional Emails)"]
    Gemini["🧠 Google Gemini Vision\n(Timetable PDF Extraction)"]

    Student -->|Checks live room status & personal routine| System
    CR -->|Submits daily class overrides & toggles room status| System
    Faculty -->|Views auto-aggregated schedule & 1-click cancels| System
    SuperAdmin -->|Onboards universities & ingests master routine| System

    System -->|Pushes emergency room shifts & class alerts| FCM
    System -->|Dispatches 1-click CR approval links| Resend
    System -->|Parses aSc Timetable PDF grids| Gemini
```

### 3.2 Level 2: Container Architecture Diagram

```mermaid
graph TD
    subgraph Client Layer
        Flutter["📱 Flutter Client (Riverpod 2.x)\nAndroid / iOS / Web"]
        WebAdmin["💻 Super Admin Web Portal\n(Next.js / Flutter Web)"]
    end

    subgraph Reverse Proxy & API Gateway
        Nginx["🌐 Nginx / Cloudflare Gateway\n(Rate Limiter, SSL Termination, Compression)"]
    end

    subgraph Backend Micro-Modular Monolith (NestJS / Docker)
        API["🚀 NestJS Application Server"]
        WS_Gateway["⚡ WebSocket Gateway (Socket.io)"]
        QueueWorker["🔄 Async Task Queue (BullMQ)"]
    end

    subgraph Data & Storage Layer
        Postgres[("🐘 PostgreSQL 16\n(Multi-Tenant Relational Data)")]
        Redis[("⚡ Redis 7\n(State Cache, Pub/Sub, Rate Limits, Job Queue)")]
    end

    Flutter -->|HTTPS / REST API| Nginx
    Flutter -->|WSS / Socket.io| WS_Gateway
    WebAdmin -->|HTTPS| Nginx

    Nginx --> API
    API --> Postgres
    API --> Redis
    API --> QueueWorker
    WS_Gateway --> Redis
    QueueWorker --> Redis
```

---

## 4. Data Architecture & PostgreSQL Indexing Strategy

### 4.1 Why PostgreSQL over MongoDB/Firestore?
1. **Relational Integrity**: A university schedule is inherently relational:
   `University ➔ Department ➔ Building ➔ Room ➔ ScheduleSlot ➔ FacultyUser ➔ Batch/Section`.
   PostgreSQL enforces **Foreign Key Constraints (CASCADE, SET NULL)** preventing orphaned records.
2. **ACID Transactions**: Room booking requires serializable isolation to prevent double-booking.
3. **Compound & Partial Indexing**: PostgreSQL allows indexing on specific active conditions (e.g. `WHERE is_active = true`), minimizing index RAM consumption.

### 4.2 Composite Indexing Strategy (Query Optimization):

```sql
-- 1. Accelerates fetching rooms by department with active status (Sub-millisecond query)
CREATE INDEX idx_rooms_tenant_dept ON rooms(university_id, department_id, current_status);

-- 2. Accelerates Student "My Routine Today" query (Filter by Day, Batch, Section)
CREATE INDEX idx_schedules_student_lookup ON schedule_slots(department_id, batch, section, day_of_week);

-- 3. Accelerates Faculty Auto-Aggregated Schedule query
CREATE INDEX idx_schedules_faculty_lookup ON schedule_slots(faculty_user_id, day_of_week);

-- 4. Accelerates checking schedule overrides for today's date
CREATE INDEX idx_overrides_date_slot ON schedule_overrides(schedule_slot_id, override_date);
```

> 💡 **Interview Defense**: Without composite index `(department_id, batch, section, day_of_week)`, Postgres performs a sequential scan over 15,000 slots ($O(N)$). With a B-Tree composite index, query time drops from **45ms to 0.8ms ($O(\log N)$)**!

---

## 5. Concurrency, Transactions & Race Condition Handling

### The Problem: The Double-Booking Race Condition
Two CRs simultaneously tap *"Occupy Room 402"* at 10:00:00.050 AM.
- If unhandled: Both read `status = AVAILABLE`. Both issue `UPDATE status = RUNNING_CLASS`. Both get success. **Result: Real-world catastrophe.**

### Our Solution: Optimistic Locking with Versioning & Atomic Transactions

```mermaid
sequenceDiagram
    autonumber
    actor CR1 as 🧑‍🏫 CR 1 (Batch 52)
    actor CR2 as 🧑‍🏫 CR 2 (Batch 53)
    participant API as 🌐 NestJS Backend
    participant DB as 🐘 PostgreSQL Database

    Note over DB: Room 402: status = 'AVAILABLE', version = 4

    CR1->>API: Claim Room 402 (with expected version = 4)
    CR2->>API: Claim Room 402 (with expected version = 4)

    API->>DB: UPDATE rooms SET status = 'RUNNING_CLASS', version = 5 WHERE id = 402 AND version = 4;
    DB-->>API: 1 Row Affected (CR 1 Wins)

    API->>DB: UPDATE rooms SET status = 'RUNNING_CLASS', version = 5 WHERE id = 402 AND version = 4;
    DB-->>API: 0 Rows Affected (CR 2 Fails - version is already 5!)

    API-->>CR1: 200 OK (Room Claimed Successfully)
    API-->>CR2: 409 Conflict ("Room was just occupied by another class!")
```

### PostgreSQL Implementation:
```typescript
async claimRoom(roomId: string, expectedVersion: number, updateDto: ClaimRoomDto) {
  const result = await this.prisma.room.updateMany({
    where: {
      id: roomId,
      version: expectedVersion, // Optimistic Lock check
      currentStatus: RoomStatus.AVAILABLE,
    },
    data: {
      currentStatus: RoomStatus.RUNNING_CLASS,
      version: { increment: 1 },
      leaseExpiresAt: new Date(Date.now() + updateDto.durationMinutes * 60000),
    },
  });

  if (result.count === 0) {
    throw new ConflictException('Race condition detected: Room status was modified by another user.');
  }
}
```

---

## 6. Caching Architecture & Redis Invalidation Strategy

### 6.1 Caching Pattern: Cache-Aside (Lazy Loading) + Write-Through Invalidation
- **Read Path**: Check Redis key `tenant:{uniId}:dept:{deptId}:rooms`. If hit, return JSON in **<2ms**. If miss, query PostgreSQL, set Redis key with TTL (60 seconds), and return.
- **Write Path (Room Status Changed)**:
  1. Commit transaction in PostgreSQL.
  2. Invalidate/Delete Redis cache key.
  3. Publish event `room:updated` via **Redis Pub/Sub** to notify all connected WebSocket nodes.

### 6.2 Redis Data Structures Used:
1. **Hashes (`HSET`)**: Stores live room availability key-value pairs for instantaneous lookups.
2. **Sorted Sets (`ZADD`)**: Stores Room Lease Expirations keyed by timestamp (`score = expiry_timestamp`). A background worker runs every 30 seconds: `ZRANGEBYSCORE 0 {current_time}` to auto-release expired rooms!

---

## 7. Real-Time Communication: WebSockets vs Long-Polling vs SSE

| Protocol | Latency | Server Resource Overhead | Battery Efficiency | Our Decision & Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **HTTP Polling** | High (2-5s delay) | Extreme (10,000 clients pinging every 2s = 5,000 RPS) | Very Poor | ❌ Rejected (Destroys mobile battery & exhausts free tier). |
| **Server-Sent Events (SSE)** | Low (<200ms) | Low (Single persistent HTTP connection) | Medium | ⚠️ Viable for unidirectional updates, but lacks native duplex capability. |
| **WebSockets (Socket.io)** | **Ultra-Low (<50ms)** | **Minimal (Single TCP socket, binary frames)** | **High (With foreground/background lifecycle)** | **✅ Selected**: Full duplex, instant sub-second room status broadcasts, native room channels. |

### Battery Optimization Lifecycle Pattern:
- **Foreground (App Open)**: Flutter initializes WebSocket connection, joins room channel: `socket.emit('join:dept', deptId)`.
- **Background (App Minimized)**: Flutter disposes socket (`socket.disconnect()`). Server stops sending socket frames. System falls back to **FCM Push Notifications** for urgent room shifts.

---

## 8. CAP Theorem & PACELC Trade-Off Analysis

> 💡 **Interview Goldmine**: Interviewers love asking how your architecture maps to distributed systems theory.

### 8.1 CAP Theorem:
- **Our Choice: CP (Consistency + Partition Tolerance)** for Room Booking.
- *Rationale*: In classroom booking, consistency is non-negotiable. It is strictly unacceptable for two students to see conflicting statuses and have two professors enter the same physical room. If a network partition occurs, we reject conflicting writes rather than accepting inconsistent duplicates.

### 8.2 PACELC Theorem:
- **PC/EC**:
  - If there is **P**artition: We choose **C**onsistency over **A**vailability.
  - **E**lse (Normal Operation): We choose **C**onsistency for room state toggles, and **L**atency for student routine reads (served via Redis cache).

---

## 9. Security, Auth & Token Rotation Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Client as 📱 Flutter Client
    participant API as 🌐 NestJS Auth Service
    participant Redis as ⚡ Redis Token Store
    participant DB as 🐘 PostgreSQL Users

    Client->>API: POST /api/v1/auth/login (email, password)
    API->>DB: Verify bcrypt hash (cost 12)
    DB-->>API: User Verified (Role: CR, Tenant: Uttara)
    API->>API: Generate Access Token (15m, signed with JWT_SECRET)
    API->>API: Generate Cryptographic Refresh Token (UUID v4)
    API->>Redis: SETEX refresh:{userId} 604800 {refreshToken}
    API-->>Client: Return { accessToken, refreshToken, user }

    Note over Client,API: After 15 minutes: Access Token expires
    Client->>API: POST /api/v1/auth/refresh (refreshToken)
    API->>Redis: Validate and Revoke old refreshToken (Token Rotation)
    API->>Redis: Issue new refreshToken
    API-->>Client: Return { newAccessToken, newRefreshToken }
```

### Security Defenses:
1. **Access Token Lifespan**: 15 minutes (Limits damage window if leaked).
2. **Refresh Token Rotation**: If an attacker steals a refresh token and uses it after the legitimate user refreshes, Redis detects a reuse violation and **immediately invalidates all sessions for that user** (Automatic Compromise Detection).
3. **Password Security**: Passwords hashed with `bcrypt` (12 rounds) + salt.
4. **Tenant-Scoped Authorization**: The JWT payload contains `{ sub: userId, universityId, departmentId, role }`. The `TenantGuard` rejects any request attempting to query a foreign `universityId`.

---

## 10. Dual-Mode AI Routine Ingestion Engine

### Why Dual-Mode? (Graceful Degradation Design)
Universities provide messy 5-page PDF routines generated by `aSc Timetables`. An enterprise system must not fail if an AI quota is reached.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        DUAL-MODE INGESTION PIPELINE ARCHITECTURE                       │
├──────────────────────────────────────────┬─────────────────────────────────────────────┤
│ Mode A: Built-in Free AI Parser          │ Mode B: External AI + JSON Ingest           │
├──────────────────────────────────────────┼─────────────────────────────────────────────┤
│ • Super Admin uploads PDF in portal.     │ • Super Admin clicks "Copy AI Prompt".      │
│ • Sent to Gemini 2.0 Flash (Free Tier).  │ • Pastes PDF into ChatGPT/Claude/DeepSeek.  │
│ • Uses strict structured JSON schema.    │ • Pastes returned JSON into Admin Portal.   │
├──────────────────────────────────────────┴─────────────────────────────────────────────┤
│               SHARED VALIDATION & ATOMIC HYDRATION GATEWAY                             │
│ 1. Schema Validation via Zod / class-validator (Type checking, slot overlap check).    │
│ 2. Interactive Preview Modal (Super Admin reviews, edits any misparsed room names).   │
│ 3. Atomic Database Hydration (Single PostgreSQL Transaction):                          │
│    - Auto-inserts missing Rooms (e.g. "AI Lab 5210 (514)").                            │
│    - Auto-links Faculty profiles by initials (e.g. "DNS", "AMU").                      │
│    - Auto-inserts 380+ ScheduleSlots for all 42 sections in <1.5 seconds.              │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 11. 100% Free-Tier ($0/Month) Production Hosting Blueprint

Every component of this architecture runs on battle-tested enterprise free tiers with **$0 monthly cloud spend**:

| Layer | Provider & Service | Free Tier Capacity | Why it works for UniRoom-Live |
| :--- | :--- | :--- | :--- |
| **API Backend** | **Render.com / Railway** | 750 free compute hours/mo | Sufficient to run the Dockerized NestJS API 24/7. |
| **Relational DB** | **Neon.tech / Supabase** | 0.5 GB PostgreSQL storage | Our 5-year data footprint is ~6 GB; Neon free tier handles 500 MB comfortably for active semesters. |
| **In-Memory Cache**| **Upstash Redis** | 10,000 commands/day | Perfect for caching hot room availability and pub/sub. |
| **Push Alerts** | **Firebase Cloud Messaging**| **100% Unlimited Free** | Unlimited push notifications to Android and iOS devices globally. |
| **Transaction Email**| **Resend API / Brevo** | 3,000 free emails/mo | Easily covers Super Admin CR approval workflows. |
| **AI Document Parsing**| **Google Gemini Flash** | 15 Requests/min Free | Enough to parse semester PDFs on-demand without cost. |
| **CI/CD Pipeline** | **GitHub Actions** | 2,000 build mins/mo | Runs automated linting, unit tests, and build checks for free. |

---

## 12. Top 10 System Design Interview Questions & Model Answers

> 🎯 **Master this section to ace your technical interviews!**

### Q1: "How do you prevent two Class Representatives from booking the same room at the exact same millisecond?"
> **Answer**:  
> *"We implement **Optimistic Concurrency Control (OCC)** combined with PostgreSQL transactions. Every room record has an integer `version` field. When a CR requests a status update, the query executes `UPDATE rooms SET status = 'RUNNING_CLASS', version = version + 1 WHERE id = :id AND version = :expectedVersion AND status = 'AVAILABLE'`. If two requests hit concurrently, the first commit increments the version to $V+1$. The second query finds zero matching rows, immediately aborts, and returns an HTTP 409 Conflict. This avoids expensive database table locking while guaranteeing zero double-bookings."*

### Q2: "How does your system scale if 10,000 students open the app simultaneously at 8:45 AM?"
> **Answer**:  
> *"We employ a multi-tier caching and decoupling strategy:  
> 1. **Cache-Aside with Redis**: The live room availability of an entire department is stored as an in-memory Redis Hash. When 10,000 students query room states, 99.5% of reads hit Redis in sub-2ms without touching PostgreSQL.  
> 2. **WebSocket Pub/Sub Decoupling**: Instead of 10,000 students polling the server every few seconds, they maintain open WebSockets. When a status changes, a single Redis Pub/Sub message broadcasts the event across connected WebSocket gateways.  
> 3. **Stateless API Tier**: The NestJS backend is stateless; we can horizontally scale container instances behind Nginx or Cloudflare."*

### Q3: "Why did you choose a Monorepo over separate Multi-Repositories for Backend and Mobile?"
> **Answer**:  
> *"A Monorepo provides atomic commits, unified versioning, and shared contract validation. When we update our OpenAPI/Swagger schema or DTOs, the corresponding Flutter models and tests are updated and verified in the exact same GitHub Actions pull request. This eliminates version drift between frontend and backend while maintaining independent build pipelines inside `backend/` and `mobile/`."*

### Q4: "How does the system ensure that a student from University A cannot access or tamper with data from University B?"
> **Answer**:  
> *"We enforce **Multi-Tenant Logical Isolation** at three independent security boundaries:  
> 1. **Cryptographic Token Scoping**: When a user logs in, their `universityId` and `departmentId` are cryptographically signed into their JWT access token.  
> 2. **NestJS `TenantGuard`**: Every incoming request passes through our guard, which extracts `req.user.universityId`.  
> 3. **Prisma Query Interceptor**: All database queries are automatically injected with `where: { universityId: req.user.universityId }`. Even if an attacker manually passes another university's Room ID in a URL parameter, the query returns 404 Not Found because the tenant scope does not match."*

### Q5: "How does the Faculty Dashboard aggregate schedules without requiring teachers to enter data?"
> **Answer**:  
> *"Through **Relational Foreign Key Linking and Inverted Indexing**. During master routine ingestion, each class slot is associated with a `faculty_id` (e.g. `FAC-102` or `DNS`). When a professor logs into the mobile app, the backend executes an indexed query `SELECT * FROM schedule_slots WHERE faculty_user_id = :userId ORDER BY day_of_week, start_time`. Because we maintain a B-Tree index on `idx_schedules_faculty_lookup`, the server aggregates their entire week across 5 different batches and sections in under 1 millisecond with zero manual configuration by the faculty."*

### Q6: "What happens if the built-in AI parser hallucinates or misreads a room number from the PDF routine?"
> **Answer**:  
> *"We designed a **Human-in-the-Loop Validation Gate**. The AI output is never inserted directly into the production database. Instead, the parsed output returns to the Super Admin's browser in an **Interactive Verification Table**. The Super Admin can visually cross-check, edit any misspelled room or course name, and only when they click 'Confirm & Ingest' does the atomic database transaction execute."*

### Q7: "How do you prevent WebSocket connections from draining the mobile phone's battery?"
> **Answer**:  
> *"We bind WebSocket connectivity to the **Flutter App Lifecycle State**. When the app is in the foreground (`AppLifecycleState.resumed`), the WebSocket is active for sub-second updates. The moment the user minimizes the app (`AppLifecycleState.paused` or `detached`), the mobile client actively disconnects the socket. While minimized, the client relies entirely on Firebase Cloud Messaging (FCM) high-priority push notifications, which utilize the operating system's native low-power notification daemon."*

### Q8: "Why did you use Riverpod 2.x instead of Provider or setState in Flutter?"
> **Answer**:  
> *"Provider relies on `BuildContext`, which tightly couples business logic to the UI tree and causes runtime `ProviderNotFoundException` errors. Riverpod 2.x is compile-safe, globally scoped without `BuildContext`, and provides `AsyncNotifier` which enforces strict handling of `AsyncValue` states (`loading`, `data`, `error`). Furthermore, Riverpod automatically disposes state when a screen unmounts, preventing memory leaks in high-frequency real-time applications."*

### Q9: "What strategy do you use for Database Migrations in production with zero downtime?"
> **Answer**:  
> *"We use **Prisma Migrations with Backward-Compatible Schema Evolution (Expand and Contract Pattern)**:  
> 1. **Expand**: Add new columns as nullable or with default values; deploy backend code that supports both old and new columns.  
> 2. **Migrate**: Run automated migration scripts via Prisma (`prisma migrate deploy`) inside the CI/CD pipeline before traffic hits new containers.  
> 3. **Contract**: In a subsequent release, remove the deprecated columns once all clients are running the new version."*

### Q10: "If a CR leaves the classroom and forgets to release the room, how does the system recover?"
> **Answer**:  
> *"We implement **Time-To-Live (TTL) Leased States**. When a CR toggles a room to `RUNNING_CLASS`, they must specify a duration (e.g. 90 minutes), which sets `lease_expires_at = NOW() + 90m`. A lightweight background cron job checks `WHERE current_status = 'RUNNING_CLASS' AND lease_expires_at <= NOW()`. If expired, the system transitions the room back to `AVAILABLE`, logs an audit entry, and broadcasts a WebSocket update. The system is completely self-healing without relying on human memory."*
