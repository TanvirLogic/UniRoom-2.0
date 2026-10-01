# UniRoom-Live 2.0: Master Engineering Tasks & Progress Tracker 📋📌

> **Authoritative Execution Tracker**: Task 1 to Final Deployment  
> **Learning Philosophy**: "I will read every feature code task-wise so that I can explain the complete project top to bottom."  
> **Status Indicators**:  
> - `[x]` = **Completed & Verified**  
> - `[/]` = **In Progress**  
> - `[ ]` = **Pending / Ready for Execution**

---

## 🗺️ Milestone Summary & Progress Dashboard

| Milestone | Focus Area | Tasks | Status |
| :--- | :--- | :---: | :---: |
| **Milestone 0** | Architecture Blueprint, System Analysis & Handbooks | Task 0.1 - 0.4 | `[x]` Completed |
| **Milestone 1** | Backend Core, Cloud DB & Prisma Multi-Tenant Schema | Task 1.1 - 1.5 | `[x]` Completed |
| **Milestone 2** | Multi-Tenant Auth, Cryptographic JWT Rotation & RBAC Guards | Task 2.1 - 2.8 | `[x]` Completed |
| **Milestone 3** | Universities, Departments, Campuses, Rooms & Web Admin Portal | Task 3.1 - 3.6 | `[x]` Completed |
| **Milestone 4** | Super Admin Dual-Mode Routine Ingestion (AI + JSON) | Task 4.1 - 4.5 | `[ ]` Queued |
| **Milestone 5** | Real-Time Engine, WebSockets, Redis Pub/Sub & OCC Locking | Task 5.1 - 5.5 | `[ ]` Queued |
| **Milestone 6** | Smart Leases, Auto-Release Cron & Emergency Announcements | Task 6.1 - 6.4 | `[ ]` Queued |
| **Milestone 7** | Multi-Channel Notifications (Resend Email + FCM Push) | Task 7.1 - 7.4 | `[ ]` Queued |
| **Milestone 8** | Faculty Schedule Aggregation & Section CR Daily Overrides | Task 8.1 - 8.4 | `[ ]` Queued |
| **Milestone 8.5**| Auto Classrooms, CR Attendance Engine & Faculty 1-on-1 Chat | Task 8.5.1 - 8.5.5 | `[ ]` Queued |
| **Milestone 9** | Mobile Clean Architecture Foundation (Flutter + Riverpod 2.x) | Task 9.1 - 9.5 | `[ ]` Queued |
| **Milestone 10**| Mobile Screens & Reactive State (Student, CR & Faculty Views) | Task 10.1 - 10.6| `[ ]` Queued |
| **Milestone 11**| Automated Testing Trophy (Unit, Widget, Supertest E2E) | Task 11.1 - 11.5| `[ ]` Queued |
| **Milestone 12**| CI/CD Pipeline (GitHub Actions) & Zero-Cost Cloud Deployment | Task 12.1 - 12.4| `[ ]` Queued |

---

## 📌 Milestone 0: Foundation & System Design (`[x]` COMPLETED)

- [x] **Task 0.1: Master Architectural Blueprint**
  - **Goal**: Formulate C4 architecture, 5-year SWE skill matrix, and project charter.
  - **Artifact**: [`docs/complete_project.md`](docs/complete_project.md)
  - **Interview Defense**: Explains the transition from prototype to an enterprise modular monolith.
- [x] **Task 0.2: Bengali Technology Justification Guide**
  - **Goal**: Deep dive into why Flutter, Riverpod, NestJS, Postgres, and Redis were selected.
  - **Artifact**: [`docs/guide.md`](docs/guide.md)
- [x] **Task 0.3: Complete System Analysis & Requirements Document**
  - **Goal**: Formulate 4-role RBAC, FRs, NFRs, race conditions, and zero-cost strategy.
  - **Artifact**: [`docs/system_analysis.md`](docs/system_analysis.md)
- [x] **Task 0.4: Final System Design & Future Distributed Systems Handbook**
  - **Goal**: Back-of-the-envelope calculations, composite indexing, CAP theorem, and free YouTube courses hub.
  - **Artifacts**: [`docs/system_design.md`](docs/system_design.md) & [`docs/future_system_design_handbook.md`](docs/future_system_design_handbook.md)

---

## 🚀 Milestone 1: Backend Core, Cloud DB & Prisma Multi-Tenant Schema (`[x]` COMPLETED)

> 📘 **Detailed Milestone 1 Guide**: [`project docs/milestone_one.md`](project%20docs/milestone_one.md) (Prerequisites, dependencies, and task breakdown)  
> 📘 **Detailed Architecture Learning Guides**:  
> - English Master Handbook: [`project explanation/milestone_one.md`](project%20explanation/milestone_one.md)  
> - বাংলা সংস্করণ: [`project explanation/milestone_one_bangla.md`](project%20explanation/milestone_one_bangla.md)

