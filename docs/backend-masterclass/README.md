# 🎓 UniRoom-Live 2.0 Backend Engineering Masterclass
### *From Basic Programming to Enterprise Backend Mastery*

Welcome to the official, complete backend engineering course for **UniRoom-Live 2.0**.
This documentation was built to explain every single file, line of code, architecture decision, and database concept in the simplest, most intuitive way possible.

---

## 📚 Curriculum & Chapters

| Chapter | Title | Core Topics Covered |
| :---: | :--- | :--- |
| [**Chapter 1**](./01_ARCHITECTURE_AND_BOOTSTRAP.md) | **Architecture, Request Lifecycle & Bootstrap** | The Restaurant Analogy, NestJS Lifecycle, `package.json`, `main.ts`, `app.module.ts`, `prisma.service.ts` |
| [**Chapter 2**](./02_DATABASE_AND_PRISMA_SCHEMA.md) | **Database & Prisma Schema Line-by-Line** | PostgreSQL 16, Neon.tech, Prisma ORM, ERD Diagrams, All Models, Relations, Cascades, Indexes, Constraints |
| [**Chapter 3**](./03_SECURITY_GUARDS_INTERCEPTORS.md) | **Security, Guards, Roles & Interceptors** | JWT Boarding Pass Analogy, Passport Strategy, Role-Based Access Control (`@Roles()`), Multi-Tenancy Guard, Exception Filter, Response Interceptor |
| [**Chapter 4**](./04_AUTH_MODULE_DEEP_DIVE.md) | **Authentication Module Deep Dive** | DTO Validation, `auth.controller.ts`, `auth.service.ts`, Bcrypt Password Hashing, Cryptographic CSPRNG PINs, Dual Token Issuing & Rotation, Incomplete Registration Recovery |
| [**Chapter 5**](./05_ROOMS_AND_OCC_BOOKING_ENGINE.md) | **Rooms & Concurrency Control (OCC)** | The Double-Booking Race Condition, Pessimistic vs Optimistic Locking, The `version` Field, Atomic `$transaction`, Query Aggregation with `GROUP BY`, CR Extra Class Bookings |
| [**Chapter 6**](./06_SCHEDULES_ROUTINES_AND_OVERRIDES.md) | **Schedules, Routines & Emergency Overrides** | Interval Collision Mathematics (`start1 < end2 && end1 > start2`), Routine Ingestion, Joint/Combined Lectures, Daily Overrides (`cancelTodaySlot`, `rescheduleTodaySlot`, `undoTodayOverride`) |
| [**Chapter 7**](./07_EMAIL_NOTIFICATIONS_AND_META.md) | **Email, Push Notifications & Metadata** | SMTP TLS Delivery (`nodemailer`), Local Dev Fallback, Firebase Cloud Messaging (FCM Topics), Android High-Priority Heads-Up Alerts, Cascading Dropdown Feeds |
| [**Chapter 8**](./08_CLASSROOM_HUB_AND_ACADEMIC_FEEDS.md) | **Virtual Classroom Hub & Cross-Cohort Fan-Out** | Virtual Classroom Space, Notice Boards, Lecture Note Archives, Dynamic Cross-Cohort Fan-Out Broadcast Algorithm, Role-Based Publishing Rules |

---

## 🚀 Quick Navigation Links
- [Read Chapter 1: Architecture & Bootstrap](./01_ARCHITECTURE_AND_BOOTSTRAP.md)
- [Read Chapter 2: Database & Prisma Schema](./02_DATABASE_AND_PRISMA_SCHEMA.md)
- [Read Chapter 3: Security & Guards](./03_SECURITY_GUARDS_INTERCEPTORS.md)
- [Read Chapter 4: Authentication Engine](./04_AUTH_MODULE_DEEP_DIVE.md)
- [Read Chapter 5: Rooms & Concurrency Control](./05_ROOMS_AND_OCC_BOOKING_ENGINE.md)
- [Read Chapter 6: Schedules & Overrides](./06_SCHEDULES_ROUTINES_AND_OVERRIDES.md)
- [Read Chapter 7: Email, FCM & Metadata](./07_EMAIL_NOTIFICATIONS_AND_META.md)
- [Read Chapter 8: Virtual Classroom Hub & Dynamic Fan-Out](./08_CLASSROOM_HUB_AND_ACADEMIC_FEEDS.md)
