# UNIROOM-LIVE 2.0: CAPSTONE PRESENTATION SLIDES & SPEAKER SCRIPT

**Project Title:**  
UniRoom-Live: A Multi-Tenant Real-Time Classroom Orchestration and Dynamic Academic Schedule Synchronization Platform  

**Institution:** Uttara University | School of Science and Engineering | Department of CSE  
**Target Duration:** 15 – 18 Minutes (approx. 5 minutes per speaker) + 5 Minutes Q&A  
**Presentation Deck File:** `PRESENTATION_SLIDES.pptx` (Located in Project Root)

---

## 3-MEMBER TEAM ALLOCATION MATRIX

| **Speaker** | **Assigned Slides** | **Core Themes & Focus Areas** | **Time Allocation** |
| :--- | :--- | :--- | :--- |
| **Speaker 1** | **Slides 1 – 6** | Title, Road-Map, Background Context, Problem Statement, System Overview, Objectives | ~5.0 Minutes |
| **Speaker 2** | **Slides 7 – 12** | Project Scope, Agile Methodology, System Architecture, Relational Data Modeling, OCC Concurrency Control, Tech Stack | ~5.5 Minutes |
| **Speaker 3** | **Slides 13 – 18**| Dynamic Routine Sync, CR Attendance Suite & Telephony SMS, 360px Mobile Responsiveness, Testing & UAT, Impact & Future Scope, Q&A | ~5.0 Minutes |

---

## DETAILED SLIDE-BY-SLIDE CONTENT & SPOKEN SCRIPT

---

### PART 1: THE FOUNDATION (SPEAKER 1)

#### Slide 1: Title Slide & Team Introduction
- **Visuals on Slide:**
  - Capstone Project Proposal Defense | CSE 4XX
  - Title: *UniRoom-Live: A Multi-Tenant Real-Time Classroom Orchestration and Dynamic Academic Schedule Synchronization Platform*
  - Subtitle: *Concurrency-Controlled Room Allocation, Push Synchronization, and Responsive Mobile Workflows*
  - Department of Computer Science & Engineering | Uttara University, Dhaka
  - Presenters: Member 1 [ID], Member 2 [ID], Member 3 [ID]
- **Speaker 1 Talking Points (What to say):**
  > *"Good morning, respected honorable faculty members, evaluators, and my fellow peers. I am [Member 1 Name], and along with my co-researchers [Member 2 Name] and [Member 3 Name], we are privileged to present our capstone project proposal: 'UniRoom-Live: A Multi-Tenant Real-Time Classroom Orchestration and Dynamic Academic Schedule Synchronization Platform'.*
  > 
  > *In higher education institutions like Uttara University, orchestrating physical classrooms, shifting routines, and tracking attendance across thousands of students is a daily operational battle. Today, we are excited to unveil our engineering solution designed to eliminate campus timetable disruption and spatial collisions through modern distributed system engineering."*

---

#### Slide 2: Presentation Road-Map & Agenda
- **Visuals on Slide:**
  - 3-Column Road-Map Card Layout:
    - **Part 1 (Speaker 1):** The Foundation (Context, Problem Statement, Overview, Objectives).
    - **Part 2 (Speaker 2):** Architecture & Methodology (Scope, Agile SDLC, 3-Tier Design, OCC Concurrency, Tech Stack).
    - **Part 3 (Speaker 3):** Execution, Workflows & Verification (Routine Sync, CR Attendance SMS, 360px Mobile UI, QA, Future Roadmap).
- **Speaker 1 Talking Points (What to say):**
  > *"To ensure a structured defense, our presentation is partitioned into three unified segments. I will begin by discussing the foundational problem landscape, our system overview, and primary objectives.*
  > 
  > *Next, my teammate [Member 2] will guide you through the architectural blueprints, database schema, and our concurrency control mathematical model. Finally, [Member 3] will demonstrate the mobile user workflows, the Class Representative attendance suite, testing benchmarks, and our future evolution roadmap."*

---

