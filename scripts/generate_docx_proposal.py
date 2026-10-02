import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    tcPr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>'))

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def create_proposal_docx(output_path):
    doc = Document()

    # Page Margins: 1 inch (72 pt = 1440 dxa)
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)

    # Base Styles
    normal_style = doc.styles['Normal']
    normal_font = normal_style.font
    normal_font.name = 'Calibri'
    normal_font.size = Pt(11)
    normal_font.color.rgb = RGBColor(0x22, 0x22, 0x22)

    # Document Header / Pre-title
    p_meta = doc.add_paragraph()
    p_meta.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_meta = p_meta.add_run("ACADEMIC PROJECT PROPOSAL REPORT\nDEPARTMENT OF COMPUTER SCIENCE & ENGINEERING\nUTTARA UNIVERSITY, DHAKA, BANGLADESH")
    run_meta.font.size = Pt(10)
    run_meta.font.bold = True
    run_meta.font.color.rgb = RGBColor(0x55, 0x55, 0x55)

    doc.add_paragraph().paragraph_format.space_after = Pt(6)

    # Main Project Title
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_title = p_title.add_run("UniRoom-Live: A Multi-Tenant Real-Time Classroom Orchestration and Dynamic Academic Schedule Synchronization Platform")
    run_title.font.size = Pt(20)
    run_title.font.bold = True
    run_title.font.color.rgb = RGBColor(0x11, 0x2D, 0x4E) # Deep Navy
    p_title.paragraph_format.space_after = Pt(6)

    # Subtitle
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_sub = p_sub.add_run("Eliminating Campus Timetable Disruption and Room Allocation Collisions Through Concurrency-Controlled Resource Orchestration, Instant Push Synchronization, and Responsive Mobile Workflows")
    run_sub.font.size = Pt(12)
    run_sub.font.italic = True
    run_sub.font.color.rgb = RGBColor(0x44, 0x55, 0x66)
    p_sub.paragraph_format.space_after = Pt(18)

    # Metadata Table
    meta_table = doc.add_table(rows=0, cols=2)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_table.autofit = False

    metadata_rows = [
        ("Institution", "Uttara University"),
        ("Faculty / School", "School of Science and Engineering"),
        ("Department", "Department of Computer Science & Engineering (CSE)"),
        ("Course Title", "Capstone Design Project / Project & Thesis (CSE 4XX)"),
        ("Project Domain", "Distributed Systems, Cloud Computing & Cross-Platform Mobile Engineering"),
        ("Target Platforms", "Android, iOS, Progressive Web App (PWA), Desktop Web"),
        ("Target Stakeholders", "Students, Class Representatives (CRs), Faculty, Department Coordinators, Admin"),
        ("Version & Status", "Version 2.0 (Production-Ready Architecture)"),
    ]

    for label, val in metadata_rows:
        row = meta_table.add_row()
        c0, c1 = row.cells[0], row.cells[1]
        c0.width = Inches(2.2)
        c1.width = Inches(4.3)
        
        set_cell_background(c0, "F0F4F8")
        set_cell_background(c1, "FAFAFA")
        set_cell_margins(c0, top=80, bottom=80, left=120, right=120)
        set_cell_margins(c1, top=80, bottom=80, left=120, right=120)

        p0 = c0.paragraphs[0]
        r0 = p0.add_run(label)
        r0.font.bold = True
        r0.font.size = Pt(9.5)
        r0.font.color.rgb = RGBColor(0x11, 0x2D, 0x4E)

        p1 = c1.paragraphs[0]
        r1 = p1.add_run(val)
        r1.font.size = Pt(9.5)

    doc.add_paragraph().paragraph_format.space_after = Pt(16)

    # Helper for Headings
    def add_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(16)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.size = Pt(15)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0x0F, 0x4C, 0x81) # Classic Academic Blue
        return p

    def add_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.size = Pt(12.5)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0x1E, 0x3A, 0x5F)
        return p

    def add_body(text, space_after=6, italic=False, bold=False):
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.line_spacing = 1.15
        run = p.add_run(text)
        run.font.size = Pt(11)
        run.font.italic = italic
        run.font.bold = bold
        return p

    def add_bullet(lead_bold, rest_text):
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.line_spacing = 1.15
        r_lead = p.add_run(lead_bold)
        r_lead.font.bold = True
        r_lead.font.size = Pt(11)
        r_rest = p.add_run(rest_text)
        r_rest.font.size = Pt(11)
        return p

    # SECTION 1: INTRODUCTION
    add_h1("1. INTRODUCTION")
    
    add_h2("1.1 Background and Context")
    add_body(
        "Higher education institutions operate in intricate, fast-moving environments characterized by multi-shift academic "
        "programs, shared specialized laboratories, large student enrollments, and hundreds of lecture halls distributed "
        "across distinct physical campus buildings. At institutions such as Uttara University, academic schedules are not "
        "static; they fluctuate continuously throughout each semester due to makeup and extra classes, unplanned faculty "
        "reassignments, specialized lab migrations, and ad-hoc student project presentations or club workshops."
    )
    add_body(
        "Historically, academic institutions communicated these changes using static paper notices, physical bulletin boards, "
        "and periodically published PDF routine sheets. In recent years, communication transitioned toward informal messaging "
        "platforms, including WhatsApp, Telegram, and Facebook Messenger groups. While fast, this informal model introduces "
        "critical communication bottlenecks, fragmented information silos, and administrative disorder."
    )

    add_h2("1.2 System Overview")
    add_body(
        "UniRoom-Live is conceived, designed, and engineered as an enterprise-grade, centralized, and authoritative real-time "
        "operational hub for campus schedules and classroom assets. The platform replaces informal chat groups and static PDF "
        "documents with an active, event-driven digital ecosystem built upon a decoupled Three-Tier Architecture:"
    )
    add_bullet("1. Presentation Tier (Flutter Cross-Platform Application): ", 
               "A fluid, high-performance client delivering customized workflows for Students, Class Representatives, Faculty, and Administrators, with responsive layout tuning down to 360px viewport widths and client-side offline routine caching.")
    add_bullet("2. Application Tier (NestJS Enterprise REST API): ", 
               "A modular TypeScript micro-framework orchestrating multi-tenancy isolation, authentication guards, pre-flight conflict validation, and event dispatch pipelines.")
    add_bullet("3. Data and Event Tier (PostgreSQL + Prisma ORM + FCM): ", 
               "An ACID-compliant relational persistence store executing transactional locks, version-controlled records, and push event pipelines via Firebase Cloud Messaging and SMTP email relays.")

    add_h2("1.3 Target Stakeholders and Operational Roles")
    add_body(
        "UniRoom-Live organizes university operations around five distinct Role-Based Access Control (RBAC) privilege tiers:"
    )
    add_bullet("Superadmin / Institutional Executive: ", "Configures global institutional boundaries, manages multi-campus facilities, and monitors macro-level operational metrics.")
    add_bullet("Department Admin / Program Coordinator: ", "Establishes master semester schedules, assigns batches and instructors, resolves cross-departmental room collisions, and audits facility usage logs.")
    add_bullet("Faculty Member: ", "Reviews real-time daily teaching agendas, requests vacant classrooms for extra sessions, releases reserved rooms early when lectures conclude ahead of schedule, and receives instant attendance rolls.")
    add_bullet("Class Representative (CR): ", "Serves as the frontline operational liaison for student cohorts; reserves on-demand rooms for batch sessions, logs daily student attendance using a rapid-entry absent keypad, and formats automatic SMS reports to instructors.")
    add_bullet("Student: ", "Accesses real-time, filtered daily routines, checks live room availability across campus buildings, and receives instant push notifications when classes are rescheduled, relocated, or cancelled.")

    # SECTION 2: PROBLEM STATEMENT
    add_h1("2. PROBLEM STATEMENT")
    add_body(
        "Despite substantial investments in modern university infrastructure, daily campus administration experiences severe "
        "operational friction caused by manual scheduling practices and decentralized communication tools. The critical problems "
        "addressed by this project are:"
    )
    
    add_h2("2.1 Fragmented Communication and Schedule Desynchronization")
    add_body(
        "When an instructor shifts a lecture from 8:30 AM to 11:30 AM or relocates from Room 402 to Lab 605, updates are typically "
        "transmitted via phone calls to the Class Representative, who then types a notice into a social media group chat. This approach "
        "repeatedly fails: students with muted notifications or poor connectivity miss announcements and travel to campus unnecessarily; "
        "critical schedule updates become lost under casual chat conversations; and students rely on obsolete PDF files without an authoritative source of truth."
    )

    add_h2("2.2 Physical Classroom Collisions and Double-Booking")
    add_body(
        "When multiple instructors or batch representatives organize extra lectures, review sessions, or makeup labs, they often identify "
        "a seemingly empty room on a static timetable and occupy it without centralized coordination. Consequently, multiple cohorts "
        "(e.g., Batch 58 and Batch 61) arrive at the exact same laboratory or classroom simultaneously, leading to academic disruption, "
        "embarrassment, and lost instructional time."
    )

    add_h2("2.3 Resource Inefficiency and 'Ghost Occupancy'")
    add_body(
        "Standard campus routine models allocate rooms in rigid blocks (e.g., 90 or 120 minutes). If a lecture concludes 30 minutes early, "
        "or if an instructor cancels a class due to illness or departmental duties, the room remains officially designated as 'Occupied' "
        "on paper. Consequently, physical spaces remain locked and empty while other student groups search fruitlessly for available study or presentation venues."
    )

    add_h2("2.4 Administrative Burden on Class Representatives (CRs)")
    add_body(
        "Class Representatives perform repetitive clerical duties that disrupt their academic focus: conducting manual roll calls on scrap sheets "
        "of paper during short class breaks, transcribing lists of absent student ID numbers, and typing long lists of 10-digit student ID "
        "numbers into their smartphones to send via SMS to instructors. This manual process introduces transcription errors and delays attendance reporting."
    )

    add_h2("2.5 Absence of Real-Time Concurrency Control and Auditability")
    add_body(
        "Prior academic management applications lack robust database concurrency controls. When two users submit a reservation request for "
        "the same vacant lecture hall within milliseconds of each other, standard database queries create duplicate records (race conditions). "
        "Furthermore, paper and group-chat methods lack immutable audit trails to verify who authorized schedule overrides or abandoned assigned rooms."
    )

    # SECTION 3: OBJECTIVES
    add_h1("3. OBJECTIVES")
    add_body(
        "The objectives of this project are strictly formulated to address the identified operational and technical bottlenecks:"
    )

    add_h2("3.1 Primary Objective")
    add_bullet("To ", "design and implement a multi-tenant, cloud-synchronized real-time classroom orchestration and dynamic academic schedule management platform that unifies students, faculty members, and campus administrators under a single authoritative, high-availability digital ecosystem.")

    add_h2("3.2 Specific Technical and Research Objectives")
    add_bullet("To ", "develop an Optimistic Concurrency Control (OCC) and atomic transactional booking engine within a relational PostgreSQL database to eliminate race conditions, preventing double-booking of physical classrooms during high-traffic scheduling windows.")
    add_bullet("To ", "formulate an intelligent pre-flight conflict detection algorithm that cross-evaluates proposed timetable modifications against physical room capacities, faculty availability, and student cohort schedules prior to database persistence.")
    add_bullet("To ", "engineer an automated push notification and event distribution pipeline leveraging Firebase Cloud Messaging (FCM) and SMTP services to instantly broadcast schedule alterations, cancellations, and room reallocations to all affected stakeholders.")
    add_bullet("To ", "implement a dynamic room release and early-checkout mechanism that liberates unoccupied physical spaces back into the public vacancy pool, systematically eliminating 'ghost occupancy' and maximizing campus facility utilization.")
    add_bullet("To ", "build a streamlined Class Representative (CR) attendance utility featuring a rapid-entry absent keypad and an automated SMS generation engine to eliminate manual transcription errors and accelerate faculty roll reporting.")
    add_bullet("To ", "establish a secure, multi-tenant Role-Based Access Control (RBAC) security architecture powered by JSON Web Tokens (JWT) and cryptographic hashing to enforce strict operational boundaries across five user privilege tiers.")
    add_bullet("To ", "create a high-performance, cross-platform mobile client in Flutter that delivers an adaptive, fluid user experience across diverse screen dimensions (specifically optimized down to 360px viewport widths) with client-side caching for offline routine consultation.")
    add_bullet("To ", "evaluate the operational efficiency, latency, and system reliability through rigorous integration testing, simulated concurrent load scenarios, and real-world stakeholder usability trials at Uttara University.")

    # SECTION 4: PROJECT SCOPE
    add_h1("4. PROJECT SCOPE")
    add_h2("4.1 In-Scope Deliverables and Core Modules")
    add_body(
        "The development and implementation scope of UniRoom-Live encompasses the following operational and technical modules:"
    )
    add_bullet("1. Multi-Tenant Physical and Academic Hierarchy: ", 
               "Complete relational modeling of Institutions, Campuses, Buildings, Rooms, Departments, Degree Programs, and Student Batches/Sections with floor, capacity, and room categorization.")
    add_bullet("2. Master Timetable & Dynamic Routine Synchronization: ", 
               "Authoring, updating, and real-time synchronization of recurring weekly class schedules with multi-parameter filtering (by Day, Department, Semester, Batch, Faculty) and offline client caching.")
    add_bullet("3. Pre-Flight Conflict Inspection Matrix: ", 
               "Triple-factor validation ensuring no room collisions, faculty schedule overlaps, or batch double-scheduling can be persisted into the database.")
    add_bullet("4. Real-Time Room Discovery and Concurrency-Controlled Booking: ", 
               "Live vacancy scanning across campus facilities and atomic reservation processing backed by Optimistic Concurrency Control (OCC).")
    add_bullet("5. Dynamic Early Room Release Engine: ", 
               "Early checkout workflow enabling instructors and CRs to release vacant spaces back to the public pool ahead of scheduled slot conclusions.")
    add_bullet("6. CR Rapid Attendance & Telephony Integration: ", 
               "Custom numerical absent-roll keypad, automated statistical computation, and direct device telephony SMS launching with pre-populated instructor phone numbers and formatted absent ID strings.")
    add_bullet("7. Enterprise Authentication & Role-Based Access Control (RBAC): ", 
               "Secure JWT authentication, Bcrypt password salting and hashing, and permission guards enforcing boundaries across 5 user privilege levels.")
    add_bullet("8. Multi-Channel Notification Infrastructure: ", 
               "Real-time background push alerts via Firebase Cloud Messaging (FCM) and institutional transactional emails via Nodemailer/SMTP.")
    add_bullet("9. Ultra-Responsive Mobile Client: ", 
               "Flutter mobile client for Android, iOS, and Web optimized for seamless rendering across all mobile screen widths down to 360px.")

    add_h2("4.2 Out-of-Scope and Future Boundaries")
    add_body(
        "To ensure high engineering quality, architectural focus, and successful deployment within the academic semester timeframe, "
        "the following components are explicitly defined as out-of-scope for the Version 2.0 release:"
    )
    add_bullet("Physical IoT Hardware Door Locks: ", "Direct electronic solenoid turnstiles and micro-controller relays (scheduled for Version 3.0 IoT hardware integration).")
    add_bullet("Biometric Hardware Terminals: ", "Dedicated optical fingerprint readers or standalone thermal infrared facial scanners.")
    add_bullet("Financial Payment Gateways: ", "Monetary payment or room rental billing processing.")
    add_bullet("Fully Automated AI Timetable Generation: ", "Automated schedule generation using genetic algorithms (the system provides master routine management and pre-flight conflict detection; automated heuristic synthesis is earmarked for future research).")

    # SECTION 5: METHODOLOGY
    add_h1("5. METHODOLOGY")
    add_body(
        "The engineering and execution of UniRoom-Live follows a disciplined, agile methodology combining empirical requirement "
        "analysis, decoupled three-tier system architecture, relational database concurrency modeling, and rigorous multi-stage quality assurance."
    )

    add_h2("5.1 Software Development Life Cycle (SDLC) - Agile/Scrum")
    add_body(
        "The project is structured under the Agile / Scrum development lifecycle, partitioned into eight 2-week sprints across a 16-week timeline. "
        "This iterative approach was chosen because university scheduling dynamics and mobile user experience workflows benefit from continuous "
        "validation by actual students, Class Representatives, and faculty members."
    )

    add_h2("5.2 Requirement Engineering and System Specifications")
    add_body(
        "Requirements were synthesized through structured interviews with Uttara University academic coordinators, faculty members, and CRs:"
    )
    add_bullet("Functional Requirements (FRs): ", 
               "FR-1 (Hierarchy Modeling), FR-2 (Role Authentication & RBAC), FR-3 (Master Timetable Filtering), FR-4 (Triple-Collision Pre-Flight Validation), FR-5 (Concurrency-Safe Room Booking), FR-6 (Early Room Release), FR-7 (CR Attendance & SMS Engine), FR-8 (FCM Push Notifications).")
    add_bullet("Non-Functional Requirements (NFRs): ", 
               "NFR-1 (Zero Double-Booking & ACID Integrity), NFR-2 (Sub-150ms Query Latency), NFR-3 (Fluid Responsiveness down to 360px Screen Widths), NFR-4 (Offline-First Routine Caching), NFR-5 (Bcrypt Hashing and Signed JWT Security).")

    add_h2("5.3 System Architecture and High-Level Design")
    add_body(
        "UniRoom-Live implements a decoupled Three-Tier Architecture:"
    )
    add_bullet("1. Client Layer: ", "Cross-platform Flutter application utilizing Provider state management and responsive layout builders.")
    add_bullet("2. API & Orchestration Layer: ", "Modular NestJS backend utilizing dependency injection, declarative validation pipes, and role authorization guards.")
    add_bullet("3. Data & Messaging Layer: ", "Neon Serverless PostgreSQL database interfaced via Prisma ORM, complemented by Firebase Cloud Messaging and SMTP gateways.")

    add_h2("5.4 Database Design and Concurrency Control Strategy")
    add_body(
        "The persistence layer comprises ten normalized relational entities (Institutions, Campuses, Buildings, Rooms, Departments, "
        "Batches, Users, Routines, Bookings, AttendanceLogs). To prevent double-booking during concurrent booking requests, the system "
        "employs Optimistic Concurrency Control (OCC) using atomic database transactions:"
    )
    add_body(
        "Collision Detection Condition: (ExistingStartTime < RequestedEndTime) AND (ExistingEndTime > RequestedStartTime)",
        italic=True, bold=True
    )
    add_body(
        "When a conflict is detected during atomic transaction execution, the database rolls back the operation and returns an HTTP 409 "
        "Conflict exception, guaranteeing zero duplicate room reservations."
    )

    add_h2("5.5 Implementation Phases and Sprint Breakdown")
    
    # Sprint Table
    sprint_table = doc.add_table(rows=0, cols=4)
    sprint_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    sprint_table.autofit = False

    sprint_data = [
        ("Phase / Sprint", "Duration", "Key Deliverables", "Milestone Outcome"),
        ("Sprint 1: Domain Modeling", "Weeks 1–2", "Requirements specification, ER diagram, Prisma schema design, Git repository setup.", "Data model & DB migrations solidified."),
        ("Sprint 2: Auth & RBAC", "Weeks 3–4", "NestJS Auth module, Bcrypt password hashing, JWT strategy, Role guards.", "Secure 5-tier authentication operational."),
        ("Sprint 3: Routine Engine", "Weeks 5–6", "CRUD timetable endpoints, multi-parameter filtering, conflict pre-flight validator.", "Zero-conflict routine authoring verified."),
        ("Sprint 4: Room Booking & OCC", "Weeks 7–8", "Vacancy search algorithm, atomic room reservation transaction, early-release engine.", "Concurrency-safe room booking validated."),
        ("Sprint 5: CR Attendance Suite", "Weeks 9–10", "Rapid absent keypad in Flutter, attendance summary widget, telephony SMS engine.", "CR attendance & SMS tested on mobile."),
        ("Sprint 6: Responsive UI (360px)", "Weeks 11–12", "Layout refactoring, elimination of pixel overflows, adaptive dialogs, offline cache.", "Flawless rendering on 360px–412px viewports."),
        ("Sprint 7: Real-Time Alerts", "Weeks 13–14", "Firebase Cloud Messaging integration, device token registration, SMTP mail service.", "Push notifications delivered on updates."),
        ("Sprint 8: QA & Deployment", "Weeks 15–16", "Concurrency load tests, Jest integration suites, production deployment, UAT.", "System defense and production rollout."),
    ]

    for idx, (c0_text, c1_text, c2_text, c3_text) in enumerate(sprint_data):
        row = sprint_table.add_row()
        cells = row.cells
        cells[0].width = Inches(1.8)
        cells[1].width = Inches(1.0)
        cells[2].width = Inches(2.3)
        cells[3].width = Inches(1.4)
        
        is_header = (idx == 0)
        bg_color = "112D4E" if is_header else ("F0F4F8" if idx % 2 == 1 else "FFFFFF")
        
        for c_idx, cell in enumerate(cells):
            set_cell_background(cell, bg_color)
            set_cell_margins(cell, top=60, bottom=60, left=80, right=80)
            p = cell.paragraphs[0]
            run = p.add_run([c0_text, c1_text, c2_text, c3_text][c_idx])
            run.font.size = Pt(8.5 if not is_header else 9.0)
            if is_header:
                run.font.bold = True
                run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
            else:
                run.font.color.rgb = RGBColor(0x22, 0x22, 0x22)

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    add_h2("5.6 Technology Stack and Tooling")

    tech_table = doc.add_table(rows=0, cols=4)
    tech_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    tech_table.autofit = False

    tech_data = [
        ("Layer / Component", "Technology", "Version", "Engineering Justification"),
        ("Mobile Client", "Flutter (Dart)", "SDK 3.x+ / Dart 3.x", "Single codebase for Android, iOS & Web; 60fps performance; 360px responsive control."),
        ("State Management", "Provider", "^6.1.0", "Reactive, predictable state tree without boilerplate overhead."),
        ("Backend Framework", "NestJS (TypeScript)", "^10.x", "Enterprise modular architecture, dependency injection, type safety."),
        ("ORM Layer", "Prisma ORM", "^5.x", "Declarative schema, type-safe queries, automatic migration management."),
        ("Database Engine", "PostgreSQL (Neon)", "v16 Cloud", "ACID transactions, row-level locks, cloud high availability."),
        ("Authentication & Crypto", "JWT & Bcrypt", "Passport / Bcrypt.js", "Stateless, horizontally scalable authorization with cryptographic security."),
        ("Push Notifications", "Firebase Cloud Messaging", "Firebase Admin SDK", "Battery-optimized background push notifications across platforms."),
        ("SMS Telephony", "url_launcher (Intent)", "Native Mobile URI", "Direct hardware-level SMS creation without third-party SMS aggregator fees."),
        ("Cloud Deployment", "Render & Neon", "Cloud Native", "Automated containerized CI/CD pipeline integrated with GitHub repository."),
    ]

    for idx, (c0_text, c1_text, c2_text, c3_text) in enumerate(tech_data):
        row = tech_table.add_row()
        cells = row.cells
        cells[0].width = Inches(1.5)
        cells[1].width = Inches(1.5)
        cells[2].width = Inches(1.1)
        cells[3].width = Inches(2.4)
        
        is_header = (idx == 0)
        bg_color = "112D4E" if is_header else ("F0F4F8" if idx % 2 == 1 else "FFFFFF")
        
        for c_idx, cell in enumerate(cells):
            set_cell_background(cell, bg_color)
            set_cell_margins(cell, top=60, bottom=60, left=80, right=80)
            p = cell.paragraphs[0]
            run = p.add_run([c0_text, c1_text, c2_text, c3_text][c_idx])
            run.font.size = Pt(8.5 if not is_header else 9.0)
            if is_header:
                run.font.bold = True
                run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
            else:
                run.font.color.rgb = RGBColor(0x22, 0x22, 0x22)

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    add_h2("5.7 Testing, Verification, and Quality Assurance")
    add_body(
        "System reliability and user satisfaction are verified across four comprehensive testing tiers:"
    )
    add_bullet("1. Unit and Integration Testing: ", "Automated backend suites written in Jest validating routine filtering, conflict checking, and user profile permissions.")
    add_bullet("2. Concurrency Load Verification: ", "Simulated concurrent booking requests testing the OCC engine to confirm zero duplicate room allocations under high request volumes.")
    add_bullet("3. Cross-Device Responsive Verification: ", "Verification on physical hardware and emulators covering 360px × 640px (compact), 390px × 844px, and 412px × 915px form factors to ensure zero render overflows.")
    add_bullet("4. User Acceptance Testing (UAT): ", "Real-world testing with student cohorts and Class Representatives at Uttara University measuring workflow completion speed and usability satisfaction.")

    # SECTION 6: CONCLUSION
    add_h1("6. CONCLUSION")
    
    add_h2("6.1 Anticipated Contributions and Impact")
    add_body(
        "The development and deployment of UniRoom-Live directly resolves acute operational bottlenecks that degrade daily campus "
        "life in modern universities. By transitioning institutional schedules from chaotic, informal messaging groups and static PDF "
        "notices into a dynamic, cloud-synchronized operational platform, the project achieves five pivotal outcomes:"
    )
    add_bullet("1. Elimination of Schedule Confusion: ", "Students and instructors receive instantaneous, authoritative notifications regarding timetable adjustments, eliminating missed classes and unnecessary travel.")
    add_bullet("2. Guaranteed Spatial Harmony: ", "The concurrency-controlled room booking engine prevents double-booking and room clashes, ensuring smooth execution for makeup lectures and academic events.")
    add_bullet("3. Maximized Campus Facility Utilization: ", "The dynamic room discovery and early-release mechanisms unlock physical capacity, eliminating 'ghost occupancy' across lecture halls and laboratories.")
    add_bullet("4. Radical Reduction in Administrative Overhead: ", "Class Representatives save valuable instructional time utilizing the rapid keypad attendance logger and automatic SMS formatting engine.")
    add_bullet("5. Universal Device Accessibility: ", "The responsive Flutter mobile application ensures that every student, regardless of screen dimensions or smartphone model (down to 360px viewport widths), experiences an accessible, fluid interface.")

    add_h2("6.2 Future Research and Development Scope")
    add_body(
        "Following successful deployment and institutional adoption at Uttara University, the UniRoom-Live platform is architected "
        "to accommodate future technological expansions:"
    )
    add_bullet("IoT Smart Door Hardware Integration: ", "Interfacing room reservation states with microcontroller-driven smart locks (ESP32/RFID) to automatically unlock physical classroom doors during authorized booking windows.")
    add_bullet("Biometric and QR-Code Attendance Verification: ", "Expanding the attendance module to include rotating cryptographic QR codes displayed on classroom screens for instant student self-verification.")
    add_bullet("AI-Powered Timetable Optimization: ", "Integrating constraint satisfaction algorithms (genetic algorithms / linear programming) to auto-generate conflict-free master semester timetables based on faculty availability, batch sizes, and physical room capacity.")
    add_bullet("Institutional ERP & LMS Integration: ", "Establishing bidirectional data pipelines with institutional platforms such as Moodle, Canvas, and university registrar systems.")

    # SECTION 7: REFERENCES
    add_h1("7. REFERENCES")
    
    references = [
        "1. Sommerville, I. (2015). Software Engineering (10th ed.). Pearson Education.",
        "2. Fowler, M. (2002). Patterns of Enterprise Application Architecture. Addison-Wesley Professional.",
        "3. Elmasri, R., & Navathe, S. B. (2016). Fundamentals of Database Systems (7th ed.). Pearson.",
        "4. Fielding, R. T. (2000). Architectural Styles and the Design of Network-based Software Architectures (Doctoral dissertation). University of California, Irvine.",
        "5. NestJS Documentation Team. (2024). NestJS: A progressive Node.js framework for building efficient, reliable and scalable server-side applications. Available at: https://docs.nestjs.com",
        "6. Flutter Documentation Team. (2024). Flutter: Build apps for any screen. Google LLC. Available at: https://docs.flutter.dev",
        "7. Prisma Team. (2024). Prisma: Next-generation ORM for Node.js and TypeScript. Available at: https://www.prisma.io/docs",
        "8. Bernstein, P. A., & Newcomer, E. (2009). Principles of Transaction Processing (2nd ed.). Morgan Kaufmann.",
        "9. IEEE Computer Society. (2014). Guide to the Software Engineering Body of Knowledge (SWEBOK Guide, Version 3.0). IEEE.",
        "10. Uttara University. (2024). Academic Regulations, Curriculum Guidelines, and Facility Management Manual. Uttara University, Dhaka, Bangladesh."
    ]

    for ref in references:
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.line_spacing = 1.15
        p.paragraph_format.left_indent = Inches(0.25)
        run = p.add_run(ref)
        run.font.size = Pt(10)

    # Save document
    doc.save(output_path)
    print(f"Successfully generated proposal document: {output_path}")

if __name__ == "__main__":
    out_file = os.path.join(os.path.abspath("."), "PROJECT_PROPOSAL_REPORT.docx")
    create_proposal_docx(out_file)
