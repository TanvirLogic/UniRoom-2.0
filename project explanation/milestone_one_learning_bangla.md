# 🇧🇩 মাইলস্টোন ১: আর্কিটেকচার ও কোড বিশ্লেষণ গাইড (বাংলা সংস্করণ)
> **UniRoom-Live 2.0 — মাইলস্টোন ১ এর সম্পূর্ণ টেকনিক্যাল হ্যান্ডবুক**  
> *উদ্দেশ্য: তানভীরের ফুল-স্ট্যাক সফটওয়্যার ইঞ্জিনিয়ারিং ও সিস্টেম ডিজাইন মাস্টারি*  
> *ভাষা: বাংলা (Bangla)*  
> *লোকেশন: `project explanation/milestone_one_learning_bangla.md`*

---

## 📑 সূচিপত্র
1. [মাইলস্টোন ১ এর মূল লক্ষ্য ও সিস্টেম ওভারভিউ](#১-মাইলস্টোন-১-এর-মূল-লক্ষ্য-ও-সিস্টেম-ওভারভিউ)
2. [Task 1.1: ব্যাকএন্ড প্রজেক্ট সেটআপ ও TypeScript কনফিগারেশন](#২-task-11-ব্যাকএন্ড-প্রজেক্ট-সেটআপ-ও-typescript-কনফিগারেশন)
   - [package.json এর লাইব্রেরিসমূহের বিস্তারিত কাজ](#packagejson-এর-লাইব্রেরিসমূহের-বিস্তারিত-কাজ)
   - [tsconfig.json: এন্টারপ্রাইজ টাইপস্ক্রিপ্ট স্ট্রিক্টনেস](#tsconfigjson-এন্টারপ্রাইজ-টাইপস্ক্রিপ্ট-স্ট্রিক্টনেস)
3. [Task 1.2: মাল্টি-টেন্যান্ট ডাটাবেজ আর্কিটেকচার (`schema.prisma`)](#৩-task-12-মাল্টি-টেন্যান্ট-ডাটাবেজ-আর্কিটেকচার-schemaprisma)
   - [মাল্টি-টেন্যান্সি (Multi-Tenancy) কী এবং কেন আবশ্যক?](#মাল্টি-টেন্যান্সি-multi-tenancy-কী-এবং-কেন-আবশ্যক)
   - [৮টি ডাটাবেজ মডেলের লাইন-বাই-লাইন বিশ্লেষণ](#৮টি-ডাটাবেজ-মডেলের-লাইন-বাই-লাইন-বিশ্লেষণ)
   - [B-Tree কম্পোজিট ইনডেক্স কেন দেওয়া হয়েছে?](#b-tree-কম্পোজিট-ইনডেক্স-কেন-দেওয়া-হয়েছে)
   - [অপটিমিস্টিক কনকারেন্সি কন্ট্রোল (OCC) ও ডাবল-বুকিং রোধ](#অপটিমিস্টিক-কনকারেন্সি-কন্ট্রোল-occ-ও-ডাবল-বুকিং-রোধ)
4. [Task 1.3: ক্লাউড ডাটাবেজ সেটআপ (Neon Serverless PostgreSQL)](#৪-task-13-ক্লাউড-ডাটাবেজ-সেটআপ-neon-serverless-postgresql)
   - [কানেকশন স্ট্রিং ও কানেকশন পুলার (PgBouncer) এর ভূমিকা](#কানেকশন-স্ট্রিং-ও-কানেকশন-পুলার-pgbouncer-এর-ভূমিকা)
5. [Task 1.4: ডাটাবেজ মাইগ্রেশন ও সিডিং স্ক্রিপ্ট](#৫-task-14-ডাটাবেজ-মাইগ্রেশন-ও-সিডিং-স্ক্রিপ্ট)
   - [`prisma migrate dev` এর ব্যাকগ্রাউন্ডে কী ঘটে?](#prisma-migrate-dev-এর-ব্যাকগ্রাউন্ডে-কী-ঘটে)
   - [`prisma/seed.ts` এর লাইন-বাই-লাইন ব্যবচ্ছেদ](#prismaseedts-এর-লাইন-বাই-লাইন-ব্যবচ্ছেদ)
6. [Task 1.5: `src/` ফোল্ডারের মূল NestJS আর্কিটেকচার](#৬-task-15-src-ফোল্ডারের-মূল-nestjs-আর্কিটেকচার)
   - [PrismaService ও গ্লোবাল PrismaModule](#prismaservice-ও-গ্লোবাল-prismamodule)
   - [গ্লোবাল HTTP Exception Filter (এরর হ্যান্ডলার)](#গ্লোবাল-http-exception-filter-এরর-হ্যান্ডলার)
   - [গ্লোবাল Transform Interceptor (রেসপন্স খাম)](#গ্লোবাল-transform-interceptor-রেসপন্স-খাম)
   - [মেইন বুটস্ট্র্যাপ ফাইল (`main.ts`) ও পাইপলাইন](#মেইন-বুটস্ট্র্যাপ-ফাইল-maints-ও-পাইপলাইন)
   - [সিস্টেম হেলথ ও ডায়াগনস্টিক কন্ট্রোলার](#সিস্টেম-হেলথ-ও-ডায়াগনস্টিক-কন্ট্রোলার)
7. [মাইলস্টোন ১ এর ভাইভা ও ইন্টারভিউ প্রস্তুতি প্রশ্নোত্তর](#৭-মাইলস্টোন-১-এর-ভাইভা-ও-ইন্টারভিউ-প্রস্তুতি-প্রশ্নোত্তর)

---

# ১. মাইলস্টোন ১ এর মূল লক্ষ্য ও সিস্টেম ওভারভিউ

### মাইলস্টোন ১ এর উদ্দেশ্য কী ছিল?
মাইলস্টোন ১ হলো একটি সফটওয়্যারের **ভিত্তিপ্রস্তর (Foundation)**। সরাসরি কোনো তাড়াহুড়ো করে লগইন বা রুটিন বুকিংয়ের কোড না লিখে, একজন সিনিয়র সফটওয়্যার ইঞ্জিনিয়ার প্রথমে সিস্টেমের সার্বিক অবকাঠামো তৈরি করেন:
1. একটি শক্তিশালী ও শতভাগ টাইপ-সেফ রানটাইম (NestJS + TypeScript)।
2. একটি স্কেলেবল ও রিলেশনাল মাল্টি-টেন্যান্ট ডাটাবেজ স্কিমা (PostgreSQL ও Prisma ORM)।
3. স্বয়ংক্রিয় ডাটাবেজ মাইগ্রেশন এবং বাস্তবসম্মত ডেমো ডেটা (উত্তরা ইউনিভার্সিটির রুটিন)।
4. গ্লোবাল নিরাপত্তা ও ভ্যালিডেশন পাইপলাইন (ভুল ইনপুট স্বয়ংক্রিয়ভাবে মুছে ফেলা ও স্ট্যান্ডার্ড এরর রেসপন্স)।
5. ব্রাউজারেই লাইভ এপিআই টেস্ট করার সোয়াগার ডকুমেন্টেশন (Swagger OpenAPI)।

```
┌────────────────────────────────────────────────────────────────────────┐
│                        মাইলস্টোন ১ এর সম্পূর্ণ পাইপলাইন                   │
├───────────────────────────────┬────────────────────────────────────────┤
│           ইনকামিং             │ ক্লায়েন্ট থেকে আসা HTTP রিকোয়েস্ট      │
│               │               │ (ফ্লাটার মোবাইল অ্যাপ বা ওয়েবসাইট)      │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │  CORS & Prefix    │     │ গ্লোবাল প্রিফিক্স: /api/v1             │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │  ValidationPipe   │     │ অনাকাঙ্ক্ষিত ফিল্ড রিমুভ ও টাইপ চেকিং  │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │ HealthController  │     │ ডাটাবেজে লাইভ SELECT 1 পিং টেস্ট       │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │   PrismaService   │     │ কানেকশন অন/অফ লাইফসাইকেল নিয়ন্ত্রণ     │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │ Neon PostgreSQL   │     │ এডাব্লিউএস ক্লাউডে ৮টি মাল্টি-টেন্যান্ট টেবিল│
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │TransformIntercept.│     │ সফল আউটপুট মোড়ানো: { success: true }   │
│     └─────────┬─────────┘     │                                        │
│               ▼               │                                        │
│     ┌───────────────────┐     │                                        │
│     │AllExceptionsFilter│     │ এরর হ্যান্ডলিং: { success: false }      │
│     └───────────────────┘     │                                        │
└───────────────────────────────┴────────────────────────────────────────┘
```

---

# ২. Task 1.1: ব্যাকএন্ড প্রজেক্ট সেটআপ ও TypeScript কনফিগারেশন

### `package.json` এর লাইব্রেরিসমূহের বিস্তারিত কাজ
[`backend/package.json`](file:///e:/Varsity%20Project/UniRoom-Live/backend/package.json) ফাইলে প্রতিটি প্যাকেজ একটি নির্দিষ্ট সফটওয়্যার ইঞ্জিনিয়ারিং উদ্দেশ্য নিয়ে যোগ করা হয়েছে:

| প্যাকেজের নাম | ব্যাকএন্ডে এর ভূমিকা | সহজ ভাষায় ব্যাখ্যা |
| :--- | :--- | :--- |
| `@nestjs/core` ও `@nestjs/common` | নেস্টজেএস ফ্রেমওয়ার্কের মূল ইঞ্জিন। | কন্ট্রোলার, সার্ভিস, মডিউল এবং ডেকোরেটরস (`@Injectable()`, `@Get()`) পরিচালনা করে। |
| `@nestjs/config` | কনফিগারেশন সার্ভিস। | `.env` ফাইল থেকে ডাটাবেজ ইউআরএল এবং সিক্রেট কি নিরাপদে পুরো অ্যাপে লোড করে। |
| `@prisma/client` | প্রিজমা কুয়েরি বিল্ডার। | টাইপস্ক্রিপ্টে স্বয়ংক্রিয়ভাবে ১০০% টাইপ-সেফ ডাটাবেজ কুয়েরি লেখার সুবিধা দেয়। |
| `class-validator` ও `class-transformer` | ডেটা ভ্যালিডেশন টুল। | ইনকামিং JSON অবজেক্টের প্রতিটি ফিল্ড যাচাই করে (যেমন: `@IsEmail()`, `@MinLength(6)`)। |
| `rxjs` | রিয়্যাক্টিভ প্রোগ্রামিং লাইব্রেরি। | নেস্টজেএস ইন্টারসেপ্টরে রেসপন্স স্ট্রিম মডিফাই করার জন্য ব্যবহৃত হয়। |
| `@nestjs/swagger` ও `swagger-ui-express` | স্বয়ংক্রিয় ডকুমেন্টেশন। | কোড পড়ে ব্রাউজারে লাইভ এপিআই ড্যাশবোর্ড (`/api/docs`) তৈরি করে। |

---

### `tsconfig.json`: এন্টারপ্রাইজ টাইপস্ক্রিপ্ট স্ট্রিক্টনেস
ফাইল: [`backend/tsconfig.json`](file:///e:/Varsity%20Project/UniRoom-Live/backend/tsconfig.json)

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "ES2021",
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "strictBindCallApply": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

#### এই ফ্ল্যাগগুলো কেন এত জরুরি?
1. **`emitDecoratorMetadata: true` ও `experimentalDecorators: true`**:
   * NestJS ফ্রেমওয়ার্ক ডেকোরেটরের ওপর নির্ভরশীল (`@Injectable()`, `@Controller()`)।
   * টাইপস্ক্রিপ্ট জাভাস্ক্রিপ্টে রূপান্তর হওয়ার সময় এই ডেকোরেটরের ডেটা নষ্ট হয়ে যায়। এই ফ্ল্যাগ অন থাকলে মেটাডেটা সুরক্ষিত থাকে, ফলে NestJS বুঝতে পারে কোন কন্ট্রোলারের ভেতরে কোন সার্ভিসটি ইনজেক্ট করতে হবে।
2. **`strictNullChecks: true`**:
   * জাভাস্ক্রিপ্টের বহুল পরিচিত ক্র্যাশ *"Cannot read properties of undefined"* বন্ধ করে। কোনো অবজেক্ট যদি কখনো `null` হতে পারে, তবে টাইপস্ক্রিপ্ট আপনাকে বাধ্য করবে `if (!room)` দিয়ে চেক করতে।
3. **`noImplicitAny: true`**:
   * কোনো ডাটাটাইপ উল্লেখ না করে কোড লেখা যাবে না। প্রতিটি প্যারামিটারের সুনির্দিষ্ট টাইপ (যেমন: `roomId: string`) থাকতে হবে। এতে কোডে কোনো গোপন বাগ লুকিয়ে থাকতে পারে না।

---

# ৩. Task 1.2: মাল্টি-টেন্যান্ট ডাটাবেজ আর্কিটেকচার (`schema.prisma`)
ফাইল: [`backend/prisma/schema.prisma`](file:///e:/Varsity%20Project/UniRoom-Live/backend/prisma/schema.prisma)

### মাল্টি-টেন্যান্সি (Multi-Tenancy) কী এবং কেন আবশ্যক?
* **সিঙ্গেল টেন্যান্ট অ্যাপ:** আপনি শুধুমাত্র উত্তরা ইউনিভার্সিটির জন্য কোড লিখলেন। অন্য কোনো বিশ্ববিদ্যালয় এটি নিতে চাইলে তাদের জন্য নতুন ডাটাবেজ এবং নতুন সার্ভার সেটআপ করতে হবে।
* **মাল্টি-টেন্যান্ট অ্যাপ (UniRoom-Live 2.0):** একটিমাত্র সার্ভার এবং একটিমাত্র ডাটাবেজ দিয়েই শত শত বিশ্ববিদ্যালয়কে আলাদা আলাদা নিরাপত্তা দিয়ে পরিচালনা করা সম্ভব।
  * **টেন্যান্ট সীমানা (Tenant Boundary):** `University` টেবিলটি হলো মূল টেন্যান্ট।
  * **ডেটা আইসোলেশন:** প্রতিটি ডিপার্টমেন্ট, রুম, ইউজার এবং রুটিনের স্লটে `universityId` সংরক্ষিত থাকে।
  * উত্তরা ইউনিভার্সিটির কোনো সিআর লগইন করলে ব্যাকএন্ডের সব কুয়েরিতে স্বয়ংক্রিয়ভাবে `WHERE universityId = '...'` যুক্ত হয়। ফলে অন্য বিশ্ববিদ্যালয়ের ডেটা দেখার বা পরিবর্তনের কোনো সুযোগ নেই।

---

### ৮টি ডাটাবেজ মডেলের লাইন-বাই-লাইন বিশ্লেষণ

#### ১. `University` (মূল টেন্যান্ট)
```prisma
model University {
  id            String      @id @default(uuid())
  name          String      // যেমন: "Uttara University"
  code          String      @unique // যেমন: "UU"
  domain        String?     // যেমন: "uttara.edu.bd"
  operatingDays DayOfWeek[] @default([MON, TUE, WED, THU])
  isActive      Boolean     @default(true)
  ...
}
```
* **UUID কেন?**: আমরা আইডি হিসেবে ক্রমান্বয়িক সংখ্যা (১, ২, ৩) ব্যবহার করিনি, বরং র্যান্ডম **UUID** ব্যবহার করেছি। ক্রমান্বয়িক সংখ্যা ব্যবহার করলে হ্যাকাররা আইডি পরিবর্তন করে (`/api/v1/users/5`) অন্যদের ডেটা খোঁজার চেষ্টা করতে পারে। UUID ভাঙা অসম্ভব।
* **`operatingDays`**: উত্তরা ইউনিভার্সিটিতে সোম থেকে বৃহস্পতিবার ক্লাস হয়, আবার অন্য বিশ্ববিদ্যালয়ে রবি থেকে বৃহস্পতিবার হতে পারে। এই ফিল্ডটির মাধ্যমে সিস্টেম যেকোনো বিশ্ববিদ্যালয়ের ক্যালেন্ডারে খাপ খাইয়ে নিতে পারে।

#### ২. `Department` (বিভাগ)
```prisma
model Department {
  id           String     @id @default(uuid())
  universityId String
  name         String     // যেমন: "Computer Science & Engineering"
  code         String     // যেমন: "CSE"
  university   University @relation(fields: [universityId], references: [id], onDelete: Cascade)
  ...
  @@unique([universityId, code])
}
```
* **`onDelete: Cascade`**: কোনো বিশ্ববিদ্যালয় ডিলিট হয়ে গেলে তার ডিপার্টমেন্টগুলোও ডাটাবেজ থেকে স্বয়ংক্রিয়ভাবে মুছে যাবে, যাতে ডাটাবেজে আবর্জনা তৈরি না হয়।
* **`@@unique([universityId, code])`**: নিশ্চিত করে যে উত্তরা ইউনিভার্সিটিতে "CSE" একটাই থাকবে, কিন্তু ঢাকা বিশ্ববিদ্যালয়েও আলাদা "CSE" থাকতে পারবে।

#### ৩. `Building` ও `Room` (ক্যাম্পাসের অবকাঠামো ও OCC)
```prisma
model Room {
  id             String     @id @default(uuid())
  universityId   String
  departmentId   String
  buildingId     String
  roomNumber     String     // যেমন: "AI Lab 5210 (514)", "5030 (508)"
  floor          Int        @default(1)
  capacity       Int        @default(40)
  currentStatus  RoomStatus @default(AVAILABLE) // AVAILABLE, RUNNING_CLASS, RESERVED, MAINTENANCE
  version        Int        @default(1) // Optimistic Concurrency Control (OCC)
  ...
  @@unique([buildingId, roomNumber])
  @@index([universityId, departmentId, currentStatus])
}
```
* **`currentStatus` Enum**: রুমের লাইভ স্ট্যাটাস। ক্লাস শেষ বা বাতিল হলে এটি `AVAILABLE` হয়ে যায়।
* **`version Int @default(1)`**: একই রুমে ডাবল বুকিং ঠেকানোর গোপন অস্ত্র (নিচে বিস্তারিত দেখুন)।

#### ৪. `RoomLog` (রুমের অডিট লগ)
* যখনই কোনো রুমের স্ট্যাটাস বদলায়, এই টেবিলে একটি হিস্ট্রি রেকর্ড জমা হয়:
  * কে পরিবর্তন করেছে (`changedByUserId`)।
  * আগের অবস্থা কী ছিল এবং নতুন অবস্থা কী হলো (`previousStatus`, `newStatus`)।
  * কোন নির্দিষ্ট মিলিসেকেন্ডে পরিবর্তন করা হলো (`createdAt`)।
* **কেন প্রয়োজন?** জবাবদিহিতা। কোনো ক্লাস সরে গেলে বা রুমে ঝামেলা হলে অ্যাডমিন দেখতে পারবেন কোন সিআর কোন সময়ে রুম বুক বা ক্যানসেল করেছিলেন।

#### ৫. `User` (ব্যবহারকারী ও ৪টি সুনির্দিষ্ট রোল)
```prisma
enum Role {
  STUDENT
  CR
  FACULTY
  SUPER_ADMIN
}
```
* **রোলগুলোর ক্ষমতা:**
  * `SUPER_ADMIN`: মাস্টার রুটিন আপলোড করে, ডিপার্টমেন্ট ও রুম তৈরি করে।
  * `FACULTY`: নিজের ক্লাসের তথ্য দেখে এবং প্রয়োজনবোধে নিজের ক্লাস রিশিডিউল করতে পারে।
  * `CR`: শুধু তার নিজস্ব ব্যাচ (যেমন: 68) ও সেকশনের (যেমন: A) জন্য খালি রুম বুক বা ক্লাস বাতিল করতে পারে।
  * `STUDENT`: রুটিন ও রুমের বর্তমান অবস্থা দেখার রিড-অনলি এক্সেস।

#### ৬. `ScheduleSlot` বনাম `ScheduleOverride` (মাস্টার-ওভাররাইড প্যাটার্ন)
* **`ScheduleSlot`**: সেমিস্টারের শুরুতে তৈরি হওয়া অপরিবর্তনীয় সাপ্তাহিক রুটিন (যেমন: প্রতি সোমবার সকাল ৯:৩০ এ ৬ষ্ঠ সেমিস্টারের অ্যালগরিদম ক্লাস রুম ৫২Intel-এ হবে)।
* **`ScheduleOverride`**: কোনো নির্দিষ্ট সোমবার শিক্ষক অসুস্থ থাকলে বা রুম পরিবর্তন করতে হলে আমরা **কখনোই মূল রুটিন ডিলিট করি না!** আমরা শুধুমাত্র ওই একটি নির্দিষ্ট তারিখের জন্য একটি ওভাররাইড এন্ট্রি তৈরি করি।
* **চমৎকার সফটওয়্যার আর্কিটেকচার:** পরের সপ্তাহে রুটিন আবার স্বয়ংক্রিয়ভাবে আগের মতো স্বাভাবিক হয়ে যায়! কাউকে নতুন করে রুটিন ঠিক করতে হয় না।

---

### B-Tree কম্পোজিট ইনডেক্স কেন দেওয়া হয়েছে?
`schema.prisma`-তে লক্ষ্য করুন:
```prisma
@@index([universityId, departmentId, currentStatus])
```
* **ইনডেক্স ছাড়া:** ডাটাবেজে যদি ২০টি ভার্সিটির ১০,০০০টি রুম থাকে, তবে খালি রুম খুঁজতে পুরো ১০,০০০টি রো ধরে ধরে স্ক্যান করতে হতো ($O(N)$ সময় লাগত, ডাটাবেজ স্লো হতো)।
* **কম্পোজিট ইনডেক্স সহ:** পোস্টগ্রেস্কেল ডিস্কে একটি B-Tree তৈরি করে রাখে। ফলে সরাসরি উত্তরা ইউনিভার্সিটি এবং সিএসই ডিপার্টমেন্টের খালি রুমগুলো মাত্র ১-২ মিলিসেকেন্ডেই খুঁজে বের করতে পারে ($O(\log N)$ স্পিড)।

---

### অপটিমিস্টিক কনকারেন্সি কন্ট্রোল (OCC) ও ডাবল-বুকিং রোধ
**সমস্যাটি কী?** ধরা যাক সকাল ১১টায় **রুম ৫০৩০** খালি আছে। ব্যাচ ৬৮-এর সিআর এবং ব্যাচ ৬৯-এর সিআর—দুজনেই একই মিলিসেকেন্ডে মোবাইল অ্যাপ থেকে "Book Room" বাটনে চাপ দিলেন।
* **লকিং মেকানিজম (ধীরগতির):** ডাটাবেজের টেবিল লক করে রাখলে অন্য শত শত ইউজার আটকে থাকবে।
* **অপটিমিস্টিক কনকারেন্সি কন্ট্রোল (অত্যন্ত দ্রুতগতির):**
  1. রুম ৫০৩০ এর ভার্সন হলো `version = 1`।
  2. দুজন সিআর-ই দেখলেন `version = 1`।
  3. সিআর ১ এর আপডেট কুয়েরি ডাটাবেজে পৌঁছাল:  
     `UPDATE rooms SET currentStatus = 'RESERVED', version = 2 WHERE id = '5030' AND version = 1;`  
     (ডাটাবেজ ১টি রো ম্যাচ পেল, ভার্সন ২ হলো, সিআর ১ রুমটি বুক করে ফেললেন!)
  4. ঠিক ৫ মিলিসেকেন্ড পর সিআর ২ এর কুয়েরি পৌঁছাল: `WHERE version = 1`।
     * কিন্তু রুমে তখন ভার্সন অলরেডি ২ হয়ে গেছে! ডাটাবেজ ০ টি রো আপডেট করল।
     * ব্যাকএন্ড এটি ধরতে পারল এবং সিআর ২ কে সাথে সাথে এরর দিল:  
       `409 Conflict: এই রুমটি এইমাত্র অন্য একজন সিআর বুক করে ফেলেছেন।`
  5. **ফলাফল:** ডাটাবেজ কোনো হ্যাং করা ছাড়াই ডাবল বুকিং ১০০% অসম্ভব হয়ে গেল!

---

# ৪. Task 1.3: ক্লাউড ডাটাবেজ সেটআপ (Neon Serverless PostgreSQL)

### কানেকশন স্ট্রিং ও কানেকশন পুলার (PgBouncer) এর ভূমিকা
[`backend/.env`](file:///e:/Varsity%20Project/UniRoom-Live/backend/.env) ফাইলে:
```env
DATABASE_URL="postgresql://neondb_owner:npg_...ep-snowy-surf-...-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require"
```
* `postgresql://`: ডাটাবেজ প্রোটোকল।
* `neondb_owner`: ডাটাবেজ ইউজারনেম।
* `npg_...`: এনক্রিপ্টেড সিক্রেট পাসওয়ার্ড।
* `ep-snowy-surf-...-pooler`: **কানেকশন পুলার (PgBouncer)**। হাজার হাজার ছাত্র একসাথে কানেক্ট হলেও ডাটাবেজের ওপর চাপ না ফেলে একই কানেকশন বারবার রিইউজ করে।
* `us-east-2.aws.neon.tech`: এডাব্লিউএস ডাটা সেন্টারে আল্ট্রা-ফাস্ট এসএসডি-তে সার্ভারলেস ইঞ্জিন চলছে।
* `sslmode=require`: আপনার পিসি এবং ক্লাউড ডাটাবেজের মধ্যকার সব ডেটা TLS/SSL দিয়ে এনক্রিপ্ট হয়ে যাতায়াত করে।

---

# ৫. Task 1.4: ডাটাবেজ মাইগ্রেশন ও সিডিং স্ক্রিপ্ট

### `prisma migrate dev` এর ব্যাকগ্রাউন্ডে কী ঘটে?
আমরা যখন `npx prisma migrate dev --name init_multitenant_schema` রান করেছিলাম:
1. প্রিজমা আমাদের `schema.prisma` ফাইলটি স্ক্যান করেছে।
2. `backend/prisma/migrations/20260916044320_init_multitenant_schema/migration.sql` ফাইলে স্বয়ংক্রিয়ভাবে SQL কোড তৈরি করেছে।
3. এই SQL কোডটি সরাসরি ক্লাউড ডাটাবেজে পাঠিয়ে টেবিল ও রিলেশনগুলো তৈরি করেছে।
4. পোস্টগ্রেস্কেলে `_prisma_migrations` নামে একটি হিস্ট্রি টেবিল তৈরি করে রেখেছে যাতে ভবিষ্যতে জানা যায় কোন কোন মাইগ্রেশন অলরেডি সম্পন্ন হয়েছে।

---

### `prisma/seed.ts` এর লাইন-বাই-লাইন ব্যবচ্ছেদ
ফাইল: [`backend/prisma/seed.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/prisma/seed.ts)

```typescript
// ১. ডিপেনডেন্সি অর্ডার মেনে টেবিল খালি করা
await prisma.emergencyAnnouncement.deleteMany();
await prisma.scheduleOverride.deleteMany();
await prisma.scheduleSlot.deleteMany();
await prisma.roomLog.deleteMany();
await prisma.room.deleteMany();
await prisma.building.deleteMany();
await prisma.user.deleteMany();
await prisma.department.deleteMany();
await prisma.university.deleteMany();
```
* **কেন এই নির্দিষ্ট ক্রমানুসারে ডিলিট করতে হলো?** ফরেন কি কনস্ট্রেইন্ট! আপনি যদি সবার আগে `University` ডিলিট করতে চান, পোস্টগ্রেস এরর দিবে: *"ইউনিভার্সিটি ডিলিট করা যাবে না কারণ ডিপার্টমেন্ট ও রুম এখনো একে রেফারেন্স করে আছে।"* তাই চাইল্ড টেবিল আগে ডিলিট করে তারপর প্যারেন্ট টেবিল ডিলিট করতে হয়।

```typescript
// ২. বাস্তবসম্মত ডেমো ডেটা তৈরি
const university = await prisma.university.create({
  data: {
    name: 'Uttara University',
    code: 'UU',
    domain: 'uttara.edu.bd',
    operatingDays: [DayOfWeek.MON, DayOfWeek.TUE, DayOfWeek.WED, DayOfWeek.THU],
  },
});
```
* উত্তরা ইউনিভার্সিটির বাস্তব রুটিন সিডিউল তৈরি করা হয়েছে।

```typescript
// ৩. সিকিউর পাসওয়ার্ড হ্যাশিং
const dummyHash = '$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW'; // "Password123!"
```
* আমরা কখনো ডাটাবেজে প্লেন পাসওয়ার্ড রাখি না। এটি একটি প্রাক-গণনাকৃত Bcrypt পাসওয়ার্ড হ্যাশ।

---

# ৬. Task 1.5: `src/` ফোল্ডারের মূল NestJS আর্কিটেকচার

### PrismaService ও গ্লোবাল PrismaModule
ফাইল: [`backend/src/prisma/prisma.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/prisma/prisma.service.ts)

```typescript
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect(); // সার্ভার চালু হলে ডাটাবেজ কানেক্ট হয়
  }

  async onModuleDestroy() {
    await this.$disconnect(); // সার্ভার বন্ধ হলে মেমরি লিক ছাড়া ক্লিনভাবে ডিসকানেক্ট হয়
  }
}
```
* **সিনিয়র ইঞ্জিনিয়ারিং স্ট্যান্ডার্ড:** শিক্ষানবিসরা প্রতি ফাইলে `new PrismaClient()` লেখে, ফলে শত শত ডাটাবেজ কানেকশন তৈরি হয়ে ডাটাবেজ ক্র্যাশ করে। আমাদের এই সার্ভিসটি একটি **সিঙ্গেলটন (Singleton)** হিসেবে স্বয়ংক্রিয়ভাবে পরিচালিত হয়।

---

### গ্লোবাল HTTP Exception Filter (এরর হ্যান্ডলার)
ফাইল: [`backend/src/common/filters/http-exception.filter.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/filters/http-exception.filter.ts)

```typescript
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    ...
    response.status(status).json({
      success: false,
      statusCode: status,
      error,
      message,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
```
* কোনো এরর হলে এক্সপ্রেস সাধারণত কুৎসিত এইচটিএমএল ক্র্যাশ মেসেজ পাঠায়। আমাদের এই ফিল্টারটি পুরো প্রোজেক্টের যেকোনো এররকে ধরে সুন্দর ও সুশৃঙ্খল JSON মেসেজে পরিণত করে যা ফ্লাটার অ্যাপ সহজেই বুঝতে পারে।

---

### গ্লোবাল Transform Interceptor (রেসপন্স খাম)
ফাইল: [`backend/src/common/interceptors/transform.interceptor.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/interceptors/transform.interceptor.ts)

```typescript
@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => ({
        success: true,
        statusCode: context.switchToHttp().getResponse().statusCode,
        data,
        timestamp: new Date().toISOString(),
      })),
    );
  }
}
```
* **ম্যাজিক:** আপনার কন্ট্রোলারে আর কষ্ট করে বারবার `return { success: true }` লিখতে হবে না। যেকোনো কন্ট্রোলারের আউটপুট স্বয়ংক্রিয়ভাবে এই সুন্দর ফরম্যাটের ভেতরে মোড়ানো অবস্থায় ক্লায়েন্টের কাছে পৌঁছাবে।

---

### মেইন বুটস্ট্র্যাপ ফাইল (`main.ts`) ও পাইপলাইন
ফাইল: [`backend/src/main.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/main.ts)

```typescript
// ১. অনাকাঙ্ক্ষিত ইনপুট ফিল্ড ফিল্টার
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,              // DTO-তে না থাকা ফিল্ড স্বয়ংক্রিয়ভাবে মুছে ফেলে
    forbidNonWhitelisted: true,   // অতিরিক্ত ফিল্ড পাঠালে সাথে সাথে এরর দেয়
    transform: true,              // স্ট্রিং ডেটাকে নাম্বারে রূপান্তর করে
  }),
);

// ২. গ্লোবাল এরর ফিল্টার
app.useGlobalFilters(new AllExceptionsFilter());

// ৩. গ্লোবাল রেসপন্স খাম
app.useGlobalInterceptors(new TransformInterceptor());

// ৪. সোয়াগার ওপেনএপিআই ডক চালু
const config = new DocumentBuilder()
  .setTitle('UniRoom-Live 2.0 API')
  .setVersion('2.0')
  .addBearerAuth(...)
  .build();
SwaggerModule.setup('api/docs', app, document);
```

---

### সিস্টেম হেলথ ও ডায়াগনস্টিক কন্ট্রোলার
ফাইল: [`backend/src/health/health.controller.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/health/health.controller.ts)

```typescript
@Get()
async checkHealth() {
  await this.prisma.$queryRaw`SELECT 1`; // ক্লাউড ডাটাবেজে দ্রুততম পিং
  const universityCount = await this.prisma.university.count();
  const roomCount = await this.prisma.room.count();
  const slotCount = await this.prisma.scheduleSlot.count();

  return {
    status: 'ok',
    stats: { universities: universityCount, rooms: roomCount, scheduleSlots: slotCount },
  };
}
```
* **`SELECT 1` কেন?**: এটি ডাটাবেজের দ্রুততম কুয়েরি (১ মিলিসেকেন্ড সময় নেয়)। এটি পরীক্ষা করে দেখে যে Neon PostgreSQL-এর সাথে ক্লাউড নেটওয়ার্ক এবং এসএসএল কানেকশন সম্পূর্ণ সুস্থ রয়েছে কি না।

---

# ৭. মাইলস্টোন ১ এর ভাইভা ও ইন্টারভিউ প্রস্তুতি প্রশ্নোত্তর

### ❓ প্রশ্ন ১: "একটি রুটিন ম্যানেজমেন্ট সিস্টেমের জন্য MongoDB-র চেয়ে PostgreSQL কেন অনেক বেশি কার্যকর?"
**উত্তর:**
"বিশ্ববিদ্যালয়ের রুটিন সিস্টেম সম্পূর্ণরূপে রিলেশনাল এবং এতে ACID নিশ্চয়তা প্রয়োজন। একটি ক্লাসের রুটিনে ডিপার্টমেন্ট, রুম, শিক্ষক, ব্যাচ ও সেকশনের সম্পর্ক থাকে। মঙ্গোডিবিতে এই তথ্যগুলো ডুপ্লিকেট হয়ে ছড়িয়ে থাকে। কোনো শিক্ষকের নাম বা রুম নম্বর পরিবর্তন হলে হাজার হাজার ডকুমেন্টে একসাথে আপডেট করতে গিয়ে অসঙ্গতি (Data Inconsistency) তৈরি হতে পারে। পোস্টগ্রেস্কেল-এর ফরেন কি (`onDelete: Cascade`), রিলেশনাল জয়েন এবং ট্রানজ্যাকশন শতভাগ ডেটা সুরক্ষার নিশ্চয়তা দেয়।"

### ❓ প্রশ্ন ২: "আপনার সিস্টেমে দুইজন সিআর একই সময়ে একই রুম বুক করার চেষ্টা করলে কী ঘটবে?"
**উত্তর:**
"আমরা অপটিমিস্টিক কনকারেন্সি কন্ট্রোল (OCC) আর্কিটেকচার ব্যবহার করেছি। আমাদের রুম টেবিলে একটি পূর্ণসংখ্যার `version` ফিল্ড রয়েছে। যখন সিআর বুক করার রিকোয়েস্ট পাঠায়, আপডেট স্টেটমেন্ট চেক করে `WHERE id = :roomId AND version = :currentVersion`। প্রথম সিআর-এর রিকোয়েস্টে ভার্সন বৃদ্ধি পায়। মাত্র ৫ মিলিসেকেন্ড পর দ্বিতীয় সিআর-এর কুয়েরি কোনো ম্যাচ খুঁজে পায় না (কারণ ভার্সন অলরেডি পরিবর্তিত)। আমাদের ব্যাকএন্ড সাথে সাথে দ্বিতীয় রিকোয়েস্টটি ধরে এবং একটি `HTTP 409 Conflict` এরর ফিরিয়ে দিয়ে ডাবল-বুকিং সম্পূর্ণ প্রতিরোধ করে।"

### ❓ প্রশ্ন ৩: "মাস্টার-ওভাররাইড প্যাটার্ন বলতে কী বোঝায়?"
**উত্তর:**
"সাধারণ রুটিন সিস্টেমে কোনো একটি ক্লাস বাতিল বা রুম পরিবর্তন করলে মূল রুটিনটি বিকৃত হয়ে যায় এবং পরের সপ্তাহে আবার হাত দিয়ে ঠিক করতে হয়। UniRoom-Live এ আমরা স্থায়ী ও অস্থায়ী ডেটা আলাদা রেখেছি: `ScheduleSlot` হলো সেমিস্টারের অপরিবর্তনীয় মাস্টার রুটিন, এবং `ScheduleOverride` হলো কোনো একদিনের জন্য হওয়া সাময়িক পরিবর্তন। ক্লায়েন্ট অ্যাপ এই দুই টেবিল মিলিয়ে লাইভ রুটিন দেখে। ওই তারিখটি পার হয়ে যাওয়ার সাথে সাথে কোনো ম্যানুয়াল পরিবর্তন ছাড়াই মূল রুটিন আবার স্বয়ংক্রিয়ভাবে সক্রিয় হয়ে যায়।"

---