- [x] **Task 1.1: Backend Project Initialization & Monorepo Structure**
  - **Objective**: Initialize `backend/` using TypeScript and NestJS with strict ESLint and Prettier configs.
  - **SWE Principle**: Modular Monolith foundation, TypeScript strict mode (zero `any`).
  - **Files**: `backend/package.json`, `backend/tsconfig.json`, `backend/nest-cli.json`, `backend/src/main.ts`.
  - **Verification**: Run `npm run build` with 0 compilation errors.

- [x] **Task 1.2: Multi-Tenant Prisma Schema Design**
  - **Objective**: Define relational schema: `University`, `Department`, `Building`, `Room`, `User`, `ScheduleSlot`, `ScheduleOverride`, `RoomLog`.
  - **SWE Principle**: Relational data integrity, Foreign key constraints, Composite unique constraints (preventing duplicate room names in the same building).
  - **Files**: `backend/prisma/schema.prisma`.
  - **Verification**: `npx prisma validate` runs clean.

- [x] **Task 1.3: Database Infrastructure (Neon Serverless PostgreSQL Cloud)**
  - **Objective**: Configure serverless PostgreSQL on AWS cloud with TLS/SSL encryption and connection pooling (`pooler`).
  - **SWE Principle**: Zero-cost, high-availability serverless relational storage with PgBouncer pooling.
  - **Files**: `backend/.env`, `backend/.env.example`.
  - **Verification**: TLS encrypted connection established to Neon AWS us-east-2.

- [x] **Task 1.4: Initial Database Migration & Seeding**
  - **Objective**: Execute the first automated migration (`init_multitenant_schema`) and create seed scripts for sample Universities (Uttara University) and Departments (CSE).
  - **SWE Principle**: Automated Database Versioning, Repeatable Seeding.
  - **Files**: `backend/prisma/migrations/`, `backend/prisma/seed.ts`.
  - **Verification**: Applied migration `20260916044320_init_multitenant_schema` and seeded 4 rooms, 4 core user roles, and 3 master schedule slots.

- [x] **Task 1.5: Core Cross-Cutting Infrastructure (Global Filters & Pipes & Swagger)**
  - **Objective**: Setup Global ValidationPipe (`class-validator`), Global HTTP Exception Filter, Transform Interceptor, and Swagger OpenAPI at `/api/docs`.
  - **SWE Principle**: Centralized Error Handling, uniform API response envelopes (`{ success: true, data: ..., timestamp: ... }`).
  - **Files**: `backend/src/common/filters/`, `backend/src/common/interceptors/`, `backend/src/health/`, `backend/src/main.ts`.
  - **Verification**: `GET /api/v1/health` and Swagger UI at `/api/docs`.

---

## 🔑 Milestone 2: Multi-Tenant Authentication & Cryptographic RBAC (`[x]` COMPLETED)

> 📘 **Detailed Milestone 2 Guide**: [`project docs/milestone_two.md`](project%20docs/milestone_two.md) (Specifications, DTO contracts, and security architecture)  
> 📘 **Detailed Architecture Learning Guides**:  
> - English Master Handbook: [`project explanation/milestone_two.md`](project%20explanation/milestone_two.md)  
> - বাংলা সংস্করণ: [`project explanation/milestone_two_bangla.md`](project%20explanation/milestone_two_bangla.md)  
> - Master Directory: [`project explanation/README.md`](project%20explanation/README.md)

- [x] **Task 2.1: Password Hashing & User Registration Service**
  - **Objective**: Secure registration endpoint for Students, CRs, and Faculty with `bcrypt` (10 rounds).
  - **SWE Principle**: Cryptographic salt & hashing; prevention of rainbow table attacks.
  - **Files**: `backend/src/modules/auth/auth.service.ts`, `backend/src/modules/auth/dto/register.dto.ts`.
  - **Verification**: Verified registration of Student and CR via `POST /api/v1/auth/register`.

- [x] **Task 2.2: JWT Access Token (15m) & Refresh Token Rotation (7d)**
  - **Objective**: Implement short-lived Access Token and secure Refresh Token Rotation pattern.
  - **SWE Principle**: Token Rotation Pattern, stateless fast authorization, window-of-vulnerability reduction.
  - **Files**: `backend/src/modules/auth/strategies/jwt.strategy.ts`, `backend/src/modules/auth/auth.controller.ts`.
  - **Verification**: Verified `POST /api/v1/auth/login` and `POST /api/v1/auth/refresh` issuing new token pairs.

- [x] **Task 2.3: Multi-Tenant Guard (`TenantGuard`)**
  - **Objective**: Extract `universityId` and `departmentId` from JWT and enforce query scoping.
  - **SWE Principle**: Zero Cross-Tenant Data Leaks, Multi-Tenant Logical Boundary Enforcement.
  - **Files**: `backend/src/common/guards/tenant.guard.ts`.
  - **Verification**: Cross-tenant violations rejected with HTTP 403 Forbidden.

