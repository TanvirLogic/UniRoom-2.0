# 🎓 UniRoom-Live 2.0: Backend Engineering Masterclass & Milestone Handbooks

Welcome to the **UniRoom-Live 2.0 Backend Learning Repository**. This directory contains exhaustive, line-by-line architectural handbooks partitioned milestone-by-milestone in **both English and Bangla**.

Whether you are studying to master production NestJS backend engineering or preparing to defend your system architecture in your thesis/viva, these handbooks explain every line of code, every database schema decision, every cryptographic security layer, and the complete request lifecycle.

---

## 🗺️ Milestone Handbooks Directory

| Milestone | Status | 🇬🇧 English Handbook | 🇧🇩 বাংলা সংস্করণ | Core Modules & Features Covered |
| :--- | :---: | :--- | :--- | :--- |
| **Milestone 1** | `[x]` Done | [`milestone_one.md`](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_one.md) | [`milestone_one_bangla.md`](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_one_bangla.md) | **Backend Foundation & Cloud Database**: NestJS, TypeScript strict mode, Multi-tenant `schema.prisma` (8 core tables), Neon PostgreSQL with connection pooling, Prisma migrations, idempotent seeding (`seed.ts`), global pipeline (`ValidationPipe`, `TransformInterceptor`, `AllExceptionsFilter`), and health diagnostics. |
| **Milestone 2** | `[x]` Done | [`milestone_two.md`](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_two.md) | [`milestone_two_bangla.md`](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_two_bangla.md) | **Authentication, Security & Metadata Engine**: Bcrypt 10 salt rounds, JWT Dual-Token pattern (15m Access + 7d Refresh rotation), 4-role RBAC (`RolesGuard`, `JwtAuthGuard`, `TenantGuard`), 2-phase Gmail SMTP email verification with SHA-256 PIN hashing & 5-attempt limits, Password recovery, `AcademicBatch` model with native PostgreSQL `text[]` arrays, cascading dropdown options tree, and Routine Auto-Discovery Sync Engine. |
| **Milestone 3** | `[x]` Done | [`milestone_three.md`](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_three.md) | [`milestone_three_bangla.md`](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_three_bangla.md) | **Campus Hierarchy, Rooms & Availability Engine**: Super Admin Universities & Departments CRUD, multi-campus Building disambiguation, indexed Room Inventory with live status statistics, the 1-Tap "Find Me a Free Room Now" algorithm (interval overlap and override merge), and Optimistic Concurrency Control (OCC) with immutable `RoomLog` auditing. |
| **Milestone 4** | `[ ]` Next | `milestone_four.md` | `milestone_four_bangla.md` | **Routine Management & Excel Parser**: Uploading PDF/Excel schedules, automated validation, and slot ingestion. |
| **Milestone 5** | `[ ]` Queued | `milestone_five.md` | `milestone_five_bangla.md` | **Booking Engine & Single-Day Overrides**: Master-Override pattern, CR room reservations, faculty approvals. |
| **Milestone 6** | `[ ]` Queued | `milestone_six.md` | `milestone_six_bangla.md` | **Emergency Announcements & Real-Time Alerts**: Websockets / Server-Sent Events for campus cancellations. |
| **Milestone 7** | `[ ]` Queued | `milestone_seven.md` | `milestone_seven_bangla.md` | **Audit Logging & System Monitoring**: Traceability, activity tracking, Prometheus/Grafana metrics. |

---

## 🧠 Architectural Mental Model: The 7-Layer Request Journey

Every request in UniRoom-Live traverses these 7 layers:

```
[ Client: Flutter Mobile App or Browser ]
                   │
                   ▼ (HTTP Request: Method + URL + Headers + Body)
┌────────────────────────────────────────────────────────────────────────┐
│                        NESTJS BACKEND PIPELINE                         │
├────────────────────────────────────────────────────────────────────────┤
│ 1. CORS & Security (main.ts)                                           │
│ 2. Global Route Prefix (/api/v1)                                       │
│ 3. Global ValidationPipe (class-validator DTO stripping & typing)      │
│ 4. Guards (JwtAuthGuard -> RolesGuard -> TenantGuard)                  │
│ 5. Interceptors: Pre-Controller (Request timing)                       │
│ 6. Controller Layer (HTTP routing, status codes, Swagger)              │
│ 7. Service Layer (Business logic, CSPRNG, Bcrypt, Nodemailer)          │
│ 8. Prisma ORM (Type-safe SQL queries)                                  │
│ 9. Neon PostgreSQL (AWS Cloud Database with connection pooling)        │
│ 10. Interceptors: Post-Controller (TransformInterceptor JSON envelope) │
│ 11. Exception Filters (AllExceptionsFilter uniform error handling)     │
└────────────────────────────────────────────────────────────────────────┘
                   │
                   ▼ (HTTP Response: Status Code + Uniform JSON Envelope)
[ Client Receives: Clean, Type-Safe, Uniform JSON Response ]
```

---

## 🎯 How to Use These Handbooks for Viva & Defense

1. **Before an Interview / Presentation:**
   - Read the **Table of Contents** to review the high-level architecture.
   - Jump to **Section 9: Top 10 Viva & Thesis Defense Q&A** in each milestone handbook.
2. **When Writing Code or Debugging:**
   - Open the **Line-by-Line Breakdown** sections to understand *why* specific decorators, types, and database constraints were selected.
3. **Language Switching:**
   - Every file has a direct switch button at the very top:
     - In English: click `বাংলা সংস্করণ` to view the Bengali explanation.
     - In Bengali: click `English Version` to view the English handbook.

---
*UniRoom-Live 2.0 — Engineered for Excellence.*