#### Slide 3: Background & Academic Context in Higher Education
- **Visuals on Slide:**
  - **The Modern University Reality:** High campus density, multi-shift batches, shared computing labs, ad-hoc make-up classes, physical room scarcity.
  - **Historical Shift in Schedule Communication:**
    - Phase 1: Static Notice Boards (Wall printouts; outdated the moment a class moves).
    - Phase 2: PDF Routine Files (Unsynchronized; cumbersome to read on mobile devices).
    - Phase 3: Social Media Chats (WhatsApp/Messenger; flooded with chat spam and misinformation).
    - The UniRoom-Live Imperative: An authoritative, real-time, synchronized source of truth.
- **Speaker 1 Talking Points (What to say):**
  > *"Let us examine the operational realities of our campus. Uttara University manages hundreds of courses daily across multi-shift programs. Class schedules are naturally dynamic—instructors schedule make-up lectures to finish syllabi, departmental meetings cause room relocations, and student presentation cohorts require vacant auditoriums.*
  > 
  > *Historically, universities relied on paper notice boards. Then we moved to PDF files uploaded to portals. Today, most communication happens over WhatsApp or Messenger groups. While informal chats feel quick, they create severe information fragmentation. Messages get buried beneath casual chatter, students travel to campus for cancelled classes, and there is no authoritative, synchronized digital record."*

---

#### Slide 4: Problem Statement: 5 Core Campus Friction Points
- **Visuals on Slide:**
  - **1. Schedule Anarchy & Rumors:** Lost rescheduling notices lead to students commuting needlessly.
  - **2. Room Collisions & Double-Booking:** Two batches arrive to claim the same room for makeup lectures.
  - **3. Ghost Occupancy:** Classes ending early leave rooms marked "occupied" on paper; other batches are locked out.
  - **4. CR Administrative Burden:** Manual roll calls on scrap sheets and typing 10-digit IDs into personal SMS.
  - **5. Lack of Concurrency & Audit:** Naive database queries cause race conditions; zero accountability.
- **Speaker 1 Talking Points (What to say):**
  > *"Through our research and stakeholder interviews, we identified five critical pain points that paralyze daily campus logistics:*
  > 
  > *First, Schedule Anarchy—students miss crucial schedule updates and commute through traffic only to find the class was cancelled.*
  > *Second, Classroom Collisions—when two instructors or Class Representatives book a room informally, both cohorts arrive at the exact same laboratory, causing friction and wasted class time.*
  > *Third, 'Ghost Occupancy'—rigid 90-minute timetable blocks keep rooms officially marked as 'Occupied' even when a class ends 30 minutes early, preventing other students from utilizing the space.*
  > *Fourth, CR Administrative Overhead—Class Representatives spend 15 minutes of every class transcribing absent roll numbers and manually typing them into SMS drafts.*
  > *And fifth, the lack of real-time concurrency controls and audit trails in existing campus software."*

---

#### Slide 5: UniRoom-Live System Overview
- **Visuals on Slide:**
  - **Presentation Client Tier:** Flutter Cross-Platform (Android/iOS/Web), 60 FPS reactive UI, responsive down to 360px viewport widths, offline-first routine caching.
  - **API & Orchestration Tier:** NestJS Modular TypeScript framework, pre-flight conflict engine, 5-tier RBAC security, FCM push notifications & SMTP alerts.
  - **Data Persistence Tier:** Neon Serverless PostgreSQL with ACID transactions, Prisma ORM, row-level concurrency locks.
- **Speaker 1 Talking Points (What to say):**
  > *"UniRoom-Live directly resolves these challenges by introducing an enterprise-grade, cloud-synchronized operational platform built on a modern decoupled architecture.*
  > 
  > *Our frontend is a high-performance Flutter application running natively on Android, iOS, and Web, specifically tuned down to 360px screen widths for universal student accessibility. Our backend is powered by NestJS in TypeScript, enforcing pre-flight conflict detection and role-based security. Finally, our persistence tier runs on PostgreSQL with Prisma ORM, providing ACID guarantees and transactional locking for every campus asset."*

---