- [x] **Task 2.4: Role-Based Access Control (`RolesGuard`)**
  - **Objective**: Implement `@Roles(Role.SUPER_ADMIN, Role.CR, Role.FACULTY, Role.STUDENT)` decorator and guard.
  - **SWE Principle**: Principle of Least Privilege (PoLP).
  - **Files**: `backend/src/common/decorators/roles.decorator.ts`, `backend/src/common/guards/roles.guard.ts`.
  - **Verification**: Verified Student calling `/api/v1/auth/admin-test` receives HTTP 403 Forbidden, while Super Admin receives HTTP 200 OK.

- [x] **Task 2.5: Interactive Swagger / OpenAPI 3.0 Documentation**
  - **Objective**: Auto-generate live API documentation at `/api/docs` with Bearer auth support.
  - **SWE Principle**: Self-documenting API, Contract-First development.
  - **Files**: `backend/src/modules/auth/auth.controller.ts`, `backend/src/main.ts`.
  - **Verification**: Swagger UI live at `http://localhost:3000/api/docs` with Bearer JWT authorizer.

- [x] **Task 2.6: Institutional Email Verification via Gmail SMTP ($0 Free Tier)**
  - **Objective**: 6-digit cryptographically generated PIN sent to institutional email upon registration; user activated upon verification.
  - **SWE Principle**: Defense-in-depth, 60s cooldown rate limiting, 5-attempt brute-force protection, hashed PIN storage.
  - **Files**: `backend/src/modules/email/`, `backend/src/modules/auth/dto/verify-email.dto.ts`.
  - **Verification**: Live email dispatch verified with real Gmail SMTP.

- [x] **Task 2.7: Cryptographic Forgot Password & Password Reset Pipeline**
  - **Objective**: Endpoints `POST /auth/forgot-password`, `POST /auth/verify-reset-pin`, and `POST /auth/reset-password` using dedicated `PasswordResetPin` table.
  - **SWE Principle**: Zero replay attacks, automatic cleanup upon reset, authenticated password hashing.
  - **Files**: `backend/src/modules/auth/dto/forgot-password.dto.ts`, `reset-password.dto.ts`.
  - **Verification**: Complete automated test suite passed.

- [x] **Task 2.8: Institutional `studentId` Roll Number Registration & `/auth/me` Profile Enrichment**
  - **Objective**: Require institutional `studentId` (e.g. `2241081422`) for Student and CR registrations; expose in JWT and `/auth/me`.
  - **SWE Principle**: Strong institutional identity for academic section rosters and attendance tracking.
  - **Files**: `backend/prisma/schema.prisma`, `backend/src/modules/auth/dto/register.dto.ts`, `backend/src/modules/auth/auth.service.ts`.
  - **Verification**: Complete integration test verified registration, uniqueness validation, and `/auth/me` extraction.

---

## 🚪 Milestone 3: Universities, Departments, Campuses & Rooms Module (`[x]` COMPLETED)

> 📘 **Detailed Milestone 3 Guide**: [`project docs/milestone_three.md`](project%20docs/milestone_three.md) (Campus hierarchy, room engine specs, and 1-tap algorithm)  
> 📘 **Detailed Architecture Learning Guides**:  
> - English Master Handbook: [`project explanation/milestone_three.md`](project%20explanation/milestone_three.md)  
> - বাংলা সংস্করণ: [`project explanation/milestone_three_bangla.md`](project%20explanation/milestone_three_bangla.md)  
> - Master Directory: [`project explanation/README.md`](project%20explanation/README.md)

- [x] **Task 3.1: University & Department Management (Super Admin)**
  - **Objective**: Endpoints to create and manage Universities and Departments.
  - **Files**: `backend/src/modules/universities/`.
  - **Verification**: CRUD operations verified via integration tests and Swagger.

- [x] **Task 3.2: Multi-Campus & Building Disambiguation**
  - **Objective**: Add Building and Floor models to rooms (e.g. "Permanent Campus - Building B, 5th Floor").
  - **Files**: `backend/src/modules/rooms/dto/create-building.dto.ts`, `backend/src/modules/rooms/dto/create-room.dto.ts`.
  - **Verification**: Room creation mandates campus and building attribution; compound uniqueness `[buildingId, roomNumber]`.

- [x] **Task 3.3: Room Availability Query Engine (Optimized Index Reads)**
  - **Objective**: Endpoint `GET /api/v1/rooms` with filtering by Department, Status, Building, Campus, Floor, Capacity, and Search.
  - **SWE Principle**: Composite B-Tree indexing query optimization and multi-tenant scoping.
  - **Files**: `backend/src/modules/rooms/rooms.service.ts`, `backend/src/modules/rooms/rooms.controller.ts`.
  - **Verification**: Query returns paginated rooms and live status summary counts (available, running, reserved, maintenance).

