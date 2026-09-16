# Architectural Decisions & Technical Rationale (প্রজেক্টের সিদ্ধান্তের কারণ ও বিশ্লেষণ) 🏛️📖

> **Document Version**: 1.0.0 (Bilingual English & Bengali)  
> **Location**: `docs/architecture_rationale.md`  
> **Purpose**: A comprehensive guide explaining **every architectural decision, technology choice, and design trade-off** in both English and Bangla so you can master, explain, and defend every aspect of UniRoom-Live 2.0 in any technical interview or viva defense.

---

# Table of Contents / সূচিপত্র
1. [Decision 1: Monorepo Structure vs Multi-Repo (মনোরেপো বনাম মাল্টি-রেপো)](#decision-1-monorepo-structure-vs-multi-repo)
2. [Decision 2: NestJS + TypeScript vs Express / Django / FastAPI (ব্যাকএন্ড চয়েস)](#decision-2-nestjs--typescript-vs-express--django--fastapi)
3. [Decision 3: PostgreSQL 16 + Prisma vs MongoDB / Firestore (রিলেশনাল বনাম নো-এসকিউএল)](#decision-3-postgresql-16--prisma-vs-mongodb--firestore)
4. [Decision 4: Redis 7 for In-Memory Caching & Pub/Sub (রেডিস ক্যাশ ও মেসেজ ব্রোকার)](#decision-4-redis-7-for-in-memory-caching--pubsub)
5. [Decision 5: Flutter + Riverpod 2.x vs Provider / BLoC (স্টেট ম্যানেজমেন্ট)](#decision-5-flutter--riverpod-2x-vs-provider--bloc)
6. [Decision 6: Super Admin Master Routine vs Section CR Daily Overrides (রুটিন নিয়ন্ত্রণ)](#decision-6-super-admin-master-routine-vs-section-cr-daily-overrides)
7. [Decision 7: Multi-Tenant Logical Partitioning vs Separate Databases (মাল্টি-টেন্যান্ট ডেটাবেজ ডিজাইন)](#decision-7-multi-tenant-logical-partitioning-vs-separate-databases)
8. [Decision 8: Dual-Mode Timetable Ingestion: Built-in AI vs External Prompt + JSON (ডুয়াল-মোড ইনজেশন)](#decision-8-dual-mode-timetable-ingestion-built-in-ai-vs-external-prompt--json)
9. [Decision 9: Sequence of Docker Compose (কেন ডকার কম্পোজ Task 1.3-এ আনা হলো?)](#decision-9-sequence-of-docker-compose-setup)
10. [Decision 10: 100% Zero-Cost ($0/Month) Production Hosting (সম্পূর্ণ ফ্রি ক্লাউড স্ট্র্যাটেজি)](#decision-10-100-zero-cost-0month-production-hosting)

---

## Decision 1: Monorepo Structure vs Multi-Repo

### 🇬🇧 English Technical Rationale:
- **Context**: UniRoom-Live consists of a backend API server, database migrations, and a cross-platform mobile client.
- **Why Monorepo (`backend/` + `mobile/` + `docs/`)**:
  1. **Atomic Commits**: API schema changes (e.g., adding `building_name` to `Room`) and the corresponding Flutter model/UI updates can be committed and verified in the exact same Git commit.
  2. **Single Source of Truth**: Documentation, architecture decision records (ADRs), and contract tests reside in one place.
  3. **No Version Drift**: In multi-repo setups, backend and mobile repos frequently drift out of sync during active development.
- **Trade-offs Considered**: Monorepos require clean folder separation and independent CI/CD triggers, which we solve cleanly using path-filtered GitHub Actions.

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কেন মনোরেপো?**: 
  - আলাদা আলাদা রিপোজিটরি বানালে ব্যাকএন্ডের এপিআই পরিবর্তন এবং মোবাইল অ্যাপের কোড পরিবর্তনের মধ্যে ভার্সন মিসম্যাচ হয়ে যায়। 
  - মনোরেপোতে একটি মাত্র গিটহাবে ব্যাকএন্ড (`backend/`) এবং মোবাইল (`mobile/`) আলাদা ফোল্ডারে সুশৃঙ্খল থাকে। একটি কমিটেই ডাটাবেজ পরিবর্তন এবং মোবাইল স্ক্রিনের কোড একসাথে ট্র্যাক করা যায়।

---

## Decision 2: NestJS + TypeScript vs Express / Django / FastAPI

### 🇬🇧 English Technical Rationale:
- **Context**: The backend requires strict modularity, automated OpenAPI/Swagger generation, dependency injection, and WebSocket gateways.
- **Why NestJS with TypeScript**:
  1. **Architectural Discipline**: Unlike Express (which is unopinionated and frequently leads to "spaghetti code" across teams), NestJS enforces Angular-like architectural discipline with Modules, Controllers, and Services.
  2. **Built-in Dependency Injection (IoC Container)**: Crucial for testability and mocking services during unit testing.
  3. **Native TypeScript & Type Safety**: Eliminates runtime type errors (`TypeError: Cannot read property of undefined`).
  4. **Native Swagger/OpenAPI 3.0**: DTO decorators (`@IsString()`, `@ApiProperty()`) automatically generate live Swagger documentation without maintaining separate YAML files.
  5. **Top-Tier Enterprise Demand**: NestJS is the dominant Node.js enterprise framework across European and US tech firms.

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কেন এক্সপ্রেস বা পাইথন নয়, NestJS + TypeScript?**:
  - এক্সপ্রেস (Express.js) এ কোনো বাঁধাধরা নিয়ম নেই, ফলে প্রজেক্ট বড় হলে একেক ডেভেলপার একেক স্টাইলে কোড লিখে জগাখিচুড়ি বানিয়ে ফেলে।
  - NestJS-এ মডিউলার আর্কিটেকচার এবং ডিপেন্ডেন্সি ইনজেকশন বিল্ট-ইন থাকে, যা কোডকে ক্লিন ও টেস্ট করা সহজ করে।
  - টাইপস্ক্রিপ্ট ব্যবহারের কারণে কোনো ভেরিয়েবলের টাইপ ভুল হলে রানটাইমে ক্র্যাশ করার বদলে কোড লেখার সময়ই এরর ধরা পড়ে।
  - কন্ট্রোলারে কোড লিখলেই ব্রাউজারে স্বয়ংক্রিয়ভাবে প্রফেশনাল Swagger API ডকুমেন্টেশন তৈরি হয়ে যায়।

---

## Decision 3: PostgreSQL 16 + Prisma vs MongoDB / Firestore

### 🇬🇧 English Technical Rationale:
- **Context**: Room scheduling, timetable conflict prevention, and multi-tenant hierarchies are fundamentally relational.
- **Why PostgreSQL over NoSQL (MongoDB / Firebase Firestore)**:
  1. **Relational Integrity & Foreign Keys**: `University ➔ Department ➔ Building ➔ Room ➔ ScheduleSlot ➔ Faculty`. Foreign keys prevent orphaned or invalid relations.
  2. **ACID Transactions & Optimistic Locking**: Room status transitions require serializable transactions and atomic version checks to mathematically eliminate double-booking race conditions. NoSQL databases struggle with multi-document cross-collection transactions at scale.
  3. **Advanced Indexing**: PostgreSQL supports composite B-Tree indexing, partial indexes (`WHERE is_active = true`), and JSONB columns for flexible tenant settings.
- **Why Prisma ORM**:
  1. **Type-Safe Database Queries**: Prisma auto-generates TypeScript types directly from `schema.prisma`. A query returns typed entities, preventing runtime column typos.
  2. **Declarative Migrations**: `prisma migrate dev` automatically tracks and versions SQL schema migrations.

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কেন NoSQL (Firebase/Mongo) বাদ দিয়ে PostgreSQL + Prisma?**:
  - বিশ্ববিদ্যালয়, ডিপার্টমেন্ট, রুম এবং রুটিন ডাটাগুলো গভীরভাবে রিলেশনাল (সম্পর্কযুক্ত)। মঙ্গোডিবি বা ফায়ারবেসে ফরেন কি (Foreign Key) এনফোর্স করা যায় না, ফলে ভুল ডাটা ঢুকে যাওয়ার ঝুঁকি থাকে।
  - যদি দুজন CR একই সেকেন্ডে একই রুম বুক করার চেষ্টা করে, তবে PostgreSQL-এর ACID ট্রানজ্যাকশন নিশ্চিত করে একজনই পাবে, অন্যজন কনফ্লিক্ট এরর পাবে। নো-এসকিউএলে রেস কন্ডিশন হ্যান্ডেল করা অত্যন্ত জটিল।
  - প্রিজমা (Prisma) ORM ব্যবহারের ফলে আমাদের কাঁচা SQL লিখতে হবে না; ডাটাবেজের প্রতিটা টেবিল সরাসরি টাইপস্ক্রিপ্ট অবজেক্ট হিসেবে পাওয়া যাবে।

---

## Decision 4: Redis 7 for In-Memory Caching & Pub/Sub

### 🇬🇧 English Technical Rationale:
- **Context**: 50,000 students frequently check room availability during morning peak hours (8:30 AM - 11:30 AM).
- **Why Redis**:
  1. **Sub-2ms Latency**: PostgreSQL disk/SSD queries take 15–50ms. Redis in-memory lookups return in under 2ms.
  2. **Database Protection**: Prevents 10,000 concurrent students from saturating PostgreSQL connection pools.
  3. **Redis Pub/Sub & WebSocket Adapter**: When room status changes, Redis publishes an event that immediately broadcasts across all active WebSocket gateway instances.
  4. **Redis TTL for Self-Healing Leases**: Expired room bookings are tracked via TTL keys or Sorted Sets (`ZADD`), auto-releasing rooms when class ends without manual CR action.

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কেন রেডিস দরকার?**:
  - হাজার হাজার শিক্ষার্থী যখন একসাথে অ্যাপে ঢুকে রুম খালি আছে কি না দেখবে, তখন বারবার মেইন ডাটাবেজে কুয়েরি চালালে ডাটাবেজ স্লো হয়ে যাবে।
  - রেডিস হলো মেমোরি (RAM) ভিত্তিক ক্যাশ, যা মাত্র ২ মিলি-সেকেন্ডে ডাটা ফিরিয়ে দেয়।
  - একজন CR রুমের স্ট্যাটাস পরিবর্তন করলেই রেডিসের Pub/Sub দিয়ে সাব-সেকেন্ডে সব কানেক্টেড মোবাইলে লাইভ আপডেট চলে যায়।

---

## Decision 5: Flutter + Riverpod 2.x vs Provider / BLoC

### 🇬🇧 English Technical Rationale:
- **Context**: The mobile client must be reactive, cross-platform (Android, iOS, Web), clean, and battery-efficient.
- **Why Riverpod 2.x over Provider & BLoC**:
  1. **Provider's Limitation**: Provider depends on `BuildContext`, coupling state management to the widget tree and risking runtime `ProviderNotFoundException`.
  2. **Riverpod's Compile-Time Safety**: Riverpod is globally scoped, compile-safe, and independent of Flutter's UI tree.
  3. **`AsyncValue` State Machine**: Riverpod's `AsyncValue` natively models `loading`, `data`, and `error` states, forcing declarative UI handling and eliminating unexpected crashes.
  4. **BLoC's Overhead**: While BLoC is great, it requires excessive boilerplate (Events, States, Blocs) for simple CRUD operations. Riverpod 2.x (`AsyncNotifier`) gives the exact same predictability with 50% less boilerplate.
  5. **Auto-Dispose & Lifecycle**: Riverpod automatically disposes inactive providers when screens unmount, preventing memory leaks.

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কেন Provider বা BLoC এর বদলে Riverpod 2.x?**:
  - আগের প্রোটোটাইপে ব্যবহৃত `Provider`-এ `BuildContext` লাগত, যা UI এর বাইরে বিজনেস লজিক লেয়ারে পাওয়া কঠিন। তাছাড়া রানটাইমে কোনো প্রোভাইডার না পেলে অ্যাপ ক্র্যাশ করত।
  - রিভারপড (Riverpod 2.x) কম্পাইল টাইমে গ্যারান্টি দেয় যে স্টেট সেফ আছে। এর `AsyncValue` প্যাটার্ন লোডিং, ডাটা এবং এরর স্টেটকে চমৎকারভাবে হ্যান্ডেল করে।
  - BLoC-এ প্রচুর অতিরিক্ত কোড (Boilerplate) লিখতে হয়, যা রিভারপডে অনেক কম কোডে আরও পরিষ্কারভাবে করা যায়।

---

## Decision 6: Super Admin Master Routine vs Section CR Daily Overrides

### 🇬🇧 English Technical Rationale:
- **Context**: Managing semester timetables vs daily classroom operational realities.
- **Why Super Admin controls Master Ingestion exclusively**:
  1. **Institutional Data Integrity**: The semester routine is an institutional policy document. Permitting CRs to upload master routines creates severe risk of accidental data deletion, slot collisions, and cross-department corruption.
  2. **CR Operational Autonomy (Daily Overrides)**: CRs operate on the ground; they need the power to handle daily cancellations, make-up classes, and room shifts without touching the locked master schedule.
  3. **Self-Reverting Logic**: Daily overrides automatically expire at midnight, reverting back to the master weekly schedule seamlessly.

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কেন শুধু সুপার অ্যাডমিন মূল রুটিন আপলোড করবেন?**:
  - সেমিস্টারের মূল রুটিন হলো বিশ্ববিদ্যালয়ের অফিসিয়াল রুলস। কোনো সাধারণ CR যদি ভুলবশত পুরো ডিপার্টমেন্টের মাস্টার রুটিন পরিবর্তন করে ফেলে, পুরো ক্যাম্পাসে বিশৃঙ্খলা সৃষ্টি হবে।
  - তাই সুপার অ্যাডমিন মূল রুটিন লক করে রাখবেন।
  - CR-রা শুধু আজকের দিনের জন্য জরুরি মেক-আপ ক্লাস বা রুম শিফট (Daily Override) করতে পারবেন, যা রাত ১২টায় স্বয়ংক্রিয়ভাবে আবার মূল রুটিনে ফিরে যাবে।

---

## Decision 7: Multi-Tenant Logical Partitioning vs Separate Databases

### 🇬🇧 English Technical Rationale:
- **Context**: Supporting multiple universities and departments on the platform.
- **Why Logical Partitioning (Single PostgreSQL DB with `university_id` & `TenantGuard`)**:
  1. **Resource Efficiency ($0 Budget)**: Multi-database architectures (separate DB per university) require managing dozens of database instances, completely blowing through free-tier cloud limits.
  2. **Simplified Schema Migrations**: A single `prisma migrate deploy` updates all tenants simultaneously without needing complex migration orchestrators.
  3. **Zero Cross-Tenant Bleed via `TenantGuard`**: Security is enforced at the controller layer and Prisma query level by automatically binding `university_id` from the cryptographically signed JWT.

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কেন প্রতিটি ভার্সিটির জন্য আলাদা ডাটাবেজ না করে একটি সিঙ্গেল ডাটাবেজে টেন্যান্ট গার্ড ব্যবহার করা হলো?**:
  - প্রতিটি বিশ্ববিদ্যালয়ের জন্য আলাদা ডাটাবেজ তৈরি করলে সার্ভার খরচ অনেক বেড়ে যাবে এবং ফ্রিতে চালানো অসম্ভব হয়ে পড়বে।
  - তাই আমরা একটি সিঙ্গেল পোস্টগ্রেস ডাটাবেজে প্রতিটি টেবিলে `university_id` যুক্ত করেছি এবং ব্যাকএন্ডে **`TenantGuard`** দিয়ে কঠোর নিরাপত্তা নিশ্চিত করেছি। এক ভার্সিটির ইউজার কখনোই অন্য ভার্সিটির ডাটা দেখতে পারবে না।

---

## Decision 8: Dual-Mode Timetable Ingestion: Built-in AI vs External Prompt + JSON

### 🇬🇧 English Technical Rationale:
- **Context**: Department routines arrive as complex 5-page PDF files created with `aSc Timetables`.
- **Why Dual-Mode Ingestion (Graceful Degradation)**:
  1. **Mode A (Built-in Free Gemini Flash)**: Direct 1-click drag-and-drop ingestion within the admin portal for seamless user experience.
  2. **Mode B (External AI Prompt + JSON Uploader)**: If cloud AI quotas are temporarily exhausted, the Super Admin can click "Copy AI Prompt", paste the PDF into ChatGPT/Claude, and paste the returned JSON into the portal.
  3. **Human-in-the-Loop Validation**: Neither mode directly writes to production tables blindly. Both flow into an **Interactive Preview Table** for visual review and confirmation before committing an atomic bulk transaction.

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কেন ডুয়াল-মোড ইনজেশন (Direct AI + External JSON)?**:
  - রিয়েল-লাইফে ক্লাউড এআই-এর কোটা কখনো শেষ হতে পারে বা নেটওয়ার্ক ফেইল করতে পারে।
  - তাই ব্যাকএন্ডে যেমন নিজস্ব ফ্রি জেমিনি এআই থাকবে, তেমনি অ্যাডমিন চাইলে চ্যাটজিপিটি বা ক্লড-এ প্রম্পট দিয়ে পাওয়া JSON পেস্ট করেও রুটিন ইমপোর্ট করতে পারবেন।
  - সিস্টেমে সরাসরি ডাটা সেভ হওয়ার আগে একটি প্রিভিউ স্ক্রিন আসবে, যাতে অ্যাডমিন কোনো বানান বা রুম নম্বর দরকার হলে এডিট করে কনফার্ম করতে পারেন।

---

## Decision 9: Sequence of Docker Compose Setup

### 🇬🇧 English Technical Rationale:
- **Context**: Determining when `docker-compose.yml` should be placed in the repository.
- **Why removed initially and scheduled for Task 1.3**:
  1. **No Dead Configurations**: `docker-compose.yml` referenced `build: context: ./backend, dockerfile: Dockerfile`. Running Docker before `backend/` was created caused immediate build errors.
  2. **Dependency Sequencing**:
     - **Task 1.1**: Initialize `backend/` and verify clean TypeScript build.
     - **Task 1.2**: Write `schema.prisma`.
     - **Task 1.3**: Introduce multi-stage `backend/Dockerfile` and root `docker-compose.yml` for PostgreSQL 16 & Redis 7. Everything boots green on the first try.

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কেন docker-compose.yml সাময়িকভাবে সরিয়ে Task 1.3-এ নেওয়া হলো?**:
  - `docker-compose.yml`-এ ব্যাকএন্ডের `Dockerfile` দিয়ে কন্টেইনার বানানোর কমান্ড ছিল। কিন্তু তখনো `backend/` ফোল্ডারটি তৈরিই হয়নি! ফলে ওটা রান করলে এরর আসত।
  - তাই সফটওয়্যার ইঞ্জিনিয়ারিংয়ের ধারাবাহিকতা অনুযায়ী প্রথমে Task 1.1-এ ব্যাকএন্ড তৈরি করব, তারপর Task 1.3-এ ডাটাবেজ কন্টেইনার সহ ডকার চালু করব।

---

## Decision 10: 100% Zero-Cost ($0/Month) Production Hosting

### 🇬🇧 English Technical Rationale:
- **Context**: Enabling students, educators, and indie developers to host the entire production stack permanently without credit cards or fees.
- **Free-Tier Stack Breakdown**:
  - **API Compute**: Render.com / Railway (750 free monthly compute hours).
  - **PostgreSQL Database**: Neon.tech / Supabase (0.5 GB free serverless PostgreSQL).
  - **In-Memory Cache**: Upstash Redis (10,000 commands/day free).
  - **Push Notifications**: Firebase Cloud Messaging (100% free unlimited pushes).
  - **Transactional Email**: Resend API (3,000 free emails/month).
  - **Multimodal AI**: Google Gemini 2.0 Flash (15 requests/minute free).
  - **CI/CD Quality Gate**: GitHub Actions (2,000 free build minutes/month).

### 🇧🇩 বাংলা ব্যাখ্যা:
- **কীভাবে পুরো প্রজেক্টটি আজীবন ফ্রিতে ($০/মাস) চলবে?**:
  - আমরা এমন কোনো সার্ভিস বেছে নিইনি যাতে পেইড সাবস্ক্রিপশন বা ক্রেডিট কার্ড লাগে।
  - রেন্ডার দিয়ে ফ্রি ব্যাকএন্ড সার্ভার, নিয়ন দিয়ে ফ্রি পোস্টগ্রেস ডাটাবেজ, আপস্ট্যাশ দিয়ে ফ্রি রেডিস ক্যাশ, ফায়ারবেস দিয়ে আনলিমিটেড ফ্রি পুশ নোটিফিকেশন এবং রিসেন্ড দিয়ে ফ্রি ইমেইল চালানো হবে।
  - ফলে ইন্টারভিউ বা ক্যাম্পাসে দেখানোর সময় কোনো খরচ ছাড়াই প্রজেক্টটি লাইভ ইন্টারনেটে চালু থাকবে!

---

> 🎓 **Summary**: This document is your foundational architectural anchor. Every decision is intentional, mathematically justified, and aligned with modern software engineering excellence.
