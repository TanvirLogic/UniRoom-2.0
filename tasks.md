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
| **Milestone 2** | Multi-Tenant Auth, Cryptographic JWT Rotation & RBAC Guards | Task 2.1 - 2.5 | `[ ]` Queued |
| **Milestone 3** | Universities, Departments, Campuses & Rooms Module | Task 3.1 - 3.4 | `[ ]` Queued |
| **Milestone 4** | Super Admin Dual-Mode Routine Ingestion (AI + JSON) | Task 4.1 - 4.5 | `[ ]` Queued |
| **Milestone 5** | Real-Time Engine, WebSockets, Redis Pub/Sub & OCC Locking | Task 5.1 - 5.5 | `[ ]` Queued |
| **Milestone 6** | Smart Leases, Auto-Release Cron & Emergency Announcements | Task 6.1 - 6.4 | `[ ]` Queued |
| **Milestone 7** | Multi-Channel Notifications (Resend Email + FCM Push) | Task 7.1 - 7.4 | `[ ]` Queued |
| **Milestone 8** | Faculty Schedule Aggregation & Section CR Daily Overrides | Task 8.1 - 8.4 | `[ ]` Queued |
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
> - Bengali: [`project explanation/milestone_one_learning_bangla.md`](project%20explanation/milestone_one_learning_bangla.md)  
> - English: [`project explanation/milestone_one_learning_english.md`](project%20explanation/milestone_one_learning_english.md)  
> - Lifecycle: [`project explanation/src_execution_lifecycle.md`](project%20explanation/src_execution_lifecycle.md)

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

## 🔑 Milestone 2: Multi-Tenant Authentication & Cryptographic RBAC

- [ ] **Task 2.1: Password Hashing & User Registration Service**
  - **Objective**: Secure registration endpoint for Students, CRs, and Faculty with `bcrypt` (12 rounds).
  - **SWE Principle**: Cryptographic salt & hashing; prevention of rainbow table attacks.
  - **Files**: `backend/src/modules/auth/auth.service.ts`, `backend/src/modules/auth/dto/register.dto.ts`.
  - **Verification**: Unit test verifying plain-text passwords are never saved.

- [ ] **Task 2.2: JWT Access Token (15m) & Refresh Token Rotation (7d)**
  - **Objective**: Implement short-lived Access Token and secure Redis-backed Refresh Token Rotation.
  - **SWE Principle**: Token Rotation Pattern, Automatic session revocation on token reuse detection.
  - **Files**: `backend/src/modules/auth/strategies/jwt.strategy.ts`, `backend/src/modules/auth/auth.controller.ts`.
  - **Verification**: Refresh endpoint issues new pair and invalidates old refresh token in Redis.

- [ ] **Task 2.3: Multi-Tenant Guard (`TenantGuard`)**
  - **Objective**: Extract `universityId` and `departmentId` from JWT and enforce query scoping.
  - **SWE Principle**: Zero Cross-Tenant Data Leaks, Multi-Tenant Logical Boundary Enforcement.
  - **Files**: `backend/src/common/guards/tenant.guard.ts`.
  - **Verification**: User from University A attempting to query University B gets HTTP 403 Forbidden.

- [ ] **Task 2.4: Role-Based Access Control (`RolesGuard`)**
  - **Objective**: Implement `@Roles(Role.SUPER_ADMIN, Role.CR, Role.FACULTY, Role.STUDENT)` decorator and guard.
  - **SWE Principle**: Principle of Least Privilege (PoLP).
  - **Files**: `backend/src/common/decorators/roles.decorator.ts`, `backend/src/common/guards/roles.guard.ts`.
  - **Verification**: Student hitting Super Admin route gets HTTP 403.

- [ ] **Task 2.5: Interactive Swagger / OpenAPI 3.0 Documentation**
  - **Objective**: Auto-generate live API documentation at `/api/docs` with Bearer auth support.
  - **SWE Principle**: Self-documenting API, Contract-First development.
  - **Files**: `backend/src/main.ts` (Swagger bootstrap).
  - **Verification**: Browser displays interactive Swagger UI at `http://localhost:3000/api/docs`.

---

## 🚪 Milestone 3: Universities, Departments, Campuses & Rooms Module

- [ ] **Task 3.1: University & Department Management (Super Admin)**
  - **Objective**: Endpoints to create and manage Universities and Departments.
  - **Files**: `backend/src/modules/universities/`.
  - **Verification**: CRUD operations verified via Swagger.