- [x] **Task 3.4: "Find Me a Free Room Now" 1-Tap Algorithm**
  - **Objective**: Algorithmic endpoint taking `durationMinutes`, `minCapacity`, and `startTime`, returning ranked free rooms.
  - **SWE Principle**: Relational interval overlap calculation (`slot.startTime < reqEnd && slot.endTime > reqStart`) merged with daily `ScheduleOverride` cancellation rules.
  - **Files**: `backend/src/modules/rooms/rooms.service.ts`, `backend/src/modules/rooms/dto/find-free-room.dto.ts`.
  - **Verification**: Successfully ranks available rooms with next class preview and remaining free minutes.

- [x] **Task 3.5: Optimistic Concurrency Control (OCC) & Audit Logging**
  - **Objective**: Endpoint `PATCH /api/v1/rooms/:id/status` enforcing OCC version checks and appending to `RoomLog`.
  - **SWE Principle**: Race-condition prevention without heavy row locks; audit trail for status modifications.
  - **Files**: `backend/src/modules/rooms/rooms.service.ts`, `backend/src/modules/rooms/dto/update-room-status.dto.ts`.
  - **Verification**: Concurrent update conflict returns HTTP 409 ConflictException; valid update increments version and writes `RoomLog`.

- [x] **Task 3.6: Clean UI/UX Web Admin Portal (`web/`)**
  - **Objective**: Modern, high-performance Super Admin web portal using React 18, Vite, Tailwind CSS, and Lucide icons.
  - **SWE Principle**: Multi-tenant tenant switcher, responsive data tables, live OCC status toggles, visual batch & cohort studio, and zero-canvas overhead.
  - **Files**: `web/src/` (Auth, Dashboard, Universities, Departments, Cohorts Studio, Rooms Inventory).
  - **Verification**: Production build compiles with 0 errors (`npm run build`), authenticated against NestJS backend on `:3000`.

---

## 📑 Milestone 4: Super Admin Dual-Mode Routine Ingestion Engine

- [ ] **Task 4.1: Routine Ingestion Data Contracts & Zod Validation**
  - **Objective**: Strict DTO schema for class slots (`batch`, `section`, `day`, `slot`, `courseCode`, `facultyCode`, `roomNumber`).
  - **SWE Principle**: Input sanitization and structural contract validation.
  - **Files**: `backend/src/modules/schedules/dto/ingest-routine.dto.ts`.

- [ ] **Task 4.2: Mode A - Built-in Free AI Parser (Google Gemini Flash)**
  - **Objective**: Endpoint receiving timetable PDF/image, sending to Gemini Flash with structured JSON output.
  - **SWE Principle**: Multimodal Document Extraction at $0 cost.
  - **Files**: `backend/src/modules/schedules/services/ai-parser.service.ts`.
  - **Verification**: Uploading 1 page of the Uttara University PDF returns structured JSON array.

- [ ] **Task 4.3: Mode B - External AI Prompt Template & JSON Ingestion**
  - **Objective**: Endpoint allowing Super Admin to paste external JSON from ChatGPT/Claude with pre-validation.
  - **SWE Principle**: Human-in-the-Loop Validation, Graceful Degradation.
  - **Files**: `backend/src/modules/schedules/schedules.controller.ts`.
  - **Verification**: Invalid JSON returns specific line-item schema errors.

- [ ] **Task 4.4: Atomic Database Hydration (Bulk Insert Transaction)**
  - **Objective**: Execute single PostgreSQL transaction creating missing Rooms, Faculty mappings, and 380+ ScheduleSlots.
  - **SWE Principle**: Database Atomicity (all succeed or none do).
  - **Files**: `backend/src/modules/schedules/services/schedule-ingestion.service.ts`.
  - **Verification**: Ingestion of 5-page PDF runs in < 2.0 seconds.

- [ ] **Task 4.5: Super Admin Interactive Verification & Preview Gateway**
  - **Objective**: Staging endpoint returning parsed slots for review before final commit.
  - **Files**: `backend/src/modules/schedules/`.
  - **Verification**: Misparsed room names can be edited in preview payload before saving.

---

## ⚡ Milestone 5: Real-Time Engine, WebSockets & Concurrency Control

- [ ] **Task 5.1: Redis Cache-Aside Implementation for Room States**
  - **Objective**: Cache department room status in Redis Hashes with sub-2ms response times.
  - **SWE Principle**: Cache-Aside pattern, in-memory latency reduction.
  - **Files**: `backend/src/modules/rooms/services/room-cache.service.ts`.

- [ ] **Task 5.2: Optimistic Concurrency Control (OCC) for Room Status Updates**
  - **Objective**: Implement atomic status toggle with `version` field verification.
  - **SWE Principle**: Double-booking race condition prevention without table-level deadlocks.
  - **Files**: `backend/src/modules/rooms/rooms.service.ts`.
  - **Verification**: Simultaneous concurrent requests trigger HTTP 409 Conflict for the second request.