#### Slide 6: Project Objectives
- **Visuals on Slide:**
  - **Core Strategic Objective:**  
    - **To** design and implement a multi-tenant, cloud-synchronized real-time classroom orchestration and dynamic academic schedule management platform that unifies students, faculty members, and campus administrators.
  - **Specific Technical Objectives:**  
    - **To** develop an Optimistic Concurrency Control (OCC) booking engine to eliminate double-booking.  
    - **To** formulate an intelligent pre-flight conflict detection algorithm checking room, faculty, and batch schedules.  
    - **To** engineer an automated push notification pipeline (FCM & SMTP) for instant schedule alterations.  
    - **To** implement a dynamic room release and early-checkout mechanism to eliminate "ghost occupancy".  
    - **To** build a streamlined CR attendance keypad and automated SMS generation engine.  
    - **To** establish a secure 5-tier Role-Based Access Control (RBAC) security layer using JWT and Bcrypt.  
    - **To** create a cross-platform Flutter client optimized down to 360px viewport widths with offline caching.  
    - **To** evaluate latency, reliability, and usability through load simulations and UAT at Uttara University.
- **Speaker 1 Talking Points (What to say):**
  > *"To guide our engineering roadmap, all our project objectives are strictly formulated to address these bottlenecks:*
  > 
  > *Our primary objective is **To** design and implement a multi-tenant, cloud-synchronized classroom orchestration platform.*
  > *Specifically, we aim **To** develop an Optimistic Concurrency Control engine that mathematically eliminates double-booking; **To** construct pre-flight conflict algorithms that validate routine entries before saving; **To** engineer automated push notifications using Firebase; **To** implement an early-checkout mechanism that liberates idle classrooms; and **To** build a rapid attendance tool for CRs that automates SMS generation.*
  > 
  > *With this foundation established, I now invite my colleague, [Member 2 Name], to walk you through our project scope, development methodology, and architectural engineering."*

*(Speaker 1 formally gestures and passes the microphone/floor to Speaker 2).*

---

### PART 2: ARCHITECTURE & METHODOLOGY (SPEAKER 2)

#### Slide 7: Project Scope: In-Scope Deliverables vs. Out-of-Scope Boundaries
- **Visuals on Slide:**
  - **In-Scope (Version 2.0 Deliverables):**
    - Multi-Tenant Institutional Hierarchy (Campuses, Buildings, Rooms, Departments, Batches).
    - Master Timetable Engine & Dynamic Routine Synchronization.
    - Pre-Flight Conflict Matrix (Room, Faculty, and Batch validation).
    - Concurrency-Controlled Real-Time Room Booking with OCC.
    - Dynamic Early Room Release & Checkout.
    - CR Attendance Keypad & Cellular SMS Telephony Launcher.
    - 5-Tier RBAC Authentication via JWT & Bcrypt.
    - Ultra-responsive Flutter Client (360px+).
  - **Out-of-Scope (Future Iterations):**
    - Physical IoT Smart Door Lock Hardware (ESP32/RFID solenoids — reserved for v3.0).
    - Biometric optical fingerprint/facial hardware terminals.
    - Commercial rental billing gateways.
    - Fully automated AI timetable generation via genetic algorithms.
- **Speaker 2 Talking Points (What to say):**
  > *"Thank you, [Member 1 Name]. Good morning, respected faculty. I am [Member 2 Name], and I will discuss our project scope, engineering methodology, and technical architecture.*
  > 
  > *To ensure that UniRoom-Live reaches production stability within our academic timeline, we defined clear scope boundaries. In-scope deliverables include our full multi-tenant hierarchy, conflict-free timetable management, atomic room reservations with early checkout, the CR attendance suite, and 360px mobile responsiveness.*
  > 
  > *Conversely, dedicated physical hardware—such as motorized door turnstiles and biometric fingerprint terminals—have been purposefully scoped for Version 3.0 IoT integration. This boundary ensures our software platform is mathematically rigorous, data-resilient, and immediately deployable."*

---

#### Slide 8: Development Methodology: Agile / Scrum Lifecycle
- **Visuals on Slide:**
  - **Agile Framework Rationale:** 8 two-week sprints over 16 weeks; continuous stakeholder feedback loops with CRs and faculty.
  - **Phases 1–4 (Weeks 1–8):** Domain Modeling -> Auth & RBAC -> Routine Conflict Engine -> OCC Room Booking & Release.
  - **Phases 5–8 (Weeks 9–16):** CR Attendance & SMS -> 360px Responsive UI & Caching -> FCM Push Notifications -> Concurrency Load Testing & UAT.