- [ ] **Task 3.2: Multi-Campus & Building Disambiguation**
  - **Objective**: Add Building and Floor models to rooms (e.g. "Permanent Campus - Building B, 5th Floor").
  - **Files**: `backend/src/modules/rooms/dto/create-room.dto.ts`.
  - **Verification**: Room creation mandates campus and building attribution.

- [ ] **Task 3.3: Room Availability Query Engine (Optimized Index Reads)**
  - **Objective**: Endpoint `GET /api/v1/rooms` with filtering by Department, Status, and Building.
  - **SWE Principle**: Composite B-Tree indexing query optimization.
  - **Files**: `backend/src/modules/rooms/rooms.service.ts`.
  - **Verification**: Benchmark query response time under 10ms.

- [ ] **Task 3.4: "Find Me a Free Room Now" 1-Tap Algorithm**
  - **Objective**: Algorithmic endpoint taking `capacity` and `durationMinutes`, returning top 3 free rooms.
  - **SWE Principle**: Relational filtering with interval overlap exclusion.
  - **Files**: `backend/src/modules/rooms/rooms.controller.ts`.
  - **Verification**: Successfully returns rooms with no overlapping schedule slots.

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

## 📱 Milestone 9: Mobile Clean Architecture (Flutter + Riverpod 2.x)

- [ ] **Task 9.1: Flutter Clean Monorepo Workspace Initialization**
  - **Objective**: Initialize clean Flutter 3.x project in `mobile/` with Material 3 Dark theme.
  - **Files**: `mobile/pubspec.yaml`, `mobile/lib/main.dart`.

- [ ] **Task 9.2: Strict Linting Suite (`analysis_options.yaml`)**
  - **Objective**: Configure Very Good Analysis ruleset enforcing immutable state and clean code.
  - **Files**: `mobile/analysis_options.yaml`.
  - **Verification**: `flutter analyze` passes with 0 warnings.

- [ ] **Task 9.3: Core Network Layer (Dio + Automatic JWT Refresh Interceptor)**
  - **Objective**: Dio client that transparently intercepts HTTP 401s, calls refresh token, and retries original request.
  - **SWE Principle**: Transparent Token Rotation, User Session Persistence.
  - **Files**: `mobile/lib/core/network/api_client.dart`, `mobile/lib/core/network/token_interceptor.dart`.

- [ ] **Task 9.4: Functional Error Handling (`Result<T, Failure>`)**
  - **Objective**: Type-safe error monad eliminating untyped exception throwing in UI.
  - **Files**: `mobile/lib/core/errors/failures.dart`, `mobile/lib/core/utils/result.dart`.

- [ ] **Task 9.5: Declarative Routing with Auth Guards (GoRouter)**
  - **Objective**: GoRouter setup with redirect logic: unauthenticated users redirected to login, pending CRs to waiting screen.
  - **Files**: `mobile/lib/app/router.dart`.

---

## 🎨 Milestone 10: Mobile Reactive Screens & Battery-Friendly WebSockets

- [ ] **Task 10.1: Auth Feature (Login, Registration, University Selector)**
  - **Objective**: Reactive authentication screens with Riverpod `AsyncNotifier`.
  - **Files**: `mobile/lib/features/auth/`.

- [ ] **Task 10.2: Student Dashboard Screen ("My Routine Today" + Room Status)**
  - **Objective**: Dashboard displaying student's daily timetable timeline and live room availability.
  - **Files**: `mobile/lib/features/home/presentation/screens/student_dashboard_screen.dart`.

- [ ] **Task 10.3: Class Representative (CR) Dashboard Screen**
  - **Objective**: CR controls to occupy/release rooms, book make-up classes, and cancel today's slots.
  - **Files**: `mobile/lib/features/home/presentation/screens/cr_dashboard_screen.dart`.

- [ ] **Task 10.4: Faculty / Mentor Dashboard Screen**
  - **Objective**: Consolidated teacher schedule with 1-click cancellation and room shift buttons.
  - **Files**: `mobile/lib/features/home/presentation/screens/faculty_dashboard_screen.dart`.

- [ ] **Task 10.5: Battery-Friendly WebSocket Lifecycle Manager**
  - **Objective**: Bind WebSocket connection to Flutter `AppLifecycleState` (connected in foreground, disconnected in background).
  - **SWE Principle**: Battery conservation, Mobile Operating System Compliance.
  - **Files**: `mobile/lib/core/services/realtime_service.dart`.

- [ ] **Task 10.6: Offline-First Local Cache (Hive / SecureStorage)**
  - **Objective**: Cache last synchronized routine so students can view class schedules without active internet.
  - **Files**: `mobile/lib/core/storage/local_cache.dart`.

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