- [ ] **Task 5.3: NestJS WebSocket Gateway (Socket.io)**
  - **Objective**: Create real-time gateway with department-scoped rooms (`join:dept_{id}`).
  - **SWE Principle**: Full-duplex event streaming, targeted room channels.
  - **Files**: `backend/src/modules/realtime/realtime.gateway.ts`.
  - **Verification**: Client receives `room:status_updated` event within 50ms of status change.

- [ ] **Task 5.4: Redis Pub/Sub Adapter for Horizontal WebSocket Scaling**
  - **Objective**: Hook Socket.io into Redis adapter so multiple API instances broadcast events uniformly.
  - **SWE Principle**: Horizontally scalable WebSocket cluster.
  - **Files**: `backend/src/modules/realtime/redis-io.adapter.ts`.

- [ ] **Task 5.5: Audit Trail Logger (`RoomLog`)**
  - **Objective**: Automatically record every room status change with user ID, timestamp, and previous status.
  - **SWE Principle**: Accountability, Non-repudiation, System Auditing.
  - **Files**: `backend/src/modules/rooms/services/audit.service.ts`.

---

## ⏰ Milestone 6: Smart Leases, Auto-Release Cron & Announcements

- [ ] **Task 6.1: Smart Room Lease & Expiry Engine**
  - **Objective**: Require duration (45m, 60m, 90m) when occupying rooms, calculating `leaseExpiresAt`.
  - **Files**: `backend/src/modules/rooms/rooms.service.ts`.

- [ ] **Task 6.2: Background Self-Healing Cron Job (Auto-Release)**
  - **Objective**: Scheduled task running every 60s reverting expired rooms from `RUNNING_CLASS` to `AVAILABLE`.
  - **SWE Principle**: Self-Healing Systems, eliminating "Ghost Occupied" rooms.
  - **Files**: `backend/src/modules/rooms/jobs/room-expiry.job.ts`.
  - **Verification**: Manually set expired timestamp; room auto-reverts and emits WebSocket event.

- [ ] **Task 6.3: Super Admin Emergency Campus Broadcast Banner**
  - **Objective**: Endpoints to create and deactivate urgent campus-wide announcement banners.
  - **Files**: `backend/src/modules/announcements/`.
  - **Verification**: Active banner appears in public API query with high priority.

- [ ] **Task 6.4: Configurable University Operational Days**
  - **Objective**: Support dynamic operating schedules (e.g. Mon-Thu for Uttara, Sun-Thu for DU).
  - **Files**: `backend/src/modules/universities/dto/update-config.dto.ts`.

---

## 🔔 Milestone 7: Multi-Channel Notifications (Email + FCM)

- [ ] **Task 7.1: Asynchronous Job Queue Setup (BullMQ + Redis)**
  - **Objective**: Offload emails and pushes to background queues to keep API latency < 50ms.
  - **SWE Principle**: Asynchronous Decoupling, Fast Response Times.
  - **Files**: `backend/src/modules/queue/`.

- [ ] **Task 7.2: Transactional Email Service (Resend / Nodemailer - $0 Cost)**
  - **Objective**: Automated email to Super Admin with 1-click HMAC-signed link to approve CR candidates.
  - **Files**: `backend/src/modules/notifications/email.service.ts`.
  - **Verification**: Test email dispatched with clickable approve link.

- [ ] **Task 7.3: Firebase Cloud Messaging (FCM) Integration ($0 Cost)**
  - **Objective**: Backend SDK integration dispatching topic-based pushes (`dept_{id}_batch_{id}_sec_{id}`).
  - **Files**: `backend/src/modules/notifications/push.service.ts`.
  - **Verification**: Triggering class shift sends test push to topic.

- [ ] **Task 7.4: Automated 10-Minute Lease Countdown Push to CRs**
  - **Objective**: Background job notifying CR 10 minutes before room lease expiry ("Extend or Release").
  - **Files**: `backend/src/modules/rooms/jobs/lease-warning.job.ts`.

---

## 👨‍🏫 Milestone 8: Faculty Aggregation & Section CR Daily Overrides

- [ ] **Task 8.1: Automated Faculty Schedule Aggregator**
  - **Objective**: Endpoint `GET /api/v1/schedules/my-classes` aggregating all slots by `faculty_user_id`.
  - **SWE Principle**: Relational Projection, Zero-Config UI for teachers.
  - **Files**: `backend/src/modules/schedules/schedules.service.ts`.
  - **Verification**: Teacher logs in and views all classes across multiple batches in chronological order.

- [ ] **Task 8.2: 1-Click Faculty Action (Cancel Class / Release Room Early)**
  - **Objective**: Teacher cancels class for today; system updates status and pushes FCM notification to students.
  - **Files**: `backend/src/modules/schedules/controllers/faculty-schedule.controller.ts`.

