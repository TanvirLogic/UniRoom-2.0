# 🎓 UniRoom-Live 2.0 Backend Masterclass
## Chapter 7: Email, Push Notifications & Metadata Management

A backend isn't just a database repository; it is a **real-time communication engine**.
When a room becomes free, when a class is rescheduled, or when a student signs up, the backend proactively reaches out through:
1. **Email (SMTP)**: Sending 6-digit cryptographic verification and password reset PINs.
2. **Push Notifications (Firebase Cloud Messaging - FCM)**: Instant mobile device alerts with custom heads-up banners and vibration.
3. **Metadata Feeds (Universities & Batches)**: Powering reactive cascading dropdowns.

This chapter breaks down `EmailService`, `PushNotificationService`, and the `Meta` modules line by line.

---

## 1. SMTP Email Service: `src/modules/email/email.service.ts`

When a student registers, they receive an email with their verification PIN. How does this work?

### 1. Transporter Initialization Line by Line:
```typescript
11: constructor(private readonly configService: ConfigService) {
12:   const host = this.configService.get<string>('SMTP_HOST', 'smtp.gmail.com');
13:   const port = Number(this.configService.get<number>('SMTP_PORT', 465));
14:   const secure = this.configService.get<string>('SMTP_SECURE', 'true') === 'true' || port === 465;
15:   const rawUser = this.configService.get<string>('SMTP_USER', '');
16:   const rawPass = this.configService.get<string>('SMTP_PASS', '');
17:   const user = rawUser.replace(/["']/g, '').trim();
18:   const pass = rawPass.replace(/["'\s]/g, '').trim();
19:   this.emailFrom = this.configService.get<string>('EMAIL_FROM', 'UniRoom-Live <no-reply@uniroom.live>');
```
- Reads SMTP credentials from `.env`.
- **Port 465 with `secure: true`**: Uses **SMTPS (SSL/TLS)** encryption directly from connection start, preventing man-in-the-middle eavesdropping.
- Sanitizes quotes or spaces from passwords (`pass.replace(/["'\s]/g, '')`).

```typescript
21:   if (user && pass) {
22:     this.transporter = nodemailer.createTransport({
23:       host,
24:       port,
25:       secure,
26:       auth: { user, pass },
27:     });
28:     this.logger.log(`[EmailService] Configured SMTP transporter with host ${host}:${port}`);
29:   } else {
30:     this.logger.warn('[EmailService] SMTP credentials not set. Falling back to console logging.');
31:   }
32: }
```
- **The Developer Fallback Superpower**:
  If a developer tests the app locally without setting up Gmail App Passwords, `this.transporter` remains `null`.
  Instead of crashing, the service prints the 6-digit PIN in large bold ASCII letters right into the server terminal! Developers can test registration and verification completely offline!

```typescript
43:   if (!this.transporter) {
44:     this.logger.warn(
45:       `\n=======================================================\n[DEVELOPMENT EMAIL VERIFICATION PIN]\nTo: ${to} (${fullName})\nVerification PIN: [ ${pin} ]\nExpires in: 10 minutes\n=======================================================`,
46:     );
47:     return true;
48:   }
```

### 2. Beautiful HTML Email Templates:
`buildVerificationTemplate()` and `buildPasswordResetTemplate()`:
- Renders responsive, inline-CSS email layouts.
- Displays the 6-digit PIN inside a large, dashed-border blue/red box with `letter-spacing: 8px` and `font-size: 32px` so students can read it effortlessly on both mobile and desktop screens.
- Includes clear expiration warnings: `"This PIN is valid for 10 minutes"`.

---

## 2. Firebase Push Notification Service: `push-notification.service.ts`

When a class is cancelled or a room is freed, sending emails to 60 students is too slow—students need to know **immediately**.
UniRoom-Live uses **Google Firebase Cloud Messaging (FCM)**.