- **Speaker 2 Talking Points (What to say):**
  > *"We adopted the Agile / Scrum development lifecycle rather than traditional Waterfall. Academic routine management involves complex edge cases—such as overlapping lab sessions and sudden instructor shifts—which require frequent stakeholder demonstrations and iterative refinement.*
  > 
  > *Over 8 two-week sprints across 16 weeks, we progressed systematically: from relational domain modeling and RBAC authentication in the first month, to our routine conflict engine and OCC booking pipeline in Month 2, followed by mobile UI tuning, FCM notifications, and load testing in the final phases."*

---

#### Slide 9: System Architecture: Decoupled Three-Tier Design
- **Visuals on Slide:**
  - **Tier 1 (Presentation):** Flutter Mobile App (Android/iOS/Web) + Admin Web Dashboard (React/Vite). Provider state management, responsive LayoutBuilder, local token encryption.
  - **Tier 2 (Application/API):** NestJS Modular TypeScript framework. Controllers, Services, JwtAuthGuard, RolesGuard, Validation Pipes, Notification dispatch.
  - **Tier 3 (Data & Messaging):** Neon Serverless PostgreSQL, Prisma ORM, Firebase Cloud Messaging, SMTP relay, native device SMS intent.
- **Speaker 2 Talking Points (What to say):**
  > *"UniRoom-Live implements a decoupled Three-Tier Architecture. This enforces strict separation of concerns, horizontal scalability, and effortless maintainability.*
  > 
  > *At the presentation tier, our cross-platform Flutter client utilizes the Provider state management pattern to reactively reflect room availability changes. At the application tier, NestJS orchestrates business logic with modular encapsulation, protecting all endpoints with JWT guards and declarative validation pipes. Finally, our data tier utilizes PostgreSQL hosted on Neon Serverless Cloud, queried through Prisma ORM to guarantee compile-time type safety and SQL injection immunity."*

---

#### Slide 10: Relational Data Model & Multi-Tenancy Hierarchy
- **Visuals on Slide:**
  - **10 Relational Domain Entities:** Institutions, Campuses, Buildings, Rooms, Departments, Batches, Users, Routines, Bookings, AttendanceLogs.
  - **Pre-Flight Conflict Detection Matrix (Triple-Check):**
    1. *Room Clash:* Room is already occupied by another class.
    2. *Faculty Clash:* Instructor is assigned to teach another course simultaneously.
    3. *Batch Clash:* Student cohort already has an assigned lecture in this slot.
- **Speaker 2 Talking Points (What to say):**
  > *"Our database schema is organized into ten normalized relational entities supporting complete institutional multi-tenancy. An institution contains campuses, which house buildings, which partition into rooms with capacity metadata.*
  > 
  > *Crucially, our Routine Module incorporates an automated Pre-Flight Conflict Matrix. Whenever an administrator or faculty member attempts to create or modify a schedule entry, the algorithm cross-examines three dimensions simultaneously: room occupancy, instructor availability, and student batch timetables. If any collision is detected, the transaction aborts with a descriptive error, making schedule overlap mathematically impossible."*

---

#### Slide 11: Optimistic Concurrency Control (OCC) Booking Engine
- **Visuals on Slide:**
  - **Mathematical Overlap Condition:**  
    $$\text{Collision} \iff (t_{\text{start}}^{\text{existing}} < T_{\text{end}}) \land (t_{\text{end}}^{\text{existing}} > T_{\text{start}})$$
  - **The Race Condition Problem (Without OCC):** Two CRs submit requests for Room 402 within 10 milliseconds; naive systems create two conflicting approved rows.
  - **UniRoom-Live OCC Engine:** Atomic database transactions (`prisma.$transaction`). Exactly one transaction succeeds; competing requests receive immediate HTTP 409 Conflict.