- [ ] **Task 8.3: Section CR Daily Override Engine**
  - **Objective**: Endpoints for CR to cancel or reschedule today's slot without corrupting Master Routine.
  - **SWE Principle**: Separation of Master State from Temporal Overrides.
  - **Files**: `backend/src/modules/schedules/services/override.service.ts`.
  - **Verification**: Today's class cancelled; tomorrow reverts back to base weekly routine automatically.

- [ ] **Task 8.4: Student "My Routine Today" Personalization Endpoint**
  - **Objective**: Endpoint `GET /api/v1/schedules/my-routine` returning current, upcoming, and free slots for student's section.
  - **Files**: `backend/src/modules/schedules/controllers/student-schedule.controller.ts`.

---

## 🏛️ Milestone 8.5: Auto Classrooms, CR Attendance Engine & Faculty 1-on-1 Chat

- [ ] **Task 8.5.1: Routine-Driven Virtual Classroom Ingestion & Membership Mapping**
  - **Objective**: When Master Routine is ingested, automatically instantiate virtual classrooms for each unique `(Course, Faculty, Batch, Section)` triplet with zero manual setup.
  - **SWE Principle**: Event-driven Relational Projection, automated group membership.
  - **Files**: `backend/src/modules/classrooms/`.

- [ ] **Task 8.5.2: CR Section Student Roster & Live Attendance Engine**
  - **Objective**: Endpoint `GET /api/v1/attendance/roster` for verified CRs to fetch registered students of their batch & section, and `POST /api/v1/attendance/session` to log attendance for a specific course & time slot.
  - **SWE Principle**: Role-scoped authorization, transactional snapshot logging.
  - **Files**: `backend/src/modules/attendance/`.

- [ ] **Task 8.5.3: CR 1-Tap Formatted Clipboard Attendance Exporter**
  - **Objective**: Formatter endpoint producing clean export text (`2241081422 - Md Tanvir Ahmed ,\n2241081417 - Mst Sumona Akter Liza`) for instant WhatsApp/Messenger/Email faculty handoff.
  - **SWE Principle**: Mobile Ergonomics & Frictionless User Experience.
  - **Files**: `backend/src/modules/attendance/attendance.service.ts`.

- [ ] **Task 8.5.4: Faculty Academic Hub (Exam/Quiz Notices & Resource PDF Uploads)**
  - **Objective**: Endpoints for Course Faculty to post urgent exam/quiz notices and upload/link lecture slides, lab manuals, and PDF study materials.
  - **Files**: `backend/src/modules/classrooms/notices/`, `backend/src/modules/classrooms/resources/`.

- [ ] **Task 8.5.5: Dedicated 1-to-1 Real-Time Chat (Section CR ↔ Course Faculty)**
  - **Objective**: Private, direct messaging channel strictly between the Section CR and the Course Faculty teaching that section to coordinate attendance, class shifts, and syllabus discussions.
  - **SWE Principle**: Scoped P2P Messaging, noise elimination.
  - **Files**: `backend/src/modules/chat/`.

---

## 📱 Milestone 9: Mobile Clean Architecture & Complete Authentication Suite (Flutter + Provider)

- [x] **Task 9.1: Flutter Mobile Workspace Initialization & Minimalist Theme (Sky Blue, Blue, White)**
  - **Objective**: Initialize clean Flutter 3.x project in `mobile/` with a modern, minimalist design system using Sky Blue (`#0284C7`), Deep Blue (`#1D4ED8`), and Crisp White (`#FFFFFF`, `#F8FAFC`).
  - **SWE Principle**: Cohesive Material 3 Design System, responsive typography, rounded cards (16px), subtle shadows.
  - **Files**: `mobile/pubspec.yaml`, `mobile/lib/core/theme/app_theme.dart`, `mobile/lib/core/constants/app_colors.dart`.
  - **Verification**: `flutter analyze` passes with 0 issues.

- [x] **Task 9.2: Local Storage & Clean HTTP Service Layer (`AuthService` + `SharedPreferences`)**
  - **Objective**: Lightweight, reliable HTTP service consuming NestJS auth endpoints (`/auth/register`, `/auth/login`, `/auth/verify-email`, `/auth/forgot-password`, `/auth/reset-password`, `/auth/me`) and persistent token storage.
  - **SWE Principle**: Separation of Concerns, Clean Error Extraction.
  - **Files**: `mobile/lib/core/constants/api_constants.dart`, `mobile/lib/services/auth_service.dart`.
  - **Verification**: Integration tested against live NestJS endpoints.

- [x] **Task 9.3: Auth Domain Entity Model (`UserModel`)**
  - **Objective**: Clean Dart entity model representing student/CR/faculty profile with `fromJson` and `toJson` serialization.
  - **SWE Principle**: Strongly Typed Domain Modeling, Null Safety.
  - **Files**: `mobile/lib/models/user_model.dart`.