### 1. Flexible Multi-Environment Initialization:
```typescript
23: private initializeFirebase() {
24:   try {
25:     const existingApps = getApps();
26:     if (existingApps.length > 0) {
27:       this.firebaseApp = existingApps[0]!;
28:       this.isInitialized = true;
29:       return;
30:     }
```
- Prevents re-initializing Firebase if already running (which throws errors in Node.js).

```typescript
35:   if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
36:     serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
37:   } else if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
38:     const decoded = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf8');
39:     serviceAccount = JSON.parse(decoded);
40:   } else {
41:     const keyPath = path.resolve(process.cwd(), 'firebase-service-account.json');
42:     if (fs.existsSync(keyPath)) {
43:       serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
44:     }
45:   }
```
- **Enterprise Cloud Ready**:
  - Locally: Reads `firebase-service-account.json` from the backend directory.
  - On Docker / Kubernetes / Render / Heroku: Reads from base64 or raw JSON environment variables, avoiding having to commit sensitive Google secret keys to GitHub!

### 2. The Topic-Based Architecture:
Instead of tracking 10,000 individual phone device tokens in the database, UniRoom-Live uses **FCM Topics**:

#### Section Broadcast: `sendToSectionTopic()`
```typescript
async sendToSectionTopic(department: string, batch: string, section: string, notification: NotificationPayload) {
  const rawTopic = `dept_${department}_batch_${batch}_sec_${section}`;
  const topic = this.sanitizeTopic(rawTopic);
  return this.sendToTopic(topic, notification);
}
```
- When a student signs up as **SWE, Batch 68, Section B**, their mobile app subscribes to topic:
  `dept_swe_batch_68_sec_b`
- When their class is cancelled, the backend sends **ONE single message** to that topic. Google's global data centers instantly deliver it to all phones in that section in under **500 milliseconds**!

#### CR Broadcast: `sendToCrTopic()`
```typescript
async sendToCrTopic(department: string, notification: NotificationPayload) {
  const rawTopic = `dept_${department}_crs`;
  const topic = this.sanitizeTopic(rawTopic);
  return this.sendToTopic(topic, notification);
}
```
- When a room is freed, an alert is sent to `dept_swe_crs`. All CRs in the department receive the notification:
  *"Room 5030 is Now Free! 🟢 Tap to claim for your batch."*

#### Faculty Direct Broadcast: `sendToFacultyTopic()`
```typescript
async sendToFacultyTopic(facultyInitials: string, notification: NotificationPayload) {
  const rawTopic = `faculty_${facultyInitials.toLowerCase()}`;
  const topic = this.sanitizeTopic(rawTopic);
  return this.sendToTopic(topic, notification);
}
```
- When a CR schedules an extra class or reserves a lab with teacher "DNS", an alert is dispatched directly to `faculty_dns`. The teacher's phone receives:
  *"Room 5030 Reserved for Your Class 🔔 Batch 68 Sec B scheduled SWE-321."*

### 3. Android High-Priority Heads-Up Alerts:
```typescript
android: {
  priority: 'high',
  notification: {
    channelId: 'uniroom_classes',
    priority: 'max',
    defaultSound: true,
    defaultVibrateTimings: true,
  },
}
```
- Ensures the phone wakes up from sleep and shows a prominent heads-up banner with sound and vibration even if the app is in the background or closed!

### 4. Asynchronous Error Isolation Pattern:
```typescript
this.pushNotificationService.sendToSectionTopic(deptCode, batch, section, payload)
  .catch((err) => {
    this.logger.warn(`Failed to broadcast push: ${err.message}`);
  });
```
- **Why this is critical for reliability**: Network requests to third-party services (like Firebase or Apple APNs) can fail if there is an internet drop.
- By attaching `.catch(...)`, we isolate the failure: the database transaction has already succeeded, the room is safely booked, and the API responds with `200 OK` rather than crashing and rolling back the user's booking!

---

## 3. Metadata & Cascading Dropdowns: `src/modules/meta/` & `universities/`