- **Speaker 2 Talking Points (What to say):**
  > *"Now, let us examine the core technical engine of UniRoom-Live: our Optimistic Concurrency Control mechanism.*
  > 
  > *In conventional academic systems, if two Class Representatives attempt to book the same vacant classroom within milliseconds of each other, naive database queries experience a race condition—both see the room as vacant, and both create approved records, resulting in double-booking.*
  > 
  > *UniRoom-Live eliminates this flaw using atomic PostgreSQL transactions. When a reservation request arrives, our engine executes an atomic row-level check using the mathematical overlap formula shown on the slide: an overlap exists if Existing Start Time is less than Requested End Time, AND Existing End Time is greater than Requested Start Time. If any collision exists, the transaction rolls back immediately and returns an HTTP 409 Conflict status. Exactly one booking succeeds, guaranteeing spatial integrity."*

---

#### Slide 12: Technology Stack & Engineering Justifications
- **Visuals on Slide:**
  - **Table of Core Technologies:**
    - Flutter 3.x / Dart (Single codebase, 60fps native rendering, cross-platform).
    - Provider (^6.1.0) (Predictable, reactive state tree without boilerplate).
    - NestJS 10.x / TypeScript (Enterprise modular architecture, Dependency Injection).
    - Prisma ORM 5.x (Type-safe client, declarative schema, zero raw SQL flaws).
    - PostgreSQL 16 on Neon Cloud (ACID transactions, row-level locking).
    - Firebase Cloud Messaging (Battery-optimized background push delivery).
    - url_launcher (Direct cellular SMS generation without third-party SMS API fees).
- **Speaker 2 Talking Points (What to say):**
  > *"Every tool in our technology stack was selected for proven enterprise stability and performance.*
  > 
  > *Flutter allows us to ship to Android, iOS, and Web simultaneously while maintaining complete control over widget rendering down to 360px widths. NestJS brings enterprise design patterns to Node.js, while Prisma ORM ensures our database transactions are type-safe from schema to API response. Furthermore, our SMS module uses native mobile telephony intents, allowing CRs to send SMS reports directly from their phones without imposing expensive third-party SMS gateway fees on the university.*
  > 
  > *I will now pass the floor to [Member 3 Name], who will present our practical workflows, mobile responsiveness, testing results, and future roadmap."*

*(Speaker 2 formally gestures and passes the microphone/floor to Speaker 3).*

---

### PART 3: EXECUTION, VERIFICATION & FUTURE ROADMAP (SPEAKER 3)

#### Slide 13: Core Workflows: Routine Sync & Early Room Release
- **Visuals on Slide:**
  - **Dynamic Routine Synchronization:** Multi-parameter filtering (Day, Batch, Instructor); FCM background push alerts when routines change; local offline caching in device storage.
  - **Early Room Release Engine:** One-tap early checkout when a lecture finishes ahead of schedule; immediate database status flip from 'OCCUPIED' to 'AVAILABLE'; eliminates "ghost occupancy".
- **Speaker 3 Talking Points (What to say):**
  > *"Thank you, [Member 2 Name]. Respected faculty, I am [Member 3 Name]. I will now showcase the user-facing workflows, mobile responsiveness, validation results, and future trajectory of UniRoom-Live.*
  > 
  > *Our routine engine provides dynamic, multi-parameter filtering. A student simply selects their semester and batch, and their daily agenda appears instantly. When an instructor reschedules a class, an FCM push notification is broadcast, updating every student's phone automatically. Furthermore, our offline caching guarantees that students can verify their room locations even if campus Wi-Fi drops.*
  > 
  > *Equally important is our Early Room Release workflow. If a lab finishes 30 minutes early, the instructor or booking CR simply taps 'Release Room' on their phone. The system immediately returns that classroom to the public vacancy pool, transforming previously wasted 'ghost occupancy' into productive campus study space."*

---

#### Slide 14: Class Representative (CR) Attendance & Telephony Integration
- **Visuals on Slide:**
  - **Rapid Numerical Absent Keypad:** CR records absent roll numbers in seconds; batch prefixes auto-filled (e.g., 223030...); instant absent chip tags; live attendance percentage calculator.
  - **Automated Cellular SMS Integration:** Single-tap launch of native mobile SMS app; pre-populated instructor phone number; pre-formatted text containing Course Code, Date, Batch, and Absent IDs; zero third-party gateway costs.