- [x] **Task 9.4: Reactive State Management with Provider (`AuthProvider extends ChangeNotifier`)**
  - **Objective**: Beginner-friendly and viva-defensible state management managing `isLoading`, `errorMessage`, `user`, and `pendingEmail`.
  - **SWE Principle**: Unidirectional Data Flow, `notifyListeners()` triggering clean UI rebuilds.
  - **Files**: `mobile/lib/providers/auth_provider.dart`.

- [x] **Task 9.5: Minimalist Modern Auth UI Screens (Sky Blue & White Design)**
  - **Objective**: Complete suite of modern, user-friendly authentication screens:
    1. **Splash Screen**: Animated logo + session restoration.
    2. **Login Screen**: Minimalist input cards, show/hide password, "Forgot Password?" link, register navigation.
    3. **Registration Screen**: Role toggle (Student / CR / Faculty), input fields for `studentId`, `batch`, `section`, `facultyId`, `fullName`, `email`, `password`.
    4. **Email PIN Verification Screen**: 6-digit PIN input, 60s cooldown timer, resend button.
    5. **Forgot & Reset Password Screens**: Step A (Enter email) -> Step B (Enter PIN & new password) with feedback snackbars.
    6. **Home / Dashboard Landing Screen**: Greeting with role badge, academic profile breakdown, quick actions, and sign-out dialog.
  - **SWE Principle**: Responsive UI, Form Validation, Clear Feedback.
  - **Files**: `mobile/lib/screens/`.
  - **Verification**: Verified with `flutter analyze` (0 issues) and `flutter test` (all passed).

- [x] **Task 9.6: Database-Driven Cascading Dropdowns (University $\to$ Department $\to$ Batch $\to$ Section)**
  - **Objective**: Replace manual batch/section text entry with dynamic, database-backed cascading dropdowns populated via `GET /api/v1/meta/registration-options`. Super Admins configure batches and sections, and routine ingestion automatically discovers new ones.
  - **SWE Principle**: Cascading Reactive UI, Data Normalization, Single Source of Truth.
  - **Files**: `backend/src/modules/meta/`, `mobile/lib/models/registration_options_model.dart`, `mobile/lib/services/auth_service.dart`, `mobile/lib/providers/auth_provider.dart`, `mobile/lib/screens/register_screen.dart`.
  - **Verification**: Verified live endpoint against Neon DB, unit tests in `mobile/test/registration_options_test.dart`, and widget tests in `mobile/test/register_screen_test.dart`.

---

## 🎨 Milestone 10: Mobile Reactive Screens, Role Nav Shell & Real-Time Automation

> **Theme**: Clean Modern White (`#FFFFFF`, `#F8FAFC`), Sky Blue (`#0284C7`), and Light Blue (`#E0F2FE`) Palette.

- [x] **Task 10.1: Design Tokens & Palette Refinement (White, Sky Blue, Light Blue)**
  - **Objective**: Refine `app_colors.dart` and `app_theme.dart` with 20px rounded cards, frosted AppBars, subtle sky drop shadows, and responsive typography hierarchy.
  - **Files**: `mobile/lib/core/constants/app_colors.dart`, `mobile/lib/core/theme/app_theme.dart`.

- [x] **Task 10.2: Backend Profile Update API (`PATCH /api/v1/auth/profile`)**
  - **Objective**: Endpoint allowing students and CRs to update `fullName`, `studentId`, `departmentId`, `batch`, and `section` with relational integrity and sanitized profile response.
  - **Files**: `backend/src/modules/auth/auth.controller.ts`, `backend/src/modules/auth/auth.service.ts`.

- [x] **Task 10.3: Mobile Data Services & State Providers (`ScheduleService`, `RoomService`)**
  - **Objective**: Services & Providers to fetch schedules (`GET /api/v1/schedules`), calculate real-time running/upcoming slots, and trigger room status updates (`PATCH /api/v1/rooms/:id/status`).
  - **Files**: `mobile/lib/services/schedule_service.dart`, `mobile/lib/services/room_service.dart`, `mobile/lib/providers/schedule_provider.dart`, `mobile/lib/providers/room_provider.dart`.

- [x] **Task 10.4: Dynamic Role-Based Navigation Shell (`MainNavigationShell`)**
  - **Objective**: Custom bottom navigation bar automatically tailored by user role:
    - **Student**: Today / Live Schedule ➔ Weekly Routine Matrix ➔ Free Rooms ➔ Cohort Profile
    - **CR**: Today / Live Schedule ➔ CR Command & Broadcast ➔ Weekly Routine Matrix ➔ Cohort Profile
    - **Faculty**: Today's Lectures ➔ Weekly Schedule ➔ Campus Rooms ➔ Faculty Profile
  - **Files**: `mobile/lib/screens/main_navigation_shell.dart`.

