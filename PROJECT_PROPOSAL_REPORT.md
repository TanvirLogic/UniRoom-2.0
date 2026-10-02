# PROJECT PROPOSAL REPORT

---

**PROJECT TITLE:**  
# UniRoom-Live: A Multi-Tenant Real-Time Classroom Orchestration and Dynamic Academic Schedule Synchronization Platform

**Subtitle:**  
*Eliminating Campus Timetable Disruption and Room Allocation Collisions Through Concurrency-Controlled Resource Orchestration, Instant Push Synchronization, and Responsive Mobile Workflows*

---

| **Attribute** | **Description / Metadata** |
| :--- | :--- |
| **Institution** | Uttara University |
| **Faculty** | School of Science and Engineering |
| **Department** | Department of Computer Science & Engineering (CSE) |
| **Course** | Capstone Design Project / Project & Thesis (CSE 4XX) |
| **Project Domain** | Distributed Systems, Cloud Computing & Cross-Platform Mobile Engineering |
| **Target Platforms** | Android, iOS, Progressive Web App (PWA), Desktop Web |
| **Target Stakeholders**| Students, Class Representatives (CRs), Faculty Members, Department Coordinators, Campus Administrators |
| **Document Format** | Academic Project Proposal Report |
| **Version** | 2.0 (Production-Ready Architecture) |

---

## TABLE OF CONTENTS