- **Speaker 3 Talking Points (What to say):**
  > *"One of the greatest operational innovations of UniRoom-Live is our specialized Class Representative Attendance Suite.*
  > 
  > *Traditionally, CRs spend significant time passing paper sheets, calling out names, and manually retyping 10-digit ID numbers into SMS messages. In UniRoom-Live, the CR opens the Attendance tab and utilizes our custom rapid keypad. Batch prefixes are handled automatically—the CR simply taps the last two digits of absent students.*
  > 
  > *Once complete, tapping 'Send SMS to Faculty' invokes the native device telephony intent. The instructor's phone number is looked up automatically, and the SMS message is pre-formatted with the course code, date, and comma-separated absent rolls. What previously took 15 minutes of manual labor now takes under 30 seconds, with zero transcription errors."*

---

#### Slide 15: Mobile Client: Ultra-Responsive 360px Optimization
- **Visuals on Slide:**
  - **The 360px Engineering Challenge:** Budget smartphones used by university students have narrow 360px displays; default Flutter layouts cause RenderFlex yellow-and-black stripe errors.
  - **Comprehensive Solution:**
    - Custom Wrap widgets and flexible row layouts prevent text truncation.
    - SingleChildScrollView wrappers prevent keyboard popup overflow errors.
    - Adaptive modal bottom sheets dynamically resize to device dimensions.
  - **Tested Matrix:** 360px × 640px, 390px × 844px, 412px × 915px, and desktop web layouts verified.
- **Speaker 3 Talking Points (What to say):**
  > *"In a student environment, device equity is essential. Many university students carry budget smartphones with narrow 360px viewport widths. Standard mobile applications frequently suffer from RenderFlex overflow errors—the infamous yellow-and-black warning stripes—making buttons unclickable when the keyboard opens.*
  > 
  > *We engineered every screen, modal bottom sheet, and routine row in UniRoom-Live using adaptive constraints, flexible wrappers, and single-child scroll views. We rigorously tested our client on 360px screens, verifying that text never clips, keypad buttons remain comfortably touch-accessible, and routine tables render cleanly across every device."*

---

#### Slide 16: Testing, Verification & Quality Assurance
- **Visuals on Slide:**
  - **4-Tier QA Verification:**
    1. *Jest Automated Suite:* 100% test coverage across routine controllers, conflict validators, and role guards.
    2. *Concurrency Load Verification:* Scripted concurrent booking floods proved that exactly one reservation succeeds while competing requests receive HTTP 409.
    3. *Cross-Device Usability:* Emulators and physical devices (360px to 1080p) verified zero visual clipping.
    4. *User Acceptance Testing (UAT):* Uttara University student cohorts booked rooms in < 10 seconds and took attendance in < 30 seconds.
- **Speaker 3 Talking Points (What to say):**
  > *"To ensure academic and operational rigor, we conducted four levels of quality assurance.*
  > 
  > *First, automated Jest suites validated all backend endpoints. Second, we conducted automated concurrency load testing—simulating multiple simultaneous booking requests hitting the server within milliseconds—and verified that our OCC engine permitted exactly one reservation while rejecting all duplicates.*
  > 
  > *Finally, through User Acceptance Testing with students and CRs at Uttara University, participants consistently booked vacant classrooms in under 10 seconds and submitted complete attendance reports in under 30 seconds, proving our system's speed and reliability."*

---

#### Slide 17: Anticipated Impact & Future Evolution Roadmap
- **Visuals on Slide:**
  - **Campus Contributions:**
    - Zero Schedule Confusion (Instant push alerts end missed lectures).
    - Spatial Harmony (OCC eliminates room collisions and embarrassment).
    - Maximized Resource Utilization (Early release ends ghost occupancy).
    - CR Time Savings (Keypad & SMS save 10-15 minutes of class time daily).
    - Universal Accessibility (Responsive on all 360px+ devices).
  - **Future Roadmap (Version 3.0+):**
    - IoT Smart Door Locks (ESP32/RFID microcontrollers unlock doors during bookings).
    - Rotating QR-Code Attendance (Cryptographic QR codes projected on lecture screens).
    - AI-Powered Routine Optimization (Genetic algorithms auto-generate semester schedules).
    - Institutional ERP & LMS Integration (Bidirectional sync with Moodle/Canvas).
