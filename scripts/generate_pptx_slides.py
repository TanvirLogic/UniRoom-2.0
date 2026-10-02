import os
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE
from pptx.dml.color import RGBColor

def create_deck(output_path):
    prs = Presentation()
    # 16:9 widescreen dimensions
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6]

    # Color Palette: Corporate Academic Tech
    C_NAVY_DARK = RGBColor(0x0A, 0x19, 0x2F)   # Deepest Navy
    C_NAVY = RGBColor(0x11, 0x2D, 0x4E)        # Primary Navy
    C_BLUE = RGBColor(0x0F, 0x4C, 0x81)        # Academic Blue
    C_LIGHT_BG = RGBColor(0xF4, 0xF7, 0xFA)    # Off-white / light slate
    C_WHITE = RGBColor(0xFF, 0xFF, 0xFF)
    C_CARD_BG = RGBColor(0xFF, 0xFF, 0xFF)
    C_BORDER = RGBColor(0xDC, 0xE2, 0xEC)
    C_TEXT_DARK = RGBColor(0x1A, 0x20, 0x2C)
    C_TEXT_MUTED = RGBColor(0x4A, 0x55, 0x68)
    C_ACCENT_BLUE = RGBColor(0x2B, 0x6C, 0xB0)
    C_ACCENT_TEAL = RGBColor(0x31, 0x97, 0x95)
    C_ACCENT_ORANGE = RGBColor(0xDD, 0x6B, 0x20)
    C_SPEAKER_TAG = RGBColor(0x2B, 0x6C, 0xB0)

    def add_bg(slide, color=C_LIGHT_BG):
        bg = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, Inches(13.333), Inches(7.5))
        bg.fill.solid()
        bg.fill.fore_color.rgb = color
        bg.line.color.rgb = color
        return bg

    def add_header(slide, title_text, category_text, speaker_label=""):
        # Header banner
        header_box = slide.shapes.add_textbox(Inches(0.8), Inches(0.4), Inches(11.733), Inches(1.1))
        tf = header_box.text_frame
        tf.word_wrap = True
        tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = 0

        # Category + Speaker tag line
        p_cat = tf.paragraphs[0]
        r_cat = p_cat.add_run()
        r_cat.text = category_text.upper()
        r_cat.font.size = Pt(10)
        r_cat.font.bold = True
        r_cat.font.color.rgb = C_BLUE

        if speaker_label:
            r_spk = p_cat.add_run()
            r_spk.text = f"   |   {speaker_label.upper()}"
            r_spk.font.size = Pt(10)
            r_spk.font.bold = True
            r_spk.font.color.rgb = C_ACCENT_ORANGE

        # Title line
        p_title = tf.add_paragraph()
        p_title.space_before = Pt(4)
        r_title = p_title.add_run()
        r_title.text = title_text
        r_title.font.size = Pt(22)
        r_title.font.bold = True
        r_title.font.color.rgb = C_NAVY_DARK

    def add_card(slide, left, top, width, height, title, items, badge="", bg_color=C_CARD_BG, border_color=C_BORDER):
        # Card Background
        card = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(left), Inches(top), Inches(width), Inches(height))
        card.fill.solid()
        card.fill.fore_color.rgb = bg_color
        card.line.color.rgb = border_color
        card.line.width = Pt(1.5)

        # Content Text Box
        tb = slide.shapes.add_textbox(Inches(left + 0.25), Inches(top + 0.2), Inches(width - 0.5), Inches(height - 0.4))
        tf = tb.text_frame
        tf.word_wrap = True
        tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = 0

        # Title / Badge
        p0 = tf.paragraphs[0]
        if badge:
            r_badge = p0.add_run()
            r_badge.text = f"[{badge}] "
            r_badge.font.size = Pt(11)
            r_badge.font.bold = True
            r_badge.font.color.rgb = C_ACCENT_BLUE

        r_title = p0.add_run()
        r_title.text = title
        r_title.font.size = Pt(14)
        r_title.font.bold = True
        r_title.font.color.rgb = C_NAVY_DARK

        # Items
        for item in items:
            p = tf.add_paragraph()
            p.space_before = Pt(8)
            p.level = 0
            
            if isinstance(item, tuple):
                bold_part, regular_part = item
                r_b = p.add_run()
                r_b.text = bold_part + " "
                r_b.font.bold = True
                r_b.font.size = Pt(11)
                r_b.font.color.rgb = C_NAVY
                
                r_r = p.add_run()
                r_r.text = regular_part
                r_r.font.size = Pt(11)
                r_r.font.color.rgb = C_TEXT_MUTED
            else:
                r = p.add_run()
                r.text = "• " + item
                r.font.size = Pt(11)
                r.font.color.rgb = C_TEXT_DARK

    # =========================================================================
    # SLIDE 1: TITLE SLIDE (Cover)
    # =========================================================================
    s1 = prs.slides.add_slide(blank_layout)
    add_bg(s1, C_NAVY_DARK)

    # Decorative header element
    dec = s1.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), Inches(1.0), Inches(2.5), Inches(0.08))
    dec.fill.solid()
    dec.fill.fore_color.rgb = C_ACCENT_ORANGE
    dec.line.color.rgb = C_ACCENT_ORANGE

    t_box = s1.shapes.add_textbox(Inches(0.8), Inches(1.3), Inches(11.733), Inches(3.2))
    tf1 = t_box.text_frame
    tf1.word_wrap = True

    p_super = tf1.paragraphs[0]
    r_super = p_super.add_run()
    r_super.text = "CAPSTONE PROJECT PROPOSAL DEFENSE  |  CSE 4XX"
    r_super.font.size = Pt(12)
    r_super.font.bold = True
    r_super.font.color.rgb = RGBColor(0x90, 0xCD, 0xF4)

    p_main = tf1.add_paragraph()
    p_main.space_before = Pt(10)
    r_main = p_main.add_run()
    r_main.text = "UniRoom-Live: A Multi-Tenant Real-Time Classroom Orchestration and Dynamic Academic Schedule Synchronization Platform"
    r_main.font.size = Pt(26)
    r_main.font.bold = True
    r_main.font.color.rgb = C_WHITE

    p_sub = tf1.add_paragraph()
    p_sub.space_before = Pt(12)
    r_sub = p_sub.add_run()
    r_sub.text = "Concurrency-Controlled Room Allocation, Push Synchronization, and Responsive Mobile Workflows"
    r_sub.font.size = Pt(13)
    r_sub.font.italic = True
    r_sub.font.color.rgb = RGBColor(0xCB, 0xD5, 0xE0)

    # Presenters Card on Cover
    p_card = s1.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(4.7), Inches(11.733), Inches(2.2))
    p_card.fill.solid()
    p_card.fill.fore_color.rgb = RGBColor(0x13, 0x2A, 0x4A)
    p_card.line.color.rgb = RGBColor(0x2B, 0x4C, 0x7E)

    t_pres = s1.shapes.add_textbox(Inches(1.1), Inches(4.85), Inches(11.133), Inches(1.9))
    tf_pres = t_pres.text_frame
    tf_pres.word_wrap = True

    p_inst = tf_pres.paragraphs[0]
    r_inst = p_inst.add_run()
    r_inst.text = "Department of Computer Science & Engineering  |  Uttara University, Dhaka, Bangladesh"
    r_inst.font.size = Pt(11)
    r_inst.font.bold = True
    r_inst.font.color.rgb = RGBColor(0xED, 0x89, 0x36)

    # 3 Presenters
    p_team = tf_pres.add_paragraph()
    p_team.space_before = Pt(10)
    
    r_t = p_team.add_run()
    r_t.text = "PROJECT TEAM (3 PRESENTERS):\n"
    r_t.font.bold = True
    r_t.font.size = Pt(10)
    r_t.font.color.rgb = C_WHITE

    p_mems = tf_pres.add_paragraph()
    p_mems.space_before = Pt(4)
    r_m1 = p_mems.add_run()
    r_m1.text = "• Speaker 1: [Member 1 Name - ID: XXXXXX] (Intro, Problem & Objectives)\n"
    r_m1.font.size = Pt(10.5)
    r_m1.font.color.rgb = RGBColor(0xE2, 0xE8, 0xF0)

    r_m2 = p_mems.add_run()
    r_m2.text = "• Speaker 2: [Member 2 Name - ID: XXXXXX] (Scope, Methodology, Architecture & OCC)\n"
    r_m2.font.size = Pt(10.5)
    r_m2.font.color.rgb = RGBColor(0xE2, 0xE8, 0xF0)

    r_m3 = p_mems.add_run()
    r_m3.text = "• Speaker 3: [Member 3 Name - ID: XXXXXX] (Workflows, CR Suite, Verification & Future)"
    r_m3.font.size = Pt(10.5)
    r_m3.font.color.rgb = RGBColor(0xE2, 0xE8, 0xF0)

    # =========================================================================
    # SLIDE 2: PRESENTATION AGENDA & SPEAKER ROADMAP
    # =========================================================================
    s2 = prs.slides.add_slide(blank_layout)
    add_bg(s2)
    add_header(s2, "Presentation Road-Map & Speaker Roles", "Presentation Structure", "All Speakers")

    add_card(s2, 0.8, 1.8, 3.6, 5.0, "PART 1: THE FOUNDATION", [
        ("Presenter:", "Speaker 1"),
        ("Focus Areas:", "Motivation & Goals"),
        ("1. Introduction:", "Context & higher education landscape"),
        ("2. Problem Statement:", "The 5 core campus friction points"),
        ("3. System Overview:", "UniRoom-Live 2.0 at a glance"),
        ("4. Objectives:", "Primary & technical aims (starting with 'To')"),
        ("Handover Cue:", "Passes floor to Speaker 2 for System Design"),
    ], badge="SPEAKER 1", border_color=C_BLUE)

    add_card(s2, 4.86, 1.8, 3.6, 5.0, "PART 2: ARCHITECTURE & METHOD", [
        ("Presenter:", "Speaker 2"),
        ("Focus Areas:", "Design & Technical Engine"),
        ("5. Project Scope:", "In-Scope modules vs. Out-of-Scope limits"),
        ("6. Methodology:", "Agile/Scrum 8-Sprint framework"),
        ("7. System Architecture:", "Decoupled Three-Tier structure"),
        ("8. Data & Concurrency:", "Relational model & OCC formula"),
        ("Handover Cue:", "Passes floor to Speaker 3 for Execution"),
    ], badge="SPEAKER 2", border_color=C_ACCENT_TEAL)

    add_card(s2, 8.93, 1.8, 3.6, 5.0, "PART 3: EXECUTION & OUTCOMES", [
        ("Presenter:", "Speaker 3"),
        ("Focus Areas:", "Workflows, QA & Future"),
        ("9. Core Workflows:", "Routine sync & dynamic room release"),
        ("10. CR Attendance Suite:", "Keypad logger & direct SMS"),
        ("11. Client Responsiveness:", "360px viewport optimization"),
        ("12. Verification & Testing:", "Jest, load tests & UAT metrics"),
        ("13. Conclusion & Future:", "Campus impact & Q&A session"),
    ], badge="SPEAKER 3", border_color=C_ACCENT_ORANGE)

    # =========================================================================
    # SLIDE 3: BACKGROUND & CONTEXT (SPEAKER 1)
    # =========================================================================
    s3 = prs.slides.add_slide(blank_layout)
    add_bg(s3)
    add_header(s3, "Background & Academic Context in Higher Education", "1. Introduction", "Speaker 1")

    add_card(s3, 0.8, 1.8, 5.7, 5.0, "The Modern University Reality", [
        ("High Campus Density:", "Multi-shift academic programs, shared computer labs, and hundreds of daily classes across separate buildings."),
        ("Dynamic Timetable Nature:", "Schedules constantly change due to make-up lectures, faculty reassignments, and student club workshops."),
        ("Physical Room Scarcity:", "Classrooms are in high demand; static reservations fail to reflect true live usage."),
        ("The Communication Void:", "Decentralized notices lead to student disorientation and wasted faculty time."),
    ], badge="CAMPUS DYNAMICS")

    add_card(s3, 6.8, 1.8, 5.7, 5.0, "Evolution of Schedule Communication", [
        ("Phase 1: Notice Boards (Static):", "Paper printouts on campus walls; obsolete the moment an instructor rescheduled."),
        ("Phase 2: PDF Routine Files (Unsynchronized):", "Distributed via portals; difficult to read on mobile and quickly outdated."),
        ("Phase 3: Social Media Chats (Fragmented):", "WhatsApp/Messenger groups prone to message floods, rumors, and missed alerts."),
        ("The Need for UniRoom-Live:", "An authoritative, real-time, concurrency-controlled single source of truth."),
    ], badge="HISTORICAL SHIFT")

    # =========================================================================
    # SLIDE 4: PROBLEM STATEMENT (SPEAKER 1)
    # =========================================================================
    s4 = prs.slides.add_slide(blank_layout)
    add_bg(s4)
    add_header(s4, "Problem Statement: 5 Core Campus Friction Points", "2. Problem Statement", "Speaker 1")

    add_card(s4, 0.8, 1.8, 5.7, 2.35, "1. Schedule Anarchy & Rumors", [
        ("Decentralized Chatter:", "Rescheduling notices get lost in social media groups."),
        ("Consequence:", "Students commute needlessly for cancelled classes."),
    ], badge="ISSUE 1", border_color=C_ACCENT_ORANGE)

    add_card(s4, 6.8, 1.8, 5.7, 2.35, "2. Room Collisions & Double-Booking", [
        ("Uncoordinated Makeups:", "Two batches book or occupy the same room at the same time."),
        ("Consequence:", "Class disruption, lost lecture hours, and administrative chaos."),
    ], badge="ISSUE 2", border_color=C_ACCENT_ORANGE)

    add_card(s4, 0.8, 4.45, 3.65, 2.45, "3. Ghost Occupancy", [
        ("Locked Empty Rooms:", "Classes ending early leave rooms marked 'Occupied'."),
        ("Resource Waste:", "Other batches cannot use empty spaces."),
    ], badge="ISSUE 3")

    add_card(s4, 4.83, 4.45, 3.65, 2.45, "4. CR Administrative Burden", [
        ("Manual Roll-Calls:", "CRs write absent IDs on paper scraps."),
        ("Error-Prone SMS:", "Manually typing 10-digit IDs into SMS."),
    ], badge="ISSUE 4")

    add_card(s4, 8.86, 4.45, 3.65, 2.45, "5. Lack of Concurrency & Audit", [
        ("Race Conditions:", "Naive databases permit simultaneous claims."),
        ("No Accountability:", "Zero audit logs for schedule overrides."),
    ], badge="ISSUE 5")

    # =========================================================================
    # SLIDE 5: SYSTEM OVERVIEW (SPEAKER 1)
    # =========================================================================
    s5 = prs.slides.add_slide(blank_layout)
    add_bg(s5)
    add_header(s5, "UniRoom-Live: Centralized Academic Hub", "1. Introduction (Overview)", "Speaker 1")

    add_card(s5, 0.8, 1.8, 3.6, 5.0, "Presentation Client Tier", [
        ("Flutter Cross-Platform:", "Single codebase compiling to Android, iOS & Web."),
        ("60 FPS Smooth UI:", "Reactive Provider state management."),
        ("Universal Layout:", "Responsive down to 360px viewport widths."),
        ("Offline First:", "Local timetable caching for instant access without data connection."),
    ], badge="CLIENT LAYER", border_color=C_BLUE)

    add_card(s5, 4.86, 1.8, 3.6, 5.0, "API & Orchestration Tier", [
        ("NestJS Framework:", "Modular TypeScript enterprise architecture."),
        ("Pre-Flight Conflict Engine:", "Triple-check algorithm for rooms, faculty, and batches."),
        ("RBAC Security:", "Strict 5-tier role enforcement via JWT."),
        ("Notification Engine:", "Instant Firebase Cloud Messaging (FCM) & SMTP alerts."),
    ], badge="BACKEND LAYER", border_color=C_BLUE)

    add_card(s5, 8.93, 1.8, 3.6, 5.0, "Data & Event Persistence", [
        ("Neon Serverless PostgreSQL:", "ACID-compliant relational storage."),
        ("Prisma ORM:", "Type-safe database queries and automated migrations."),
        ("Atomic Transactions:", "Row-level locks ensuring zero double-booking."),
        ("Multi-Tenant Hierarchy:", "Isolates campuses, buildings, departments, and batches."),
    ], badge="DATA LAYER", border_color=C_BLUE)

    # =========================================================================
    # SLIDE 6: OBJECTIVES (SPEAKER 1)
    # =========================================================================
    s6 = prs.slides.add_slide(blank_layout)
    add_bg(s6)
    add_header(s6, "Project Objectives (All Starting with 'To')", "3. Objectives", "Speaker 1")

    add_card(s6, 0.8, 1.8, 11.733, 1.35, "PRIMARY STRATEGIC OBJECTIVE", [
        ("To", "design and implement a multi-tenant, cloud-synchronized real-time classroom orchestration and dynamic academic schedule management platform that unifies students, faculty members, and campus administrators under a single authoritative digital ecosystem.")
    ], badge="CORE OBJECTIVE", bg_color=RGBColor(0xEE, 0xF6, 0xFC), border_color=C_BLUE)

    add_card(s6, 0.8, 3.35, 5.7, 3.6, "Specific Technical Objectives (Part A)", [
        ("To", "develop an Optimistic Concurrency Control (OCC) and atomic transactional booking engine to eliminate race conditions and prevent double-booking."),
        ("To", "formulate an intelligent pre-flight conflict detection algorithm that cross-evaluates room, faculty, and batch schedules prior to database save."),
        ("To", "engineer an automated push notification pipeline using FCM and SMTP to broadcast schedule updates instantly."),
        ("To", "implement a dynamic room release mechanism that liberates unoccupied physical spaces, eliminating 'ghost occupancy'."),
    ], badge="TECHNICAL AIMS")

    add_card(s6, 6.8, 3.35, 5.7, 3.6, "Specific Technical Objectives (Part B)", [
        ("To", "build a streamlined CR attendance utility featuring a rapid keypad and automatic SMS generation to eliminate manual transcription."),
        ("To", "establish a secure, multi-tenant Role-Based Access Control (RBAC) security architecture powered by JWT and Bcrypt hashing."),
        ("To", "create a high-performance cross-platform Flutter client optimized down to 360px viewport widths with offline routine caching."),
        ("To", "evaluate system latency, reliability, and usability through load simulations and stakeholder trials at Uttara University."),
    ], badge="OPERATIONAL AIMS")

    # =========================================================================
    # SLIDE 7: PROJECT SCOPE (SPEAKER 2)
    # =========================================================================
    s7 = prs.slides.add_slide(blank_layout)
    add_bg(s7)
    add_header(s7, "Project Scope: Core Deliverables vs. Future Boundaries", "4. Project Scope", "Speaker 2")

    add_card(s7, 0.8, 1.8, 5.7, 5.0, "In-Scope Deliverables (Version 2.0)", [
        ("Multi-Tenant Hierarchy:", "Institutions, Campuses, Buildings, Rooms, Departments, Batches."),
        ("Master Timetable Engine:", "Weekly routine authoring with multi-parameter filtering."),
        ("Pre-Flight Conflict Matrix:", "Triple-check validation (Room, Faculty, Batch)."),
        ("Live Vacancy & OCC Booking:", "Real-time room search and concurrency-safe locking."),
        ("Dynamic Early Release:", "Early checkout workflow liberating unused spaces."),
        ("CR Attendance Suite:", "Rapid absent roll keypad & automatic SMS generator."),
        ("5-Tier RBAC & JWT:", "Granular permission security across all user roles."),
        ("Responsive Flutter Client:", "Universal rendering optimized for 360px+ mobile screens."),
    ], badge="IN-SCOPE", border_color=C_ACCENT_TEAL)

    add_card(s7, 6.8, 1.8, 5.7, 5.0, "Out-of-Scope (Future Iterations)", [
        ("IoT Smart Door Hardware:", "Direct electronic solenoid locks and microcontroller turnstiles (Earmarked for Version 3.0 IoT Integration)."),
        ("Biometric Scanner Terminals:", "Dedicated physical optical fingerprint or infrared facial recognition hardware."),
        ("Commercial Payment Gateway:", "Financial billing for commercial venue rentals."),
        ("Automated AI Schedule Synthesis:", "Algorithmic routine generation via genetic algorithms (conflict detection is active; AI generation is future work)."),
        ("Focus Rationale:", "Ensures production-grade software stability, data integrity, and rapid student adoption."),
    ], badge="OUT-OF-SCOPE", border_color=C_BORDER)

    # =========================================================================
    # SLIDE 8: DEVELOPMENT METHODOLOGY (SPEAKER 2)
    # =========================================================================
    s8 = prs.slides.add_slide(blank_layout)
    add_bg(s8)
    add_header(s8, "Development Methodology: Agile / Scrum Lifecycle", "5. Methodology (SDLC)", "Speaker 2")

    add_card(s8, 0.8, 1.8, 11.733, 1.3, "Agile Framework Overview (8 Sprints / 16 Weeks)", [
        ("Iterative Cadence:", "Two-week sprints combining backlog prioritization, continuous implementation, and stakeholder reviews with Uttara University CRs and faculty."),
        ("Why Agile:", "Academic workflows require real-world feedback loops to eliminate UI bottlenecks and refine edge-case scheduling conflict handling.")
    ], badge="FRAMEWORK RATIONALE", border_color=C_BLUE)

    add_card(s8, 0.8, 3.3, 5.7, 3.7, "Sprint Timeline: Phases 1 to 4", [
        ("Sprint 1 (Weeks 1-2):", "Domain modeling, ER diagram, Prisma schema & repository setup."),
        ("Sprint 2 (Weeks 3-4):", "Multi-tenant auth, Bcrypt hashing, JWT tokens & role guards."),
        ("Sprint 3 (Weeks 5-6):", "Routine engine, timetable filters & pre-flight conflict validator."),
        ("Sprint 4 (Weeks 7-8):", "Live room search, atomic reservation & early-release engine."),
    ], badge="SPRINTS 1 - 4")

    add_card(s8, 6.8, 3.3, 5.7, 3.7, "Sprint Timeline: Phases 5 to 8", [
        ("Sprint 5 (Weeks 9-10):", "CR attendance keypad, statistics widget & telephony SMS engine."),
        ("Sprint 6 (Weeks 11-12):", "Flutter UI refactoring, 360px overflow fixes & offline caching."),
        ("Sprint 7 (Weeks 13-14):", "Firebase Cloud Messaging (FCM) & SMTP event-driven alerts."),
        ("Sprint 8 (Weeks 15-16):", "Concurrency stress testing, Jest integration suites, UAT & rollout."),
    ], badge="SPRINTS 5 - 8")

    # =========================================================================
    # SLIDE 9: SYSTEM ARCHITECTURE (SPEAKER 2)
    # =========================================================================
    s9 = prs.slides.add_slide(blank_layout)
    add_bg(s9)
    add_header(s9, "System Architecture: Decoupled Three-Tier Design", "5. Methodology (Architecture)", "Speaker 2")

    add_card(s9, 0.8, 1.8, 3.6, 5.0, "Tier 1: Presentation Layer", [
        ("Flutter Cross-Platform:", "Android, iOS, PWA, Desktop."),
        ("Adaptive Layout Builders:", "Dynamic scaling, flexible flex, safe-area wrappers."),
        ("Provider State Engine:", "Reactive, decoupled UI state synchronization."),
        ("Local Persistence:", "Encrypted token store and cached routine JSON."),
    ], badge="CLIENT TIER", border_color=C_BLUE)

    add_card(s9, 4.86, 1.8, 3.6, 5.0, "Tier 2: Application / API Layer", [
        ("NestJS Framework:", "TypeScript enterprise modular controller/service structure."),
        ("Guards & Pipes:", "JwtAuthGuard, RolesGuard, class-validator DTO validation."),
        ("Concurrency Manager:", "Atomic transaction boundaries (prisma.$transaction)."),
        ("Notification Dispatcher:", "FCM push notifications and Nodemailer SMTP."),
    ], badge="API TIER", border_color=C_BLUE)

    add_card(s9, 8.93, 1.8, 3.6, 5.0, "Tier 3: Data & Messaging Layer", [
        ("Neon PostgreSQL:", "ACID transactions with row-level locking isolation."),
        ("Prisma ORM:", "Type-safe database client and automated migrations."),
        ("Firebase Cloud Messaging:", "Device token registry & push broadcasts."),
        ("Cellular Telephony:", "Device-native SMS intent integration."),
    ], badge="DATA TIER", border_color=C_BLUE)

    # =========================================================================
    # SLIDE 10: RELATIONAL DATA MODEL & MULTI-TENANCY (SPEAKER 2)
    # =========================================================================
    s10 = prs.slides.add_slide(blank_layout)
    add_bg(s10)
    add_header(s10, "Relational Data Model & Multi-Tenancy Hierarchy", "5. Methodology (Data Modeling)", "Speaker 2")

    add_card(s10, 0.8, 1.8, 5.7, 5.0, "Multi-Tenant Domain Entities", [
        ("1. Institutions:", "Top-level tenant isolation (Uttara University)."),
        ("2. Campuses & Buildings:", "Physical infrastructure distribution."),
        ("3. Rooms:", "Floor indexing, capacity limits, and categorization."),
        ("4. Departments & Programs:", "Academic structures (CSE, EEE, BBA)."),
        ("5. Batches & Sections:", "Student cohorts linked to department nodes."),
        ("6. Users & Roles:", "SUPERADMIN, ADMIN, FACULTY, CR, STUDENT."),
        ("7. Routines & Bookings:", "Master schedule slots vs. dynamic reservations."),
        ("8. AttendanceLogs:", "CR absent rolls and session headcounts."),
    ], badge="SCHEMA ENTITIES")

    add_card(s10, 6.8, 1.8, 5.7, 5.0, "Pre-Flight Conflict Detection Matrix", [
        ("Automated Triple-Check Algorithm:", "Every routine creation or edit is cross-examined against three simultaneous dimensions:"),
        ("1. Room Collision:", "Is the physical room already booked for another batch during this time window?"),
        ("2. Faculty Collision:", "Is the course instructor assigned to another lecture or campus simultaneously?"),
        ("3. Batch Collision:", "Does the student cohort have another overlapping lecture or laboratory session?"),
        ("Result:", "Zero schedule overlaps can be written to the database."),
    ], badge="CONFLICT VALIDATION", border_color=C_ACCENT_TEAL)

    # =========================================================================
    # SLIDE 11: CONCURRENCY CONTROL (OCC) (SPEAKER 2)
    # =========================================================================
    s11 = prs.slides.add_slide(blank_layout)
    add_bg(s11)
    add_header(s11, "Optimistic Concurrency Control (OCC) Booking Engine", "5. Methodology (Concurrency)", "Speaker 2")

    add_card(s11, 0.8, 1.8, 11.733, 1.5, "The Mathematical Overlap Detection Formula", [
        ("Collision Condition:", "A collision exists if and only if: (ExistingStartTime < RequestedEndTime) AND (ExistingEndTime > RequestedStartTime)"),
        ("Atomic Isolation:", "All reservation requests run inside an atomic database transaction. If any overlap exists on an approved, unreleased booking, the request is immediately rejected with HTTP 409 Conflict.")
    ], badge="OCC EQUATION", bg_color=RGBColor(0xEE, 0xF6, 0xFC), border_color=C_BLUE)

    add_card(s11, 0.8, 3.5, 5.7, 3.5, "How Naive Systems Fail (Race Condition)", [
        ("Step 1:", "CR A and CR B both view Room 402 as empty."),
        ("Step 2:", "Both submit booking requests within 10ms of each other."),
        ("Step 3 (Naive):", "Both queries see '0 rows', and both write 'APPROVED'."),
        ("Disaster:", "Double-booking occurs! Two cohorts fight over Room 402."),
    ], badge="WITHOUT OCC", border_color=C_ACCENT_ORANGE)

    add_card(s11, 6.8, 3.5, 5.7, 3.5, "How UniRoom-Live Prevents Collisions", [
        ("Step 1:", "Both requests enter isolated Prisma transactions."),
        ("Step 2:", "Transaction A secures the reservation atomically."),
        ("Step 3 (UniRoom):", "Transaction B detects the active booking and aborts."),
        ("Success:", "CR A gets Room 402; CR B receives an instant 409 Conflict alert."),
    ], badge="WITH UNIROOM OCC", border_color=C_ACCENT_TEAL)

    # =========================================================================
    # SLIDE 12: TECHNOLOGY STACK (SPEAKER 2)
    # =========================================================================
    s12 = prs.slides.add_slide(blank_layout)
    add_bg(s12)
    add_header(s12, "Technology Stack & Engineering Justifications", "5. Methodology (Tech Stack)", "Speaker 2")

    add_card(s12, 0.8, 1.8, 3.6, 5.0, "Frontend & State", [
        ("Flutter 3.x / Dart:", "High-performance native rendering across mobile & web."),
        ("Provider (^6.1.0):", "Lightweight, reactive state tree without boilerplate overhead."),
        ("url_launcher:", "Hardware telephony intent for direct SMS creation."),
        ("Responsive Layout:", "Fluid flex, safe-area and 360px viewport optimization."),
    ], badge="CLIENT STACK")

    add_card(s12, 4.86, 1.8, 3.6, 5.0, "Backend & Logic", [
        ("NestJS 10.x:", "Enterprise TypeScript architecture, DI, and modular structure."),
        ("Prisma ORM 5.x:", "Declarative schema modeling and compile-time type safety."),
        ("Passport-JWT & Bcrypt:", "Stateless, horizontally scalable authentication."),
        ("FCM Admin SDK:", "Reliable cross-platform push notification delivery."),
    ], badge="SERVER STACK")

    add_card(s12, 8.93, 1.8, 3.6, 5.0, "Database & DevOps", [
        ("PostgreSQL (Neon):", "Cloud serverless relational database with ACID safety."),
        ("Row-Level Locking:", "Guarantees zero concurrent reservation collisions."),
        ("Git & GitHub:", "Strict version control and branch management."),
        ("Render Cloud Platform:", "Automated CI/CD build and container deployment."),
    ], badge="INFRASTRUCTURE")

    # =========================================================================
    # SLIDE 13: CORE WORKFLOWS (SPEAKER 3)
    # =========================================================================
    s13 = prs.slides.add_slide(blank_layout)
    add_bg(s13)
    add_header(s13, "Core Workflows: Routine Sync & Early Room Release", "Execution & Workflows", "Speaker 3")

    add_card(s13, 0.8, 1.8, 5.7, 5.0, "Dynamic Routine Synchronization", [
        ("1. Multi-Parameter Filtering:", "Students and instructors filter routines by day, semester, batch, and instructor ID."),
        ("2. Instant Update Propagation:", "When an admin or instructor modifies a routine, affected student devices receive FCM background push alerts."),
        ("3. Local Offline Caching:", "Timetable data is cached in SQLite/SharedPreferences, allowing consultation during campus network outages."),
        ("4. Zero Confusion:", "Students always possess an authoritative, verified schedule on their smartphones."),
    ], badge="ROUTINE WORKFLOW", border_color=C_BLUE)

    add_card(s13, 6.8, 1.8, 5.7, 5.0, "Early Room Release Engine", [
        ("The Problem Solved:", "Lectures ending 30 minutes early traditionally leave rooms marked 'Occupied' on paper."),
        ("One-Tap Early Checkout:", "Instructors or booking CRs tap 'Release Room' upon early conclusion."),
        ("Instant State Flip:", "The backend flags the reservation as released and recalculates vacancy immediately."),
        ("Campus Efficiency:", "Vacant physical rooms become bookable instantly by other waiting batches."),
    ], badge="ROOM RELEASE", border_color=C_ACCENT_TEAL)

    # =========================================================================
    # SLIDE 14: CR ATTENDANCE SUITE (SPEAKER 3)
    # =========================================================================
    s14 = prs.slides.add_slide(blank_layout)
    add_bg(s14)
    add_header(s14, "Class Representative (CR) Attendance & SMS Suite", "Execution & Workflows", "Speaker 3")

    add_card(s14, 0.8, 1.8, 5.7, 5.0, "Rapid Numerical Absent Keypad", [
        ("Custom Keypad Interface:", "CR taps absent student roll numbers rapidly during 5-minute lecture breaks."),
        ("Batch ID Auto-Completion:", "Prefixes (e.g., 223030...) are applied automatically; CR enters only the last 2 digits."),
        ("Instant Absent Chips:", "Recorded absent IDs appear as interactive chips that can be tapped to remove."),
        ("Headcount Summary:", "Real-time calculation of Total Students, Present Count, Absent Count, and Attendance Percentage."),
    ], badge="RAPID KEYPAD")

    add_card(s14, 6.8, 1.8, 5.7, 5.0, "Automated Cellular SMS Integration", [
        ("Zero Manual Typing:", "Eliminates the error-prone task of transcribing student IDs into phones."),
        ("Hardware Intent Launch:", "UniRoom launches the native Android/iOS SMS app with a single tap."),
        ("Pre-Populated Message:", "Course Code, Date, Batch, and comma-separated Absent Rolls are pre-filled."),
        ("Instructor Telephony:", "Faculty phone number is automatically looked up and set as the recipient."),
        ("Zero Gateway Costs:", "Uses standard SIM SMS allowances without requiring third-party SMS aggregator fees."),
    ], badge="TELEPHONY SMS", border_color=C_ACCENT_ORANGE)

    # =========================================================================
    # SLIDE 15: MOBILE RESPONSIVENESS (SPEAKER 3)
    # =========================================================================
    s15 = prs.slides.add_slide(blank_layout)
    add_bg(s15)
    add_header(s15, "Mobile Client: Ultra-Responsive 360px Optimization", "Execution & UI/UX", "Speaker 3")

    add_card(s15, 0.8, 1.8, 5.7, 5.0, "The 360px Width Engineering Challenge", [
        ("The Challenge:", "Budget and entry-level smartphones used by university students feature narrow 360px displays."),
        ("Previous Failures:", "Text clipped, routine tables overflowed off-screen, and bottom sheets caused RenderFlex errors."),
        ("Comprehensive Solution:", "Redesigned all dialogs and screens with responsive constraints:"),
        ("• Wrap Widgets & Flexible Rows:", "Prevent horizontal row pixel overflow."),
        ("• SingleChildScrollView Wrappers:", "Prevent keyboard popup overflow errors."),
        ("• Scaled Typography & Touch Targets:", "Ensure accessibility on compact displays."),
    ], badge="RESPONSIVE UI")

    add_card(s15, 6.8, 1.8, 5.7, 5.0, "Verified Screen Dimension Matrix", [
        ("Compact Smartphones (360px x 640px):", "Zero yellow/black render overflow stripes; full button usability."),
        ("Standard Smartphones (390px - 412px):", "Optimal typography spacing and fluid card proportions."),
        ("Tablets & Desktops (768px - 1080p):", "Adaptive grid multi-column layout with responsive sidebars."),
        ("Dark & Light Mode Support:", "High-contrast academic theme optimized for outdoor campus sunlight."),
    ], badge="VERIFIED VIEWPORTS", border_color=C_BLUE)

    # =========================================================================
    # SLIDE 16: TESTING & QA (SPEAKER 3)
    # =========================================================================
    s16 = prs.slides.add_slide(blank_layout)
    add_bg(s16)
    add_header(s16, "Testing, Verification & Quality Assurance", "5. Methodology (QA & Results)", "Speaker 3")

    add_card(s16, 0.8, 1.8, 5.7, 2.35, "1. Automated Unit & Integration Testing", [
        ("Jest Framework:", "Full test coverage across NestJS controllers, services, and conflict calculation algorithms."),
        ("Validation Pipes:", "Enforces strict payload constraints on every incoming REST request."),
    ], badge="JEST SUITE", border_color=C_BLUE)

    add_card(s16, 6.8, 1.8, 5.7, 2.35, "2. Concurrency Load Verification", [
        ("Simulated Race Conditions:", "Scripted concurrent requests targeting the same room at the exact same millisecond."),
        ("Result:", "Exactly one reservation approved; all competing requests received HTTP 409 Conflict."),
    ], badge="CONCURRENCY LOAD", border_color=C_ACCENT_TEAL)

    add_card(s16, 0.8, 4.45, 5.7, 2.35, "3. Cross-Device Usability Testing", [
        ("Viewport Inspections:", "Tested on physical devices and emulators (360px, 390px, 412px, 768px)."),
        ("Result:", "Zero visual clipping; 100% of dialogs and sheets scroll smoothly."),
    ], badge="DEVICE TESTING")

    add_card(s16, 6.8, 4.45, 5.7, 2.35, "4. User Acceptance Testing (UAT)", [
        ("Uttara University Trials:", "Tested by student cohorts, CRs, and faculty members."),
        ("Speed Metrics:", "Room booked in < 10 seconds; attendance logged in < 30 seconds."),
    ], badge="UAT METRICS")

    # =========================================================================
    # SLIDE 17: IMPACT & FUTURE ROADMAP (SPEAKER 3)
    # =========================================================================
    s17 = prs.slides.add_slide(blank_layout)
    add_bg(s17)
    add_header(s17, "Anticipated Impact & Future Evolution Roadmap", "6. Conclusion & Future Scope", "Speaker 3")

    add_card(s17, 0.8, 1.8, 5.7, 5.0, "Anticipated Campus Contributions", [
        ("1. Zero Schedule Confusion:", "Authoritative, instant push alerts eliminate missed lectures and travel confusion."),
        ("2. Guaranteed Spatial Harmony:", "OCC booking prevents classroom collisions and embarrassment."),
        ("3. Maximized Room Utilization:", "Early checkout unlocks physical capacity, ending 'ghost occupancy'."),
        ("4. CR Time Savings:", "Rapid absent keypad and SMS generator save 10-15 minutes of class time daily."),
        ("5. Universal Accessibility:", "Accessible to all students on 360px+ smartphones."),
    ], badge="CAMPUS IMPACT", border_color=C_BLUE)

    add_card(s17, 6.8, 1.8, 5.7, 5.0, "Future Evolution Roadmap (V3.0+)", [
        ("IoT Smart Door Locks:", "Microcontroller relays (ESP32/RFID) automatically unlock room doors during active bookings."),
        ("Rotating QR Attendance:", "Cryptographic QR codes displayed on lecture projectors for instant self-verification."),
        ("AI Schedule Optimization:", "Genetic algorithms to auto-generate master semester routines based on room and faculty constraints."),
        ("ERP & LMS Integration:", "Bidirectional sync with Moodle, Canvas, and university registrar systems."),
    ], badge="FUTURE ROADMAP", border_color=C_ACCENT_TEAL)

    # =========================================================================
    # SLIDE 18: CONCLUSION & Q&A (ALL SPEAKERS)
    # =========================================================================
    s18 = prs.slides.add_slide(blank_layout)
    add_bg(s18, C_NAVY_DARK)

    # Header bar
    dec18 = s18.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), Inches(1.0), Inches(2.5), Inches(0.08))
    dec18.fill.solid()
    dec18.fill.fore_color.rgb = C_ACCENT_ORANGE
    dec18.line.color.rgb = C_ACCENT_ORANGE

    t_box18 = s18.shapes.add_textbox(Inches(0.8), Inches(1.3), Inches(11.733), Inches(2.5))
    tf18 = t_box18.text_frame
    tf18.word_wrap = True

    p18_sub = tf18.paragraphs[0]
    r18_sub = p18_sub.add_run()
    r18_sub.text = "UNIROOM-LIVE 2.0  |  CAPSTONE PROJECT PROPOSAL DEFENSE"
    r18_sub.font.size = Pt(12)
    r18_sub.font.bold = True
    r18_sub.font.color.rgb = RGBColor(0x90, 0xCD, 0xF4)

    p18_main = tf18.add_paragraph()
    p18_main.space_before = Pt(8)
    r18_main = p18_main.add_run()
    r18_main.text = "Thank You for Your Time & Attention!"
    r18_main.font.size = Pt(30)
    r18_main.font.bold = True
    r18_main.font.color.rgb = C_WHITE

    p18_desc = tf18.add_paragraph()
    p18_desc.space_before = Pt(8)
    r18_desc = p18_desc.add_run()
    r18_desc.text = "UniRoom-Live provides an enterprise-ready, concurrency-safe, real-time classroom orchestration foundation for modern tertiary institutions."
    r18_desc.font.size = Pt(13)
    r18_desc.font.italic = True
    r18_desc.font.color.rgb = RGBColor(0xCB, 0xD5, 0xE0)

    # Card with Q&A info
    qa_card = s18.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(4.3), Inches(11.733), Inches(2.6))
    qa_card.fill.solid()
    qa_card.fill.fore_color.rgb = RGBColor(0x13, 0x2A, 0x4A)
    qa_card.line.color.rgb = RGBColor(0x2B, 0x4C, 0x7E)

    t_qa = s18.shapes.add_textbox(Inches(1.1), Inches(4.45), Inches(11.133), Inches(2.3))
    tf_qa = t_qa.text_frame
    tf_qa.word_wrap = True

    p_qa_head = tf_qa.paragraphs[0]
    r_qa_head = p_qa_head.add_run()
    r_qa_head.text = "QUESTIONS & ANSWERS (Q&A) SESSION — FLOOR OPEN TO EVALUATION COMMITTEE"
    r_qa_head.font.size = Pt(12)
    r_qa_head.font.bold = True
    r_qa_head.font.color.rgb = RGBColor(0xED, 0x89, 0x36)

    p_qa_team = tf_qa.add_paragraph()
    p_qa_team.space_before = Pt(10)
    r_qa_team = p_qa_team.add_run()
    r_qa_team.text = "All 3 Team Members are Ready for Technical Inquiries:\n"
    r_qa_team.font.bold = True
    r_qa_team.font.size = Pt(11)
    r_qa_team.font.color.rgb = C_WHITE

    p_qa_roles = tf_qa.add_paragraph()
    p_qa_roles.space_before = Pt(4)
    r_r1 = p_qa_roles.add_run()
    r_r1.text = "• Speaker 1: Ready for inquiries regarding Problem Definition, Objectives, User Needs & Administrative Policy.\n"
    r_r1.font.size = Pt(10)
    r_r1.font.color.rgb = RGBColor(0xE2, 0xE8, 0xF0)

    r_r2 = p_qa_roles.add_run()
    r_r2.text = "• Speaker 2: Ready for inquiries regarding Backend Architecture, PostgreSQL OCC, Prisma ORM & Conflict Algorithms.\n"
    r_r2.font.size = Pt(10)
    r_r2.font.color.rgb = RGBColor(0xE2, 0xE8, 0xF0)

    r_r3 = p_qa_roles.add_run()
    r_r3.text = "• Speaker 3: Ready for inquiries regarding Flutter Client Responsiveness (360px), CR SMS Integration & Testing Results."
    r_r3.font.size = Pt(10)
    r_r3.font.color.rgb = RGBColor(0xE2, 0xE8, 0xF0)

    prs.save(output_path)
    print(f"Successfully generated PowerPoint presentation: {output_path}")

if __name__ == "__main__":
    out_file = os.path.join(os.path.abspath("."), "PRESENTATION_SLIDES.pptx")
    create_deck(out_file)