When a student opens the registration or profile screen, the app displays four cascading dropdowns:
```
1. Select University   ──► Uttara University (UU)
2. Select Department   ──► Computer Science & Engineering (CSE)
3. Select Batch        ──► Batch 68
4. Select Section      ──► Section B
```
How does the app know which sections belong to Batch 68?

### `MetaService.getRegistrationOptions()`
In `meta.service.ts`:
```typescript
async getRegistrationOptions() {
  const universities = await this.prisma.university.findMany({
    where: { isActive: true },
    select: {
      id: true,
      name: true,
      code: true,
      departments: {
        select: {
          id: true,
          name: true,
          code: true,
          academicBatches: {
            where: { isActive: true },
            select: {
              id: true,
              name: true,
              sections: true,
            },
            orderBy: { name: 'desc' },
          },
        },
        orderBy: { code: 'asc' },
      },
    },
    orderBy: { name: 'asc' },
  });

  return { universities };
}
```
- A single, deeply nested query returns the entire hierarchy in one network request!
- When the user selects "Uttara University", the Flutter app filters its departments in memory. When they select "CSE", it filters batches. When they select "68", it populates sections `["A", "B", "C"]`.
- Fast, silky-smooth, zero loading lag!

---

### Multi-Tenant University & Batch Administration:
In `src/modules/universities/universities.service.ts` & `src/modules/meta/meta.service.ts`:

#### 1. Managing Universities: `createUniversity()`
```typescript
79: async createUniversity(dto: CreateUniversityDto) {
80:   const normalizedCode = dto.code.trim().toUpperCase();
81:   const existing = await this.prisma.university.findUnique({
82:     where: { code: normalizedCode },
83:   });
84:   if (existing) throw new ConflictException(`University '${normalizedCode}' already exists`);
85: 
86:   return this.prisma.university.create({
87:     data: {
88:       name: dto.name.trim(),
89:       code: normalizedCode,
90:       domain: dto.domain?.trim().toLowerCase(),
91:       logoUrl: dto.logoUrl?.trim(),
92:       operatingDays: dto.operatingDays,
93:       isActive: dto.isActive ?? true,
94:     },
95:   });
96: }
```
- Restricts duplicate institution codes (`UU`, `DU`, `NSU`).
- Stores `operatingDays` (e.g. `[MON, TUE, WED, THU]`) so routines for weekend institutions adapt automatically.

#### 2. Managing Departments: `createDepartment()`
```typescript
180: async createDepartment(dto: CreateDepartmentDto) {
181:   const normalizedCode = dto.code.trim().toUpperCase();
182:   const university = await this.prisma.university.findUnique({ where: { id: dto.universityId } });
183:   if (!university) throw new NotFoundException('University not found');
184: 
185:   return this.prisma.department.create({
186:     data: {
187:       universityId: dto.universityId,
188:       name: dto.name.trim(),
189:       code: normalizedCode,
190:     },
191:   });
192: }
```
- Enforces composite uniqueness: `@@unique([universityId, code])`. Two universities can both have a `"CSE"` department, but one university cannot have two conflicting departments with the same code!

#### 3. Managing Dynamic Cohorts: `MetaService.createBatch()`
```typescript
async createBatch(dto: CreateBatchDto) {
  return this.prisma.academicBatch.create({
    data: {
      departmentId: dto.departmentId,
      name: dto.name.trim(),
      sections: dto.sections.map((s) => s.trim().toUpperCase()),
      isActive: true,
    },
  });
}
```
- Populates allowed sections (`["A", "B", "C", "D"]`) so students selecting their section during registration are prevented from entering non-existent sections.

---

## 4. Next Chapter: The Virtual Classroom Hub

You have now mastered communications and metadata feeds.
Next, let's explore **Chapter 8**: how UniRoom-Live enables teachers and CRs to publish classroom notices and lecture materials, with intelligent cross-cohort fan-out push broadcasting!

---

*Continue to [Chapter 8: Virtual Classroom Hub & Dynamic Cross-Cohort Fan-Out](./08_CLASSROOM_HUB_AND_ACADEMIC_FEEDS.md).*