- [Project Title](#uniroom-live-a-multi-tenant-real-time-classroom-orchestration-and-dynamic-academic-schedule-synchronization-platform)
- [1. Introduction](#1-introduction)
  - [1.1 Background and Context](#11-background-and-context)
  - [1.2 System Overview](#12-system-overview)
  - [1.3 Target Stakeholders and Operational Roles](#13-target-stakeholders-and-operational-roles)
- [2. Problem Statement](#2-problem-statement)
  - [2.1 Fragmented Communication and Schedule Desynchronization](#21-fragmented-communication-and-schedule-desynchronization)
  - [2.2 Physical Classroom Collisions and Double-Booking](#22-physical-classroom-collisions-and-double-booking)
  - [2.3 Resource Inefficiency and "Ghost Occupancy"](#23-resource-inefficiency-and-ghost-occupancy)
  - [2.4 Administrative Burden on Class Representatives (CRs)](#24-administrative-burden-on-class-representatives-crs)
  - [2.5 Absence of Real-Time Concurrency Control and Auditability](#25-absence-of-real-time-concurrency-control-and-auditability)
- [3. Objectives](#3-objectives)
  - [3.1 Primary Objective](#31-primary-objective)
  - [3.2 Specific Technical and Research Objectives](#32-specific-technical-and-research-objectives)
- [4. Project Scope](#4-project-scope)
  - [4.1 In-Scope Deliverables and Core Modules](#41-in-scope-deliverables-and-core-modules)
  - [4.2 Out-of-Scope and Future Boundaries](#42-out-of-scope-and-future-boundaries)
- [5. Methodology](#5-methodology)
  - [5.1 Software Development Life Cycle (SDLC) - Agile/Scrum](#51-software-development-life-cycle-sdlc---agilescrum)
  - [5.2 Requirement Engineering and System Specifications](#52-requirement-engineering-and-system-specifications)
  - [5.3 System Architecture and High-Level Design](#53-system-architecture-and-high-level-design)
  - [5.4 Database Design and Concurrency Control Strategy](#54-database-design-and-concurrency-control-strategy)
  - [5.5 Implementation Phases and Sprint Breakdown](#55-implementation-phases-and-sprint-breakdown)
  - [5.6 Technology Stack and Tooling](#56-technology-stack-and-tooling)
  - [5.7 Testing, Verification, and Quality Assurance](#57-testing-verification-and-quality-assurance)
  - [5.8 Work Breakdown Structure and Project Timeline](#58-work-breakdown-structure-and-project-timeline)
- [6. Conclusion](#6-conclusion)
  - [6.1 Anticipated Contributions and Impact](#61-anticipated-contributions-and-impact)
  - [6.2 Future Research and Development Scope](#62-future-research-and-development-scope)
- [7. References](#7-references)

---

## 1. INTRODUCTION

### 1.1 Background and Context
Higher education institutions operate in intricate, fast-moving environments characterized by multi-shift academic programs, shared specialized laboratories, large student enrollments, and hundreds of lecture halls distributed across distinct physical campus buildings. At institutions like Uttara University, academic schedules are not static; they fluctuate continuously throughout each semester due to:
- Make-up and remedial lectures scheduled by instructors to complete syllabus milestones.
- Unplanned faculty rescheduling arising from institutional meetings or personal emergencies.
- Specialized laboratory migrations where classes require high-performance computing or engineering facilities.
- Ad-hoc student presentations, project defenses, and student club workshops that require vacant rooms outside standard hours.

Historically, academic institutions communicated these changes using static paper notices, physical bulletin boards, and periodically published PDF routine sheets. In recent years, communication transitioned toward informal messaging platforms, including WhatsApp, Telegram, and Facebook Messenger groups. While fast, this informal model introduces critical communication bottlenecks, fragmented information silos, and administrative disorder.

### 1.2 System Overview
**UniRoom-Live** is conceived, designed, and engineered as an enterprise-grade, centralized, and authoritative real-time operational hub for campus schedules and classroom assets. The platform replaces informal chat groups and static PDF documents with an active, event-driven digital ecosystem.

The system is constructed upon a decoupled, three-tier architecture:
1. **Presentation Tier (Flutter Cross-Platform Application):** A fluid, high-performance client application delivering tailored interfaces for Students, Class Representatives, Faculty, and Administrators. It features a responsive layout system operational across all display form factors down to 360px viewport widths, client-side caching, and offline-first routine inspection.
2. **Application / Orchestration Tier (NestJS Enterprise REST API):** A modular TypeScript micro-framework orchestrating authentication, multi-tenancy isolation, timetable conflict pre-flight checks, and notification pipelines.
3. **Data and Event Tier (PostgreSQL + Prisma ORM + FCM):** An ACID-compliant relational persistence store executing transactional locks, version-controlled records, and event dispatch pipelines via Firebase Cloud Messaging (FCM) and SMTP email relays.

### 1.3 Target Stakeholders and Operational Roles
UniRoom-Live organizes university workflows into five distinct Role-Based Access Control (RBAC) tiers:
- **Superadmin / Institutional Executive:** Configures global institutional boundaries, manages multi-campus facilities, and monitors macro-level operational metrics.
- **Department Admin / Program Coordinator:** Establishes master semester schedules, assigns batches and instructors, resolves cross-departmental room collisions, and audits facility usage logs.
- **Faculty Member:** Reviews real-time daily teaching agendas, requests vacant classrooms for extra sessions, releases reserved rooms early when lectures conclude ahead of time, and receives instant attendance rolls.
- **Class Representative (CR):** Serves as the primary operational liaison for student cohorts; reserves on-demand rooms for batch sessions, logs daily student attendance using a rapid-entry absent keypad, and formats automatic SMS reports to instructors.
- **Student:** Accesses real-time, filtered daily routines, checks live room availability across campus buildings, and receives instant push notifications when classes are rescheduled, relocated, or cancelled.

```
+-----------------------------------------------------------------------------------+
|                                  UniRoom-Live                                     |
|                       Multi-Tenant Role-Based Hierarchy                           |
+-----------------------------------------------------------------------------------+
|  [Superadmin]          -> Global Institutional Setup & Tenant Management          |
|      v                                                                            |
|  [Department Admin]    -> Master Timetables, Routine Publishing, Conflict Audit   |
|      v                                                                            |
|  [Faculty Member]      -> Dynamic Rescheduling, Early Room Release                |
|      v                                                                            |
|  [Class Rep (CR)]      -> On-Demand Room Booking, Rapid Attendance Logging & SMS  |
|      v                                                                            |
|  [Student]             -> Real-Time Timetable Sync, Live Room Vacancy Tracking     |
+-----------------------------------------------------------------------------------+
```

---

## 2. PROBLEM STATEMENT

Despite substantial investments in university infrastructure, modern campuses suffer from operational friction caused by manual scheduling practices and decentralized communication tools. The critical problems addressed by this project include:

### 2.1 Fragmented Communication and Schedule Desynchronization
When an instructor shifts a lecture from 8:30 AM to 11:30 AM or relocates from Room 402 to Lab 605, updates are typically transmitted via informal phone calls to the Class Representative, who then posts a text update in a social media chat group. This approach repeatedly breaks down:
- Students with muted notifications or poor internet access miss announcements and travel to campus unnecessarily.
- Critical schedule updates become lost under dozens of informal student chat messages.
- There is no single authoritative source of truth, causing students to rely on obsolete PDF files or unverified rumors.

### 2.2 Physical Classroom Collisions and Double-Booking
When multiple instructors or batch representatives attempt to organize extra lectures, review sessions, or makeup labs, they often identify a seemingly empty room on a static timetable and occupy it without centralized coordination. Consequently:
- Two different student batches (e.g., Batch 58 and Batch 61) arrive at the exact same laboratory or classroom simultaneously, leading to academic disruption, embarrassment, and lost instructional time.
- Academic coordinators have zero real-time visibility into which rooms are genuinely occupied across campus at any specific hour.

### 2.3 Resource Inefficiency and "Ghost Occupancy"
Standard campus routine models allocate rooms in rigid blocks (e.g., 90 or 120 minutes). If a lecture concludes 30 minutes early, or if an instructor cancels a class due to illness or departmental duties, the room remains officially designated as "Occupied" on paper. Consequently:
- Classrooms remain locked and empty ("Ghost Occupancy") while other student groups search fruitlessly for available study or presentation venues.
- Campus facility utilization remains artificially depressed despite perceived room shortages.

### 2.4 Administrative Burden on Class Representatives (CRs)
Class Representatives perform repetitive clerical duties that disrupt their academic focus:
- Conducting manual roll calls on scrap sheets of paper during short class breaks.
- Manually transcribing lists of absent student ID numbers.
- Typing long lists of 10-digit student ID numbers into their smartphones to send via SMS to instructors.
- This manual process introduces transcription errors, consumes instructional time, and delays attendance submission.

### 2.5 Absence of Real-Time Concurrency Control and Auditability
Prior academic management applications lack robust database concurrency controls. When two users submit a reservation request for the same vacant lecture hall within milliseconds of each other, standard database queries create duplicate records (race conditions). Furthermore, paper and group-chat methods lack immutable audit trails to verify who authorized schedule overrides or abandoned assigned rooms.

---

## 3. OBJECTIVES

*(Note: In strict compliance with academic proposal requirements, every objective item begins with the word **"To"**.)*

### 3.1 Primary Objective
- **To** design and implement a multi-tenant, cloud-synchronized real-time classroom orchestration and dynamic academic schedule management platform that unifies students, faculty members, and campus administrators under a single authoritative, high-availability digital ecosystem.

### 3.2 Specific Technical and Research Objectives
- **To** develop an Optimistic Concurrency Control (OCC) and atomic transactional booking engine within a relational PostgreSQL database to eliminate race conditions, preventing double-booking of physical classrooms during high-traffic scheduling windows.
- **To** formulate an intelligent pre-flight conflict detection algorithm that cross-evaluates proposed timetable modifications against physical room capacities, faculty availability, and student cohort schedules prior to database persistence.
- **To** engineer an automated push notification and event distribution pipeline leveraging Firebase Cloud Messaging (FCM) and SMTP services to instantly broadcast schedule alterations, cancellations, and room reallocations to all affected stakeholders.
- **To** implement a dynamic room release and early-checkout mechanism that liberates unoccupied physical spaces back into the public vacancy pool, systematically eliminating "ghost occupancy" and maximizing campus facility utilization.
- **To** build a streamlined Class Representative (CR) attendance utility featuring a rapid-entry absent keypad and an automated SMS generation engine to eliminate manual transcription errors and accelerate faculty roll reporting.
- **To** establish a secure, multi-tenant Role-Based Access Control (RBAC) security architecture powered by JSON Web Tokens (JWT) and cryptographic hashing to enforce strict operational boundaries across five user privilege tiers.
- **To** create a high-performance, cross-platform mobile client in Flutter that delivers an adaptive, fluid user experience across diverse screen dimensions (specifically optimized down to 360px viewport widths) with client-side caching for offline routine consultation.
- **To** evaluate the operational efficiency, latency, and system reliability through rigorous integration testing, simulated concurrent load scenarios, and real-world stakeholder usability trials at Uttara University.

---

## 4. PROJECT SCOPE

### 4.1 In-Scope Deliverables and Core Modules
The development and implementation scope of UniRoom-Live encompasses the following core functional domains:

1. **Multi-Tenant Physical and Academic Hierarchy:**
   - Full modeling and administrative management of Institutions, Campuses, Buildings, Rooms, Departments, Degree Programs, and Student Batches/Sections.
   - Granular room metadata including capacity, room type (Lecture, Lab, Seminar, Auditorium), and floor indexing.

2. **Master Timetable & Dynamic Routine Synchronization:**
   - Digital routine authoring and management supporting multi-parameter filtering (by Day, Department, Semester, Batch, and Faculty).
   - Real-time routine synchronization with offline local caching for students and instructors.

3. **Pre-Flight Conflict Inspection Matrix:**
   - Automated triple-factor validation checking:
     1. Room Collision (Room occupied by another batch during the requested interval).
     2. Faculty Collision (Instructor assigned to another lecture simultaneously).
     3. Batch Collision (Student cohort scheduled for another course concurrently).

4. **Real-Time Room Discovery and Concurrency-Controlled Booking:**
   - Live campus room vacancy scanner displaying current and upcoming availability.
   - On-demand room reservation engine with atomic transaction locking preventing race conditions.
   - Early room release / checkout workflow returning rooms immediately to the available pool.

5. **Class Representative (CR) Attendance & Telephony Integration:**
   - Rapid-entry absent roll keypad tailored for fast batch processing.
   - Automatic absent roll aggregation and attendance percentage calculations.
   - Native device telephony integration generating pre-formatted SMS drafts with instructor phone numbers and absent roll strings.

6. **Enterprise Authentication & RBAC Security:**
   - Secure login using email and institutional student/employee IDs.
   - Cryptographic password protection using Bcrypt hashing with automated salting.
   - Stateless JWT authorization with role guards enforcing boundaries across 5 user privilege levels.

7. **Multi-Channel Notification Infrastructure:**
   - Instant push notifications via Firebase Cloud Messaging (FCM) to mobile devices.
   - Transactional email dispatch via Nodemailer/SMTP for account provisioning and critical announcements.

8. **Ultra-Responsive Cross-Platform Client:**
   - Native compilation to Android, iOS, and Web from a single Dart codebase.
   - Responsive layouts optimized for ultra-compact 360px width smartphones up to high-resolution desktop displays.

### 4.2 Out-of-Scope and Future Boundaries
To ensure timely delivery, architectural focus, and budget feasibility within the academic timeline, the following elements are designated as out-of-scope for the initial release:
- **Physical Hardware Door Automation:** Automated electronic door solenoids or RFID turnstiles (reserved for Version 3.0 IoT integration).
- **Biometric Hardware Terminals:** Dedicated fingerprint scanners or infrared facial recognition terminals.
- **Commercial Payment Gateways:** Monetary transactions or fee payment processing for room rentals.
- **Automated AI Timetable Synthesis:** Algorithmic routine generation using genetic algorithms (the system provides master routine management and pre-flight conflict detection; automated synthesis is earmarked for future research).

---

## 5. METHODOLOGY

The development and deployment of **UniRoom-Live** follows an engineering-driven, iterative methodology to ensure system reliability, architectural cleanliness, robust security, and seamless user adoption.

```
+-----------------------------------------------------------------------------------------+
|                               AGILE / SCRUM METHODOLOGY                                 |
+-----------------------------------------------------------------------------------------+
| [ Sprint 1 ] Requirement Gathering, Stakeholder Interviews & Domain Relational Modeling |
| [ Sprint 2 ] Multi-Tenant Core, RBAC Security Layer & JWT Authentication Infrastructure |
| [ Sprint 3 ] Routine Engine & Pre-Flight Conflict Detection Matrix                      |
| [ Sprint 4 ] Real-Time Room Booking with Optimistic Concurrency Control (OCC)           |
| [ Sprint 5 ] CR Attendance Automation, Rapid Absent Keypad & SMS Telephony Engine       |
| [ Sprint 6 ] Flutter Responsive Mobile Client, 360px Optimization & Offline Caching     |
| [ Sprint 7 ] Firebase Cloud Messaging (FCM), SMTP Dispatch & Event-Driven Alerts        |
| [ Sprint 8 ] System Integration, Concurrency Stress Testing, Verification & UAT         |
+-----------------------------------------------------------------------------------------+
```

### 5.1 Software Development Life Cycle (SDLC) - Agile/Scrum
The project employs the **Agile / Scrum framework**, structured into eight 2-week sprints over a 16-week timeline. Agile was chosen over rigid Waterfall processes because university scheduling workflows require frequent stakeholder demonstrations and incremental adjustments based on real student and faculty feedback.

Each sprint follows a structured cadence:
- **Sprint Planning:** Defining user stories and prioritizing critical backlog items.
- **Daily Scrums:** Tracking progress, identifying technical blockers, and verifying architectural consistency.
- **Sprint Review & Demonstrations:** Presenting functional increments to university CRs, faculty, and project advisors.
- **Retrospective:** Evaluating sprint velocity, refactoring technical debt, and fine-tuning UI responsiveness.

### 5.2 Requirement Engineering and System Specifications

#### 5.2.1 Functional Requirements (FRs)
- **FR-1:** The system shall model multi-tenant hierarchies down to individual rooms and student batches.
- **FR-2:** The system shall authenticate users with role-based access control across 5 privilege levels.
- **FR-3:** The system shall retrieve, filter, and display master routines by department, semester, and batch.
- **FR-4:** The backend shall reject any routine addition or edit that causes room, faculty, or batch schedule collisions.
- **FR-5:** The system shall allow authorized users (CRs/Faculty) to reserve vacant rooms using atomic transactions.
- **FR-6:** The system shall allow occupants to release booked rooms early, immediately updating vacancy status.
- **FR-7:** The mobile client shall provide a rapid numerical keypad for CRs to record absent roll numbers and launch pre-filled SMS messages to instructors.
- **FR-8:** The system shall dispatch background push notifications via FCM whenever lecture schedules are updated or cancelled.

#### 5.2.2 Non-Functional Requirements (NFRs)
- **NFR-1 (Concurrency & Integrity):** Zero room double-bookings under concurrent access; guaranteed ACID compliance for reservations.
- **NFR-2 (Latency):** Routine queries and vacancy lookups shall respond in $\le 150 \text{ ms}$ under normal network conditions.
- **NFR-3 (Responsiveness):** Mobile user interfaces shall render with zero visual clipping or layout overflow errors across screen widths from 360px to 4K displays.
- **NFR-4 (Offline Capability):** The mobile application shall cache timetable data locally, enabling routine inspection without an active network connection.
- **NFR-5 (Security):** Passwords shall be salted and hashed with Bcrypt; all API communications shall be encrypted using TLS/HTTPS; endpoints shall be secured via signed JWT tokens.

---

### 5.3 System Architecture and High-Level Design

UniRoom-Live adopts a decoupled **Three-Tier Architecture** that enforces separation of concerns, high scalability, and robust maintainability:

```
+-----------------------------------------------------------------------------------+
|                            PRESENTATION TIER (CLIENT)                             |
|                                                                                   |
|   +-----------------------+                     +-----------------------------+   |
|   |  Flutter Mobile App   |                     |     Admin Web Dashboard     |   |
|   |  (Android / iOS / PWA)|                     |      (React / Vite SPA)     |   |
|   +-----------------------+                     +-----------------------------+   |
|               |                                                |                  |
|               +-----------------------+------------------------+                  |
+---------------------------------------|-------------------------------------------+
                                        | HTTPS / REST / JSON
                                        v
+-----------------------------------------------------------------------------------+
|                        APPLICATION / LOGIC TIER (API)                             |
|                                                                                   |
|   +---------------------------------------------------------------------------+   |
|   |                    NestJS Modular Enterprise Framework                    |   |
|   |                                                                           |   |
|   |   [Auth Module]       -> JWT Guards, Passport, Bcrypt Hashing             |   |
|   |   [Users Module]      -> Profile Management & RBAC Role Enforcement       |   |
|   |   [Routine Module]    -> Timetable Pre-Flight Conflict Validator          |   |
|   |   [Rooms Module]      -> Live Vacancy Detection & OCC Booking Engine      |   |
|   |   [Attendance Module] -> Absent Roll Aggregator & SMS Dispatcher          |   |
|   |   [Notif Module]      -> FCM Push Dispatch & Nodemailer SMTP Gateway      |   |
|   +---------------------------------------------------------------------------+   |
+-----------------------------------------------------------------------------------+
                                        | Prisma ORM (Type-Safe Client)
                                        v
+-----------------------------------------------------------------------------------+
|                             DATA & MESSAGING TIER                                 |
|                                                                                   |
|   +-------------------------+                      +--------------------------+   |
|   |  PostgreSQL Datastore   |                      |  External Cloud Services |   |
|   |  (Neon Cloud Serverless)|                      |                          |   |
|   |  - ACID Transactions    |                      |  - Firebase Cloud Push   |   |
|   |  - OCC Locking Locks    |                      |  - Nodemailer SMTP Relay |   |
|   |  - Relational Schema    |                      |  - Cellular SMS Gateway  |   |
|   +-------------------------+                      +--------------------------+   |
+-----------------------------------------------------------------------------------+
```

#### Layer Responsibilities:
1. **Presentation Tier:** Built using **Flutter (Dart)**. Employs the **Provider** pattern for reactive state management, responsive builders (`LayoutBuilder`, flexible spacers, scalable font metrics), and local storage caching.
2. **Application Tier:** Built using **NestJS (TypeScript)**. Uses Dependency Injection (DI), modular architectural boundaries, declarative validation pipes (`class-validator`), and Guard-based authorization (`JwtAuthGuard`, `RolesGuard`).
3. **Data Tier:** Powered by **PostgreSQL** hosted on Neon cloud serverless infrastructure. Interfaced through **Prisma ORM**, ensuring compile-time type safety, zero SQL injection vulnerabilities, and declarative database migrations.

---

### 5.4 Database Design and Concurrency Control Strategy

#### 5.4.1 Relational Data Model (Normalized Entity Architecture)
The persistence layer comprises ten interconnected domain entities structured to enforce institutional multi-tenancy:
1. **Institutions:** Top-level tenant container (e.g., Uttara University).
2. **Campuses:** Physical campus installations belonging to an institution (e.g., Main Campus).
3. **Buildings:** Physical structural towers located within a campus.
4. **Rooms:** Physical rooms with floor numbering, capacity limits, and categorization (Lecture, Laboratory, Seminar, Auditorium).
5. **Departments:** Academic units (e.g., CSE, EEE, BBA).
6. **Batches / Sections:** Specific student cohorts belonging to a department (e.g., Batch 58 - Section A).
7. **Users:** Account records tied to roles (SUPERADMIN, ADMIN, FACULTY, CR, STUDENT) and associated with specific department/batch nodes.
8. **Routines:** Master schedule entries defining recurring weekly slots with `day_of_week`, `start_time`, `end_time`, `course_code`, `course_name`, `faculty_id`, `room_id`, and `batch_id`.
9. **Bookings:** On-demand dynamic room allocations with start/end timestamps, approval status, purpose, and room release flags.
10. **AttendanceLogs:** Records created by CRs capturing class dates, course IDs, attendee headcounts, and serialized absent roll arrays.

#### 5.4.2 Optimistic Concurrency Control (OCC) and Overlap Detection Formula
To guarantee that two users cannot simultaneously reserve the same room for overlapping time slots, UniRoom-Live employs **Optimistic Concurrency Control (OCC)** coupled with atomic database transactions.

When a room reservation request arrives for time interval $[T_{\text{start}}, T_{\text{end}}]$ on date $D$ for room $R$, the backend executes an atomic database transaction:

$$\text{Overlap Condition} \iff (t_{\text{start}}^{\text{existing}} < T_{\text{end}}) \land (t_{\text{end}}^{\text{existing}} > T_{\text{start}})$$

```typescript
// Architectural Implementation of Concurrency-Controlled Reservation
await this.prisma.$transaction(async (tx) => {
  // 1. Inspect existing bookings with Row-Level Verification
  const collision = await tx.booking.findFirst({
    where: {
      roomId: requestedRoomId,
      date: requestedDate,
      status: 'APPROVED',
      isReleased: false,
      AND: [
        { startTime: { lt: requestedEndTime } },
        { endTime: { gt: requestedStartTime } },
      ],
    },
  });

  if (collision) {
    throw new ConflictException('Room has already been reserved for this timeslot by another user.');
  }

  // 2. Persist booking atomically
  return tx.booking.create({
    data: { ...bookingPayload, status: 'APPROVED' },
  });
});
```

If a collision is detected, the transaction rolls back immediately and returns an HTTP 409 Conflict status code, safeguarding database integrity against race conditions.

---

### 5.5 Implementation Phases and Sprint Breakdown

| **Phase / Sprint** | **Duration** | **Primary Deliverables** | **Milestone Outcome** |
| :--- | :--- | :--- | :--- |
| **Sprint 1: Domain Modeling & Planning** | Weeks 1–2 | System requirements specification, ER diagram, Prisma schema design, Git repository initialization. | Data model solidified; database migrations configured. |
| **Sprint 2: Authentication & RBAC** | Weeks 3–4 | NestJS Auth module, Bcrypt password hashing, JWT strategy, User profile controllers, Role guards. | Secure authentication active across all 5 user tiers. |
| **Sprint 3: Routine Engine & Conflict Pre-Flight** | Weeks 5–6 | CRUD timetable endpoints, multi-parameter schedule filtering, triple-conflict detection validator. | Zero-conflict schedule creation verified. |
| **Sprint 4: Dynamic Room Booking & OCC** | Weeks 7–8 | Vacancy search algorithm, atomic room reservation transaction, early-release checkout engine. | Concurrency-safe room booking validated under load. |
| **Sprint 5: CR Attendance & SMS Engine** | Weeks 9–10 | Rapid absent keypad in Flutter, statistical summary widget, device telephony URL-launcher SMS integration. | CR attendance recording tested on mobile devices. |
| **Sprint 6: Responsive UI & 360px Tuning** | Weeks 11–12 | Flutter layout refactoring, elimination of pixel overflows, adaptive dialogs, bottom sheets, offline caching. | Flawless mobile rendering on 360px–412px viewports. |
| **Sprint 7: Real-Time Notifications** | Weeks 13–14 | Firebase Cloud Messaging integration, device token registration, Nodemailer SMTP service, broadcast triggers. | Push notifications delivered on schedule alterations. |
| **Sprint 8: QA, Load Testing & Deployment** | Weeks 15–16 | Concurrency stress testing, Jest integration test suites, production build deployment, UAT at Uttara University. | Project proposal defense, documentation, and live rollout. |

---

### 5.6 Technology Stack and Tooling

| **Layer / Component** | **Technology Selected** | **Version** | **Engineering Justification** |
| :--- | :--- | :--- | :--- |
| **Mobile Frontend** | **Flutter (Dart)** | SDK 3.x+ / Dart 3.x | Single codebase compiling natively to Android, iOS, and Web; 60fps fluid UI performance; granular responsive layout controls. |
| **State Management** | **Provider** | ^6.1.0 | Lightweight, reactive, predictable state tree without excessive boilerplate; easy to maintain. |
| **Backend Framework** | **NestJS (TypeScript)** | ^10.x | Enterprise-grade architectural conventions, modular architecture, robust dependency injection, native TypeScript type safety. |
| **Object-Relational Mapping** | **Prisma ORM** | ^5.x | Declarative data modeling, automated type generation, migration tracking, and protection against SQL injection. |
| **Database Management** | **PostgreSQL** | v16 (Neon Cloud) | ACID-compliant relational engine offering row-level transaction isolation, indexing, and high availability. |
| **Authentication & Crypto** | **JWT & Bcrypt** | Passport-JWT / Bcrypt.js | Stateless, horizontally scalable token authentication with cryptographic password hashing. |
| **Push Notification Service** | **Firebase Cloud Messaging** | Firebase Admin SDK | Reliable, battery-optimized background push notifications across Android, iOS, and Web platforms. |
| **Telephony / SMS Gateway** | **url_launcher (Telephony URI)** | Native Mobile Intent | Direct hardware-level cellular SMS generation without requiring expensive third-party SMS aggregator API credits. |
| **Deployment & Hosting** | **Render / Docker / Neon** | Cloud Native | Containerized backend deployment with automated CI/CD pipeline linked to GitHub repository. |

---

### 5.7 Testing, Verification, and Quality Assurance
To validate the reliability, performance, and user experience of UniRoom-Live, four layers of quality assurance are conducted:

1. **Unit and Integration Testing:** Automated backend test suites written in **Jest** covering authentication services, routine retrieval filters, and conflict calculation algorithms.
2. **Concurrency & Race Condition Verification:** Automated concurrent script execution simulating multiple simultaneous room reservation requests to ensure the Optimistic Concurrency Control (OCC) mechanism permits exactly one booking while rejecting competing requests with HTTP 409.
3. **Cross-Device Responsive Verification:** UI testing across physical smartphones and emulators representing multiple aspect ratios and display densities:
   - Small Screens: 360px × 640px (e.g., entry-level smartphones).
   - Standard Screens: 390px × 844px and 412px × 915px (e.g., modern flagship devices).
   - Tablets & Desktops: 768px to 1080p displays.
4. **User Acceptance Testing (UAT):** Real-world scenario testing with sample groups comprising Uttara University students, Class Representatives, and faculty members to evaluate task completion times (e.g., booking a room in under 10 seconds; taking attendance in under 30 seconds).

---

### 5.8 Work Breakdown Structure and Project Timeline

```
Task / Milestone                   Month 1       Month 2       Month 3       Month 4
-------------------------------------------------------------------------------------
1. Requirements & System Design    [====]
2. Auth & Multi-Tenant Core              [====]
3. Routine Engine & Conflict Logic             [====]
4. Room Booking Engine & OCC                         [====]
5. CR Attendance & SMS System                              [====]
6. Flutter Responsive UI (360px)                                 [====]
7. Push Notifications (FCM/Email)                                      [====]
8. QA, Load Testing & Deployment                                             [====]
-------------------------------------------------------------------------------------
```

---

## 6. CONCLUSION

### 6.1 Anticipated Contributions and Impact
The development and deployment of **UniRoom-Live** directly resolves acute operational bottlenecks that degrade daily campus life in modern universities. By transitioning institutional schedules from chaotic, informal messaging groups and static PDF notices into a dynamic, cloud-synchronized operational platform, the project achieves:

1. **Elimination of Schedule Confusion:** Students and faculty receive instantaneous, authoritative alerts regarding timetable changes, eliminating missed lectures and unnecessary travel.
2. **Guaranteed Spatial Harmony:** The concurrency-controlled booking engine prevents double-booking and room clashes, ensuring smooth operation for makeup lectures and academic events.
3. **Maximized Campus Resource Efficiency:** The on-demand reservation and early-release mechanisms unlock physical capacity, eliminating "ghost occupancy" and allowing optimal use of classrooms and laboratories.
4. **Radical Reduction in Administrative Friction:** Class Representatives save valuable classroom time using the rapid keypad attendance logger and automatic SMS formatting engine.
5. **Universal Accessibility:** The responsive Flutter mobile application ensures that every student, regardless of device screen size or price tier (down to 360px viewport widths), enjoys an equitable, smooth digital experience.

### 6.2 Future Research and Development Scope
Following successful deployment and institutional adoption at Uttara University, the UniRoom-Live platform is architected to support future evolutionary expansions:
- **IoT Smart Door Hardware Integration:** Interfacing room reservation states with microcontroller-driven smart locks (ESP32/RFID) to unlock doors automatically when a verified booking commences.
- **Biometric and QR-Code Attendance Verification:** Expanding the attendance module to include rotating cryptographic QR codes displayed on classroom screens for instant student self-verification.
- **Artificial Intelligence-Powered Routine Optimization:** Integrating constraint satisfaction algorithms (genetic algorithms / linear programming) to auto-generate conflict-free master semester timetables based on faculty availability, batch sizes, and physical room capacity.
- **Institutional ERP & Learning Management System (LMS) Integration:** Establishing bidirectional data pipelines with platforms such as Moodle, Canvas, and university registrar databases.

In summary, **UniRoom-Live** demonstrates rigorous software engineering principles, robust distributed system design, and practical academic merit, establishing a scalable, production-ready foundation for modern smart campus operations.

---

## 7. REFERENCES

1. **Sommerville, I. (2015).** *Software Engineering* (10th ed.). Pearson Education.
2. **Fowler, M. (2002).** *Patterns of Enterprise Application Architecture*. Addison-Wesley Professional.
3. **Elmasri, R., & Navathe, S. B. (2016).** *Fundamentals of Database Systems* (7th ed.). Pearson.
4. **Fielding, R. T. (2000).** *Architectural Styles and the Design of Network-based Software Architectures* (Doctoral dissertation). University of California, Irvine.
5. **NestJS Documentation Team. (2024).** *NestJS: A progressive Node.js framework for building efficient, reliable and scalable server-side applications*. Available at: https://docs.nestjs.com
6. **Flutter Documentation Team. (2024).** *Flutter: Build apps for any screen*. Google LLC. Available at: https://docs.flutter.dev
7. **Prisma Team. (2024).** *Prisma: Next-generation ORM for Node.js and TypeScript*. Available at: https://www.prisma.io/docs
8. **Bernstein, P. A., & Newcomer, E. (2009).** *Principles of Transaction Processing* (2nd ed.). Morgan Kaufmann.
9. **IEEE Computer Society. (2014).** *Guide to the Software Engineering Body of Knowledge (SWEBOK Guide, Version 3.0)*. IEEE.
10. **Uttara University. (2024).** *Academic Regulations, Curriculum Guidelines, and Facility Management Manual*. Uttara University, Dhaka, Bangladesh.

---
*Report End — UniRoom-Live 2.0 Academic Project Proposal*