- **Speaker 3 Talking Points (What to say):**
  > *"The impact of UniRoom-Live on campus life is transformative. By providing real-time schedule synchronization, concurrency-safe room allocation, and automated CR attendance workflows, we restore operational efficiency to university classrooms.*
  > 
  > *Looking toward Version 3.0, our modular architecture is primed for future advancements: integrating ESP32 smart door locks to unlock rooms automatically, projecting rotating cryptographic QR codes for student self-check-in, applying genetic algorithms for automated semester routine generation, and linking directly with institutional LMS platforms like Moodle and Canvas."*

---

#### Slide 18: Conclusion & Q&A Session (All Speakers)
- **Visuals on Slide:**
  - "Thank You for Your Time & Attention!"
  - UniRoom-Live provides an enterprise-ready, concurrency-safe, real-time classroom orchestration foundation for modern tertiary institutions.
  - **Floor Open for Questions (Q&A):**
    - Speaker 1: Problem Definition, User Needs, Scope & Academic Policy.
    - Speaker 2: Backend Architecture, PostgreSQL OCC, Prisma ORM & Conflict Algorithms.
    - Speaker 3: Flutter Client Responsiveness (360px), CR SMS Telephony & Testing Metrics.
- **Speaker 3 Talking Points (What to say):**
  > *"In conclusion, UniRoom-Live transforms academic administration from reactive, informal chaos into a reliable, synchronized digital ecosystem. It is robust, scalable, and tailored to the everyday realities of students and educators.*
  > 
  > *On behalf of our entire team, thank you for your kind attention. All three of us are now delighted to open the floor to the honorable committee for questions and feedback."*

*(All 3 speakers stand attentively to take questions from the faculty panel).*

---

## FACULTY Q&A PREPARATION GUIDE (ANTICIPATED QUESTIONS & ANSWERS)

### Questions for Speaker 1 (Problem, Objectives & Stakeholders):
- **Q: Why not just use existing Google Calendar or institutional LMS (like Moodle) for routines?**
  - **Answer:** *"Google Calendar lacks multi-tenant campus awareness—it doesn't understand room capacity, lab equipment, or batch hierarchies. Moodle excels at assignments and grading, but lacks real-time physical room occupancy tracking, pre-flight clash detection, and mobile CR attendance telephony integration. UniRoom-Live is built specifically for physical campus orchestration."*

### Questions for Speaker 2 (Architecture, OCC & Concurrency):
- **Q: What happens if two students press the 'Book Room' button at the exact same millisecond?**
  - **Answer:** *"Our backend processes the request inside an isolated database transaction using `prisma.$transaction`. Under PostgreSQL's row-level locking, the first transaction checks the overlap condition and creates the approved booking. The second concurrent transaction instantly sees the active booking, rolls back, and returns an HTTP 409 Conflict exception, completely preventing double-booking."*
- **Q: Why did you choose NestJS over Express.js or Django?**
  - **Answer:** *"NestJS provides an enterprise-grade modular architecture with native TypeScript type safety, built-in dependency injection, and declarative validation pipes. Express lacks structured conventions, while NestJS gives us clear boundaries between Auth, Routines, Rooms, and Attendance modules that scale cleanly."*

### Questions for Speaker 3 (Flutter UI, CR SMS & Performance):
- **Q: Why use native SMS intent instead of a cloud SMS API like Twilio?**
  - **Answer:** *"Third-party SMS gateways charge per SMS message, which would require the university or students to maintain a paid API subscription. By utilizing the native device telephony intent (`url_launcher`), the app pre-fills the message and opens the phone's native SMS app. The CR sends it using their regular SIM SMS package at zero infrastructure cost to the university."*
- **Q: How did you fix the 360px screen overflow problems?**
  - **Answer:** *"We replaced rigid fixed-width containers and unbounded Row widgets with `Wrap`, `Flexible`, and `SingleChildScrollView` wrappers. Furthermore, modal dialogs dynamically adapt their maximum height relative to `MediaQuery.of(context).size.height`, preventing RenderFlex yellow-and-black overflow stripes when the software keyboard pops up."*