- [x] **Task 10.5: Automated "Running Class" Engine & Today's Schedule Screen**
  - **Objective**: Real-time interval matching comparing device clock against today's routine slots. Displays hero card with live pulsing badge for current running class, countdown timer for upcoming classes, room numbers, floors, and teacher codes.
  - **Files**: `mobile/lib/screens/today_schedule_screen.dart`.

- [x] **Task 10.6: Weekly Routine Matrix Screen with Interactive Day & Course Filters**
  - **Objective**: Day-by-day timetable view with horizontal pill selectors (MON-SUN), course code search, and room details.
  - **Files**: `mobile/lib/screens/weekly_routine_screen.dart`.

- [x] **Task 10.7: CR Command Center (1-Tap Room Release & In-App Broadcast Alerts)**
  - **Objective**: CR dashboard allowing 1-tap room freeing ("Make Room Free") when class is cancelled or dismissed early. Updates room to `AVAILABLE` with OCC version lock and triggers broadcast alert to other CRs and students.
  - **Files**: `mobile/lib/screens/cr_command_screen.dart`.

- [x] **Task 10.8: 1-Tap Free Room Finder Screen (Building & Floor Grouping)**
  - **Objective**: Real-time listing of available rooms across campus buildings showing capacity, floor, and free duration windows.
  - **Files**: `mobile/lib/screens/free_rooms_screen.dart`.

- [x] **Task 10.9: Faculty Schedule View (Initials-Based Timetable Mapping)**
  - **Objective**: Personalized teacher view filtered by faculty code (e.g. `DNS`) displaying assigned rooms, floors, student batches, and upcoming class countdown.
  - **Files**: `mobile/lib/screens/faculty_schedule_screen.dart`.

- [x] **Task 10.10: Student & CR Cohort Profile Editor with Instant Re-Alignment**
  - **Objective**: Interactive profile screen with "Edit Cohort" sheet enabling students and CRs to update their Department, Batch, Section, Name, and Student ID. Saving updates backend profile and triggers reactive timetable reload with zero app restart.
  - **Files**: `mobile/lib/screens/cohort_profile_screen.dart`.

---

## 🧪 Milestone 11: Production Automated Testing Trophy

- [ ] **Task 11.1: Backend Unit Tests (Jest)**
  - **Objective**: Unit tests for Room Concurrency, JWT rotation, and Ingestion Parser with 100% mocked DB.
  - **Files**: `backend/src/**/*.spec.ts`.
  - **Verification**: `npm run test` passes with > 80% coverage.

- [ ] **Task 11.2: Backend End-to-End API Integration Tests (Supertest)**
  - **Objective**: Test full HTTP flow: Register ➔ Login ➔ Ingest Routine ➔ Occupy Room ➔ Verify WebSocket.
  - **Files**: `backend/test/app.e2e-spec.ts`.
  - **Verification**: `npm run test:e2e` passes.

- [ ] **Task 11.3: Mobile Domain & UseCase Unit Tests (Mocktail)**
  - **Objective**: Unit test Riverpod Notifiers and UseCases with mocked Dio client.
  - **Files**: `mobile/test/features/**/*_test.dart`.
  - **Verification**: `flutter test` passes.

- [ ] **Task 11.4: Mobile Widget Tests**
  - **Objective**: Widget test `RoomCard`, `StatusBadge`, and `LoginForm` in isolation.
  - **Files**: `mobile/test/widgets/room_card_test.dart`.

- [ ] **Task 11.5: End-to-End Mobile Flow Test (`integration_test`)**
  - **Objective**: Automated integration test launching app, logging in, and navigating dashboard.
  - **Files**: `mobile/integration_test/app_test.dart`.

---

## 🚢 Milestone 12: DevOps, CI/CD & Production Zero-Cost Deployment

- [ ] **Task 12.1: Multi-Stage Production Dockerfile for Backend**
  - **Objective**: Lean, hardened multi-stage Docker build for NestJS (< 150MB image).
  - **Files**: `backend/Dockerfile`.

- [ ] **Task 12.2: GitHub Actions Automated CI Pipeline**
  - **Objective**: Automatic pipeline running linting, type-checking, backend tests, and Flutter tests on every PR.
  - **Files**: `.github/workflows/ci.yml`.
  - **Verification**: Green checkmark on GitHub pull request.

- [ ] **Task 12.3: Free Cloud Database & Cache Deployment (Neon + Upstash)**
  - **Objective**: Deploy live PostgreSQL on Neon.tech and Redis on Upstash ($0/month).
  - **Verification**: Cloud connection string verified.

- [ ] **Task 12.4: Free Cloud Backend Deployment (Render / Railway)**
  - **Objective**: Deploy Dockerized NestJS API on free cloud tier with automated Git deploy.
  - **Verification**: Live public Swagger docs accessible at `https://uniroom-api.onrender.com/api/docs`.

---

> 🎯 **Next Immediate Action**: We begin with **Task 1.1: Backend Project Initialization & Monorepo Structure**!
