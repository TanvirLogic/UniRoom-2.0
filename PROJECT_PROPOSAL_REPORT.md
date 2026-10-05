# ACADEMIC PROJECT PROPOSAL REPORT

**UTTARA UNIVERSITY**  
**School of Science and Engineering**  
**Department of Computer Science & Engineering (CSE)**  
**Course:** Capstone Project / Project & Thesis (CSE 4XX)  

---

# Project Title:
## UniRoom-Live: A Real-Time Classroom Booking and Smart Routine Management System for Universities

**Subtitle:** *Solving Daily Routine Confusion, Classroom Clashes, and Attendance Headaches in Campus Life*

---

| **Field** | **Details** |
| :--- | :--- |
| **Course Title** | Project & Thesis / Capstone Project (CSE 4XX) |
| **Department** | Department of Computer Science & Engineering (CSE) |
| **University** | Uttara University, Dhaka, Bangladesh |
| **Project Domain** | Web & Mobile Application, Database Systems |
| **Target Users** | Students, Class Representatives (CRs), Teachers, and Department Admins |
| **Platforms** | Android Mobile App, iOS, and Web Admin Panel |

---

## TABLE OF CONTENTS

1. [Introduction](#1-introduction)
   - 1.1 Background and Context
   - 1.2 System Overview
   - 1.3 Target Users and Their Roles
2. [Problem Statement](#2-problem-statement)
   - 2.1 Routine Confusion from WhatsApp and Facebook Groups
   - 2.2 Classroom Clashes and Double-Booking
   - 2.3 Empty Classrooms Staying Locked ("Ghost Occupancy")
   - 2.4 Heavy Burden and Mistakes in CR Attendance Management
   - 2.5 No Protection Against Simultaneous Bookings in Naive Systems
3. [Objectives](#3-objectives)
   - 3.1 Primary Objective
   - 3.2 Specific Technical Objectives
4. [Project Scope](#4-project-scope)
   - 4.1 In-Scope Features (What the System Includes)
   - 4.2 Out-of-Scope (What is Reserved for Future Versions)
5. [Methodology](#5-methodology)
   - 5.1 Software Development Life Cycle (SDLC) - Agile/Scrum
   - 5.2 Three-Tier System Architecture
   - 5.3 How the System Stops Double-Booking (Concurrency Protection)
   - 5.4 Tools and Technologies Used
   - 5.5 Testing and Validation
6. [Conclusion](#6-conclusion)
   - 6.1 Project Contributions and Benefits
   - 6.2 Future Improvements
7. [References](#7-references)

---

## 1. INTRODUCTION

### 1.1 Background and Context
In our university life at Uttara University, managing classes and finding empty rooms is a daily challenge. Every semester, thousands of students attend classes in different buildings and floors. However, academic schedules do not stay the same throughout the semester. Teachers frequently take extra classes to complete the syllabus, reschedule classes due to personal or departmental meetings, or move classes to computer labs for practical work. Also, students often need empty classrooms for group study, club meetings, and project presentations.

Currently, universities in Bangladesh manage these changes through manual notices or informal social media chat groups such as WhatsApp and Facebook Messenger. While WhatsApp is common, it creates serious confusion. When a teacher tells the Class Representative (CR) that a class is cancelled or moved to another room, the CR posts it in the group chat. Very often, students who are traveling on the bus through Dhaka traffic do not have mobile data turned on, or the important notice gets lost under hundreds of normal chat messages. As a result, students travel a long way to campus only to discover that their class was cancelled hours ago.

### 1.2 System Overview
**UniRoom-Live** is designed and built to solve these daily campus headaches. It is a modern, real-time web and mobile application that acts as the single, official source of truth for university routines and classroom availability. Instead of checking multiple PDF files or asking friends on WhatsApp, students and teachers can simply open the app on their phones and immediately see today's live schedule.

The system consists of three main parts that work together smoothly:
1. **Mobile Application (Flutter):** A fast and user-friendly mobile app for Android and iOS. It works on all phone screen sizes (including small budget phones with 360px width) and allows students to check routines even when offline.
2. **Central Server (NestJS):** The brain of the system that manages user accounts, checks that no two batches book the same room at the same time, and sends push notifications to phones.
3. **Database (PostgreSQL):** A reliable relational database that safely stores all room details, weekly routine slots, bookings, and attendance records.

### 1.3 Target Users and Their Roles
UniRoom-Live is built for the entire campus community, with clear roles for each type of user:
- **Students:** They can see their daily class routine, check which rooms are currently empty on campus to sit and study, and receive instant push notifications if any class is rescheduled or cancelled.
- **Class Representatives (CRs):** They can find empty classrooms and book them for make-up lectures, quickly record student attendance during class, and automatically send a formatted SMS to the course teacher in one tap.
- **Teachers (Faculty Members):** They can view their daily teaching routine, release a booked classroom early if their class finishes ahead of time, and receive accurate student attendance lists directly on their phones.
- **Department Coordinators & Admins:** They can upload the semester master routine, manage classroom details, and ensure that no two batches are scheduled in the same room.

---

## 2. PROBLEM STATEMENT

Through our daily experience as university students and discussions with teachers and Class Representatives, we identified five major problems that happen every day on campus:

### 2.1 Routine Confusion from WhatsApp and Facebook Groups
When a teacher reschedules a class from 8:45 AM to 11:25 AM, the news is sent by phone call to the CR, who writes a text message in the batch WhatsApp or Messenger group. This traditional method fails repeatedly. Students miss the notification because of poor network or muted groups, messages get buried under casual chatter, and students arrive at university unnecessarily. There is no single official app where students can check the confirmed schedule.

### 2.2 Classroom Clashes and Double-Booking
When two different teachers or CRs plan to take an extra class or quiz at the same time, they both look for an empty room and enter it. Because there is no live central booking system, two whole batches (for example, Batch 60 and Batch 62) often show up at the exact same classroom at the same time. This leads to arguments, embarrassment, and lost lecture time.

### 2.3 Empty Classrooms Staying Locked ("Ghost Occupancy")
On the official paper routine, a class slot is usually 80 or 160 minutes long. If a teacher finishes class 30 minutes early, or cancels class for the day, the room remains officially marked as "Occupied". Other students who desperately need an empty room to practice coding, prepare for presentations, or study quietly cannot enter because everyone assumes the room is busy. This wastes valuable campus resources.

### 2.4 Heavy Burden and Mistakes in CR Attendance Management
In our university, Class Representatives have to take attendance during short 5-minute class breaks. The CR has to write down long 10-digit student ID numbers on small scraps of paper. Then, after class, the CR has to manually type all those absent ID numbers one by one into their phone's SMS app and send it to the course teacher. This takes 10 to 15 minutes of personal time every class, causes typing mistakes, and delays attendance submission.

### 2.5 No Protection Against Simultaneous Bookings in Naive Systems
Basic website forms and paper sheets do not have concurrency control. If two CRs click "Book Room" for the same room within the same second, traditional naive database queries create two approved bookings for the exact same room. Furthermore, there is no audit trail to see who booked a room or why a schedule was changed.

---

## 3. OBJECTIVES

The objectives of this project are directly designed to solve the problems mentioned above. In strict accordance with academic project standards, every objective starts with the word **"To"**:

### 3.1 Primary Objective
- **To** design and develop a real-time, user-friendly classroom booking and academic routine management platform called UniRoom-Live that brings students, teachers, and university administration into a single, synchronized digital environment.

### 3.2 Specific Technical Objectives
- **To** build an automatic room-locking system using database transactions so that two users can never double-book the same physical classroom at the same time.
- **To** create a smart routine checker that checks room availability, teacher schedules, and student batch times before saving, completely preventing timetable clashes.
- **To** implement an instant push notification system using Firebase Cloud Messaging (FCM) that automatically alerts students on their smartphones whenever a class is cancelled, rescheduled, or relocated.
- **To** develop an early room release feature that allows teachers and CRs to release a room with one tap when class finishes early, making the room immediately available for other students.
- **To** build a rapid attendance keypad for Class Representatives (CRs) that allows quick entry of absent student roll numbers and automatically generates a ready-to-send SMS for the teacher.
- **To** establish a secure login system with five user privilege levels (Super Admin, Department Admin, Teacher, CR, Student) using secure tokens (JWT) and encrypted passwords (Bcrypt).
- **To** create a cross-platform mobile application in Flutter that works smoothly and responsively on all Android and iOS smartphones, specifically optimized for small 360px width screens with offline routine caching.
- **To** test and evaluate the complete system through real-world usability trials and load tests at Uttara University to verify that it is fast, simple, and reliable for daily campus use.

---

## 4. PROJECT SCOPE

### 4.1 In-Scope Features (What the System Includes)
UniRoom-Live covers the following key features and modules:
1. **Complete Campus Hierarchy:** Organizes the university into Campuses, Buildings, Floors, Classrooms, Computer Labs, Departments, and Batches.
2. **Master Routine Management:** Allows department admins to manage weekly class schedules with simple filters by Day, Batch, Section, and Teacher.
3. **Timetable PDF Parser:** Allows admins to upload the official university routine PDF (e.g. `routine_cse.pdf`) and automatically extracts all class slots into the database without needing manual typing.
4. **Real-Time Room Vacancy Finder:** Students and CRs can search and see which rooms are currently empty on campus right now or in the next period.
5. **Safe Room Booking with Conflict Protection:** Authorized CRs and teachers can book empty classrooms for extra classes with guaranteed protection against double-booking.
6. **One-Tap Early Room Release:** Enables occupants to release a room immediately if class finishes early, changing the room status back to 'Available'.
7. **CR Attendance Keypad & Auto-SMS:** Provides a custom numerical keypad for CRs to record absent roll numbers in seconds and opens the phone's native SMS app with the teacher's number and absent list pre-filled.
8. **Mobile Push Notifications:** Sends background push alerts directly to students' phone lock screens when any class is changed or cancelled.
9. **Responsive Mobile Client with Offline Support:** A lightweight Flutter app that saves the weekly routine on the device, allowing students to check routine even without internet.

### 4.2 Out-of-Scope (What is Reserved for Future Versions)
To keep the project focused, practical, and completed on time within our university semester, the following hardware and experimental features are kept for future versions:
- **Physical Smart Door Hardware:** Electronic magnetic door locks and RFID turnstiles on classroom doors (planned for Version 3.0 IoT integration).
- **Biometric Face Recognition Machines:** Wall-mounted infrared face scanners (our system focuses on the software mobile solution).
- **Payment Gateway Integration:** Money collection or room rental fees (our system is strictly for free internal university academic use).
- **Full AI Automatic Timetable Generation:** Fully generating a semester routine from scratch using genetic algorithms (our system checks and verifies routines; full generation is reserved for future research).

---

## 5. METHODOLOGY

We followed a clear, practical software engineering approach to design, build, and test UniRoom-Live.

### 5.1 Software Development Life Cycle (SDLC) - Agile/Scrum
We chose the Agile/Scrum development process with 2-week sprints across a 16-week project timeline. We selected Agile rather than traditional Waterfall because university routines have many real-life exceptions—such as 2-period lab classes, joint sections, and small phone screens—which required regular testing and feedback from real students and CRs.

- **Sprint 1 (Weeks 1-2):** Requirements gathering, student interviews, and database schema design.
- **Sprint 2 (Weeks 3-4):** User authentication, password encryption (Bcrypt), and token security (JWT).
- **Sprint 3 (Weeks 5-6):** Weekly routine manager and pre-flight clash checking algorithm.
- **Sprint 4 (Weeks 7-8):** Real-time room vacancy finder, booking engine, and early room checkout.
- **Sprint 5 (Weeks 9-10):** CR attendance keypad, statistics calculations, and automated phone SMS generator.
- **Sprint 6 (Weeks 11-12):** Flutter mobile UI improvements, fixing layout on 360px small screens, and offline caching.
- **Sprint 7 (Weeks 13-14):** Firebase Cloud Messaging (FCM) push notifications and email service.
- **Sprint 8 (Weeks 15-16):** Final load testing, fixing bugs, usability trials at Uttara University, and documentation.

### 5.2 Three-Tier System Architecture
UniRoom-Live is built using a clean 3-Tier Architecture so that each part of the system is independent and easy to maintain:
1. **Client Layer (Presentation):** The mobile app is built with Flutter (Dart) and the admin portal with React/Vite. The mobile app uses Provider for smooth state management.
2. **API Layer (Business Logic):** Built with NestJS (TypeScript). It handles all business logic, checks user permissions, verifies room availability, and coordinates notifications.
3. **Data Layer (Persistence):** PostgreSQL database hosted on Neon Cloud, managed using Prisma ORM for safe, strongly-typed database queries.

### 5.3 How the System Stops Double-Booking (Concurrency Protection)
To make sure that two users can never book the same room at the same time, UniRoom-Live uses atomic database transactions. When a user wants to book Room 402 for a timeslot between Start Time ($T_s$) and End Time ($T_e$), the server checks existing bookings:

$$\text{Collision Rule} \iff (T_{\text{start}}^{\text{existing}} < T_e) \land (T_{\text{end}}^{\text{existing}} > T_s)$$

If any existing approved booking overlaps with these times, the transaction immediately cancels and returns an error (*"Room is already booked for this time"*). Exactly one booking succeeds, making double-booking mathematically impossible.

### 5.4 Tools and Technologies Used

| **Component** | **Technology** | **Why We Chose It** |
| :--- | :--- | :--- |
| **Mobile Frontend** | **Flutter (Dart)** | Single codebase that runs fast on both Android and iOS with clean UI. |
| **State Management**| **Provider** | Simple and reliable state management without unnecessary complex code. |
| **Backend Framework**| **NestJS (Node.js/TS)**| Organized modular structure, very secure, and easy to maintain. |
| **Database ORM** | **Prisma ORM** | Type-safe database tool that prevents SQL injection mistakes. |
| **Database** | **PostgreSQL** | Industry-standard relational database with strong transaction safety. |
| **Push Notifications**| **Firebase (FCM)** | Delivers instant push notifications to Android and iOS phones for free. |
| **CR SMS Feature** | **url_launcher (Intent)** | Directly opens native phone SMS app without requiring paid SMS gateway APIs. |

### 5.5 Testing and Validation
We tested the project thoroughly in four ways:
1. **Code Testing:** Automated tests to verify that room conflict checks and routine filters work accurately.
2. **Concurrency Load Test:** Simulated two booking requests sent at the exact same millisecond. Exactly one succeeded, proving zero double-booking.
3. **Small Screen Testing (360px):** Tested on budget Android phones with narrow 360px screen width. Fixed all layout overflows so that no text or button gets cut off.
4. **User Testing with Students & CRs:** Real students at Uttara University tested the app. Booking a room took less than 10 seconds, and taking class attendance took under 30 seconds.

---

## 6. CONCLUSION

### 6.1 Project Contributions and Benefits
UniRoom-Live provides practical, everyday solutions to real problems faced by students, teachers, and university staff in Bangladesh. By replacing scattered WhatsApp notices and static paper routines with a unified digital platform, the project achieves five clear benefits:
1. **No More Missed Classes:** Students receive instant push notifications if a class is cancelled, saving unnecessary travel through Dhaka traffic.
2. **No More Room Clashes:** The system mathematically prevents double-booking, ensuring that makeup lectures happen without arguments.
3. **Maximum Use of Campus Rooms:** Early room release allows empty classrooms to be used by other students instead of sitting locked.
4. **Huge Time Savings for CRs:** Class Representatives can take attendance and send an SMS to the teacher in under 30 seconds instead of 15 minutes.
5. **Accessible on Budget Phones:** The app works smoothly on all smartphones, including small 360px budget devices, ensuring equal access for all students.

### 6.2 Future Improvements
After successful implementation at Uttara University, the platform can be expanded in the following ways:
- **Smart Door Locks (IoT):** Connecting the app to electronic door locks so classrooms unlock automatically when a class begins.
- **QR Code Attendance:** Displaying a secure QR code on the classroom projector so students can scan and mark their own attendance.
- **Integration with University ERP:** Connecting directly with the university student portal for automatic semester enrollment sync.

---

## 7. REFERENCES

1. **Sommerville, I. (2015).** *Software Engineering* (10th ed.). Pearson Education.
2. **Elmasri, R., & Navathe, S. B. (2016).** *Fundamentals of Database Systems* (7th ed.). Pearson.
3. **Fowler, M. (2002).** *Patterns of Enterprise Application Architecture*. Addison-Wesley Professional.
4. **NestJS Documentation. (2024).** *NestJS - A progressive Node.js framework*. Available at: https://docs.nestjs.com
5. **Flutter Documentation. (2024).** *Flutter - Build apps for any screen*. Google LLC. Available at: https://docs.flutter.dev
6. **Prisma Documentation. (2024).** *Next-generation ORM for Node.js and TypeScript*. Available at: https://www.prisma.io/docs
7. **PostgreSQL Global Development Group. (2024).** *PostgreSQL 16 Documentation*. Available at: https://www.postgresql.org/docs
8. **Firebase Documentation. (2024).** *Firebase Cloud Messaging (FCM)*. Google LLC. Available at: https://firebase.google.com/docs/cloud-messaging
9. **Uttara University. (2024).** *Academic Rules and Facility Management Guidelines*. Uttara University, Dhaka, Bangladesh.

---
*Report End — UniRoom-Live Capstone Project Proposal*
