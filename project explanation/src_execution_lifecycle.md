# 🔄 UniRoom-Live 2.0: The Complete `src/` Execution Lifecycle Guide
> **সার্ভার চালু হওয়া থেকে রিকোয়েস্ট হ্যান্ডলিং ও শাটডাউন — `src/` ফোল্ডারের পূর্ণাঙ্গ জীবনচক্র হ্যান্ডবুক**  
> *Target Audience: Tanvir (Full-Stack Backend Mastery)*  
> *Language: Bilingual (বাংলা ও English)*  
> *Location: `project explanation/src_execution_lifecycle.md`*

---

## 📑 সূচিপত্র (Table of Contents)
1. [The Big Picture: `src/` ফোল্ডারের আর্কিটেকচারাল মানচিত্র](#১-the-big-picture-src-ফোল্ডারের-আর্কিটেকচারাল-মানচিত্র)
2. [Phase 1: The Startup Cycle (সার্ভার চালু হওয়ার মুহূর্ত)](#২-phase-1-the-startup-cycle-সার্ভার-চালু-হওয়ার-মুহূর্ত)
   - [ধাপ ১: `src/main.ts` এ প্রবেশ ও `bootstrap()`](#ধাপ-১-srcmaints-এ-প্রবেশ-ও-bootstrap)
   - [ধাপ ২: `app.module.ts` এ ডিপেনডেন্সি ট্রি তৈরি](#ধাপ-২-appmodulets-এ-ডিপেনডেন্সি-ট্রি-তৈরি)
   - [ধাপ ৩: ডাটাবেজ হ্যান্ডশেক (`onModuleInit`)](#ধাপ-৩-ডাটাবেজ-হ্যান্ডশেক-onmoduleinit)
   - [ধাপ ৪: গ্লোবাল পাইপ, ফিল্টার ও সোয়াগার যুক্ত হওয়া](#ধাপ-৪-গ্লোবাল-পাইপ-ফিল্টার-ও-সোয়াগার-যুক্ত-হওয়া)
   - [ধাপ ৫: পোর্ট ৩০০০ এ সার্ভার লিসেনিং শুরু](#ধাপ-৫-পোর্ট-৩০০০-এ-সার্ভার-লিসেনিং-শুরু)
3. [Phase 2: The Request-Response Cycle (লাইভ রিকোয়েস্ট সাইকেল)](#৩-phase-2-the-request-response-cycle-লাইভ-রিকোয়েস্ট-সাইকেল)
   - [ধাপ ১: ক্লায়েন্ট থেকে রিকোয়েস্ট আসা (`GET /api/v1/health`)](#ধাপ-১-ক্লায়েন্ট-থেকে-রিকোয়েস্ট-আসা-get-apiv1health)
   - [ধাপ ২: CORS ও গ্লোবাল প্রিফিক্স যাচাই](#ধাপ-২-cors-ও-গ্লোবাল-প্রিফিক্স-যাচাই)
   - [ধাপ ৩: ভ্যালিডেশন পাইপের স্ক্রিনিং](#ধাপ-৩-ভ্যালিডেশন-পাইপের-স্ক্রিনিং)
   - [ধাপ ৪: কন্ট্রোলারে রিকোয়েস্ট হ্যান্ডলিং (`HealthController`)](#ধাপ-৪-কন্ট্রোলারে-রিকোয়েস্ট-হ্যান্ডলিং-healthcontroller)
   - [ধাপ ৫: ডাটাবেজে লাইভ কুয়েরি ও পিং (`PrismaService`)](#ধাপ-৫-ডাটাবেজে-লাইভ-কুয়েরি-ও-পিং-prismaservice)
   - [ধাপ ৬: রেসপন্স ইন্টারসেপ্টর (`TransformInterceptor`)](#ধাপ-৬-রেসপন্স-ইন্টারসেপ্টর-transforminterceptor)
   - [ধাপ ৭: ক্লায়েন্টের কাছে চূড়ান্ত ডেটা পৌঁছানো](#ধাপ-৭-ক্লায়েন্টের-কাছে-চূড়ান্ত-ডেটা-পৌঁছানো)
4. [Phase 3: The Error Cycle (যদি কোনো ভুল বা ক্র্যাশ ঘটে)](#৪-phase-3-the-error-cycle-যদি-কোনো-ভুল-বা-ক্র্যাশ-ঘটে)
   - [`AllExceptionsFilter` কীভাবে এরর উদ্ধার করে?](#allexceptionsfilter-কীভাবে-এরর-উদ্ধার-করে)
5. [Phase 4: The Shutdown Cycle (সার্ভার বন্ধের মুহূর্ত)](#৫-phase-4-the-shutdown-cycle-সার্ভার-বন্ধের-মুহূর্ত)
   - [`onModuleDestroy()` এবং কানেকশন পুল ক্লোজিং](#onmoduledestroy-এবং-কানেকশন-পুল-ক্লোজিং)
6. [Quick Reference Table: ফাইলের নাম ও তাদের দায়িত্ব](#৬-quick-reference-table-ফাইলের-নাম-ও-তাদের-দায়িত্ব)

---

# ১. The Big Picture: `src/` ফোল্ডারের আর্কিটেকচারাল মানচিত্র

আমাদের [`backend/src/`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src) ফোল্ডারটি হলো অ্যাপ্লিকেশনের **মস্তিষ্ক ও কেন্দ্রীয় ইঞ্জিন**। এর ফাইলের গঠন নিচে দেওয়া হলো:

```
backend/src/
├── main.ts                            <-- মূল প্রবেশদ্বার (Bootstrap Gate)
├── app.module.ts                      <-- সেন্ট্রাল কন্ট্রোল সুইচবোর্ড (Root Module)
├── common/                            <-- গ্লোবাল গার্ডিয়ান ও ইউটিলিটি
│   ├── filters/
│   │   └── http-exception.filter.ts   <-- এরর নিয়ন্ত্রণকারী (Global Exception Filter)
│   └── interceptors/
│       └── transform.interceptor.ts   <-- রেসপন্স খাম প্রস্তুতকারী (Transform Interceptor)
├── health/                            <-- সিস্টেম ডায়াগনস্টিক মডিউল
│   ├── health.controller.ts           <-- টেস্ট এপিআই রাউট (@Get('health'))
│   └── health.module.ts               <-- হেলথ মডিউল প্যাকেজার
└── prisma/                            <-- ডাটাবেজ কমিউনিকেশন লেয়ার
    ├── prisma.service.ts              <-- পোস্টগ্রেস্কেল লাইফসাইকেল ড্রাইভার
    └── prisma.module.ts               <-- গ্লোবাল ডাটাবেজ মডিউল
```

---

# ২. Phase 1: The Startup Cycle (সার্ভার চালু হওয়ার মুহূর্ত)

যখন আপনি টার্মিনালে লিখবেন:
```bash
npm run start:dev
```
তখন নেস্টজেএস (NestJS) কোড কম্পাইল করে মেমরিতে নিচের সিকোয়েন্স অনুযায়ী রান করে:

```
[ টার্মিনালে npm run start ]
            │
            ▼
   1. src/main.ts -> bootstrap() কল হয়
            │
            ▼
   2. NestFactory.create(AppModule)
            │
            ├──► ConfigModule: .env ফাইল পড়ে DATABASE_URL লোড করে
            ├──► PrismaModule: PrismaService তৈরি করে
            │         └──► onModuleInit(): Neon PostgreSQL এর সাথে ক্লাউড হ্যান্ডশেক সম্পন্ন করে!
            └──► HealthModule: HealthController কে মেমরিতে রেজিস্টার করে
            │
            ▼
   3. গ্লোবাল সেটিংস যুক্ত হয় (CORS, Prefix, ValidationPipe, Filter, Interceptor, Swagger)
            │
            ▼
   4. app.listen(3000): পোর্ট ৩০০০ ওপেন হয় -> সার্ভার সম্পূর্ণ সক্রিয়!
```

---

### ধাপ ১: `src/main.ts` এ প্রবেশ ও `bootstrap()`
ফাইল: [`src/main.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/main.ts)
```typescript
async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule); // ◄── মূল অ্যাপ অবজেক্ট তৈরি
```
* `bootstrap()` হলো পুরো অ্যাপ্লিকেশনের চাবি। এটি চালু হওয়ামাত্র `NestFactory.create(AppModule)` কে কল করে।
* NestJS ফ্রেমওয়ার্ক তখন `AppModule` পড়ে পুরো অ্যাপ্লিকেশনের আর্কিটেকচারাল ট্রি বিল্ড করতে শুরু করে।

---

### ধাপ ২: `app.module.ts` এ ডিপেনডেন্সি ট্রি তৈরি
ফাইল: [`src/app.module.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/app.module.ts)
```typescript
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, envFilePath: '.env' }),
    PrismaModule,
    HealthModule,
  ],
})
export class AppModule {}
```
* **`ConfigModule`**: `.env` ফাইল থেকে গোপন ডাটাবেজ ইউআরএল এবং সিক্রেট কি লোড করে।
* **`PrismaModule`**: আমাদের ডাটাবেজ সার্ভিসকে চালু করার নির্দেশ দেয়।
* **`HealthModule`**: আমাদের ডায়াগনস্টিক রাউটটি মেমরিতে রেজিস্টার করে।

---

### ধাপ ৩: ডাটাবেজ হ্যান্ডশেক (`onModuleInit`)
ফাইল: [`src/prisma/prisma.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/prisma/prisma.service.ts)
```typescript
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    this.logger.log('Connecting to PostgreSQL database...');
    await this.$connect(); // ◄── ক্লাউড ডাটাবেজে হ্যান্ডশেক
    this.logger.log('✅ PostgreSQL connection established successfully.');
  }
}
```
* **আর্কিটেকচারাল জাদু:** সার্ভার পোর্ট খোলার আগেই `onModuleInit()` হুক রান করে।
* এটি এডাব্লিউএস ক্লাউডে থাকা **Neon PostgreSQL**-এর সাথে TLS/SSL এনক্রিপ্টেড টিসিপি হ্যান্ডশেক করে কানেকশন পুল রেডি করে।
* যদি ডাটাবেজ পাসওয়ার্ড ভুল হয় বা ডাটাবেজ ডাউন থাকে, সার্ভার ক্র্যাশ করে এখানেই থেমে যাবে, যাতে কোনো ব্রোকেন সার্ভার চালু না হয়।

---

### ধাপ ৪: গ্লোবাল পাইপ, ফিল্টার ও সোয়াগার যুক্ত হওয়া
ডাটাবেজ প্রস্তুত হওয়ার পর `main.ts` এ সিকিউরিটি ও পাইপলাইন টুলগুলো লোড হয়:

```typescript
// ১. ব্রাউজার ও মোবাইল অ্যাপের জন্য CORS ওপেন করা
app.enableCors({ origin: true, credentials: true });

// ২. সব এপিআই এর আগে /api/v1 প্রিফিক্স যুক্ত করা
app.setGlobalPrefix('api/v1');

// ৩. ইনপুট ভ্যালিডেশন দারোয়ান চালু করা
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,              // DTO তে ডিফাইন না করা ফিল্ড আসলে ডিলিট করে
    forbidNonWhitelisted: true,   // হ্যাকার অতিরিক্ত ফিল্ড পাঠালে 400 এরর দেয়
    transform: true,              // স্ট্রিং ডেটাকে নাম্বারে কনভার্ট করে
  }),
);

// ৪. এরর ফিল্টার চালু করা
app.useGlobalFilters(new AllExceptionsFilter());

// ৫. রেসপন্স খাম প্রস্তুতকারী ইন্টারসেপ্টর চালু করা
app.useGlobalInterceptors(new TransformInterceptor());

// ৬. লাইভ সোয়াগার ডকুমেন্টেশন ওয়েবসাইট চালু করা (/api/docs)
const config = new DocumentBuilder()
  .setTitle('UniRoom-Live 2.0 API')
  .setVersion('2.0')
  .addBearerAuth(...)
  .build();
const document = SwaggerModule.createDocument(app, config);
SwaggerModule.setup('api/docs', app, document);
```

---

### ধাপ ৫: পোর্ট ৩০০০ এ সার্ভার লিসেনিং শুরু
```typescript
const port = process.env.PORT || 3000;
await app.listen(port);
logger.log(`🚀 API Server running on: http://localhost:${port}/api/v1`);
logger.log(`📚 Swagger Documentation: http://localhost:${port}/api/docs`);
```
* অপারেটিং সিস্টেমের পোর্ট ৩০০০ ওপেন হয়ে যায়। সার্ভার এখন ক্লায়েন্টের রিকোয়েস্ট শোনার জন্য ১০০% প্রস্তুত!

---

# ৩. Phase 2: The Request-Response Cycle (লাইভ রিকোয়েস্ট সাইকেল)

ধরা যাক, একজন শিক্ষার্থী তার ফ্লাটার মোবাইল অ্যাপ বা ব্রাউজার থেকে রিকোয়েস্ট পাঠাল:
👉 **`GET http://localhost:3000/api/v1/health`**

এখন দেখুন রিকোয়েস্টটি কীভাবে ধাপে ধাপে ভ্রমণ করে:

```
[ ১. ক্লায়েন্ট পাঠাল: GET /api/v1/health ]
                     │
                     ▼
[ ২. CORS & Prefix Check ]
     └─ /api/v1 আছে কি না এবং অরিজিন ভ্যালিড কি না চেক করল
                     │
                     ▼
[ ৩. Global ValidationPipe ]
     └─ কোনো ক্ষতিকর বা অবৈধ বডি/প্যারামিটার আছে কি না চেক করল
                     │
                     ▼
[ ৪. HealthController (@Get('health')) ]
     └─ কন্ট্রোলার রিকোয়েস্টটি রিসিভ করল এবং সার্ভিস মেথড চালাল
                     │
                     ▼
[ ৫. PrismaService -> Neon PostgreSQL ]
     └─ ক্লাউডে SELECT 1 এবং COUNT(*) কুয়েরি পাঠিয়ে টেবিল স্ট্যাটাস আনল
                     │
                     ▼
[ ৬. TransformInterceptor ]
     └─ সাধারণ ডেটাকে স্ট্যান্ডার্ড { success: true, statusCode: 200, ... } খামে মোড়াল
                     │
                     ▼
[ ৭. ক্লায়েন্ট পেল: নিখুঁত JSON রেসপন্স! ]
```

---

### লাইন-বাই-লাইন কোড বিশ্লেষণ:

#### ধাপ ৪: কন্ট্রোলারে রিকোয়েস্ট রিসিভ হওয়া
ফাইল: [`src/health/health.controller.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/health/health.controller.ts)
```typescript
@ApiTags('Health & Diagnostics')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {} // ◄── Dependency Injection

  @Get()
  async checkHealth() {
```
* **Dependency Injection:** কন্ট্রোলারে আমরা কোনো `new PrismaService()` তৈরি করিনি। NestJS স্বয়ংক্রিয়ভাবে বুটস্ট্র্যাপের সময় তৈরি হওয়া ডাটাবেজ সার্ভিসকে এখানে ইনজেক্ট করে দিয়েছে।
* `@Get()` ডেকোরেটরটি রিকোয়েস্ট হ্যান্ডল করা শুরু করে।

---

#### ধাপ ৫: ডাটাবেজে লাইভ কুয়েরি পাঠানো
```typescript
    // ক্লাউড ডাটাবেজে ১ মিলিসেকেন্ডের লাইভ পিং
    await this.prisma.$queryRaw`SELECT 1`;

    // ডাটাবেজের ৩টি টেবিলের মোট রো গণনা করা
    const universityCount = await this.prisma.university.count();
    const roomCount = await this.prisma.room.count();
    const slotCount = await this.prisma.scheduleSlot.count();

    return {
      status: 'ok',
      service: 'UniRoom-Live 2.0 Backend',
      database: 'PostgreSQL (Neon Serverless)',
      stats: {
        universities: universityCount,
        rooms: roomCount,
        scheduleSlots: slotCount,
      },
    };
```
* কন্ট্রোলারটি ডাটাবেজ থেকে ডেটা নিয়ে একটি র' (raw) জাভাস্ক্রিপ্ট অবজেক্ট রিটার্ন করে।

---

#### ধাপ ৬: ইন্টারসেপ্টরে রেসপন্স রূপান্তর হওয়া
ফাইল: [`src/common/interceptors/transform.interceptor.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/interceptors/transform.interceptor.ts)
* কন্ট্রোলার থেকে ডেটা বের হওয়ার সাথে সাথে **`TransformInterceptor`** মাঝপথে এটিকে ধরে ফেলে:
```typescript
return next.handle().pipe(
  map((data) => ({
    success: true,
    statusCode: response.statusCode,
    data, // ◄── কন্ট্রোলারের রিটার্ন করা ডেটা এখানে বসে যায়!
    timestamp: new Date().toISOString(),
  })),
);
```

#### ধাপ ৭: ক্লায়েন্ট যা দেখতে পায়
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "status": "ok",
    "service": "UniRoom-Live 2.0 Backend",
    "database": "PostgreSQL (Neon Serverless)",
    "stats": {
      "universities": 1,
      "rooms": 4,
      "scheduleSlots": 3
    }
  },
  "timestamp": "2026-09-17T09:15:00.000Z"
}
```

---

# ৪. Phase 3: The Error Cycle (যদি কোনো ভুল বা ক্র্যাশ ঘটে)

ধরা যাক, ক্লায়েন্ট একটি ভুল ইউআরএল কল করল:
👉 **`GET http://localhost:3000/api/v1/wrong-url`**  
অথবা ক্লাউড ডাটাবেজের ইন্টারনেট সংযোগ বিচ্ছিন্ন হয়ে গেল!

তখন কী ঘটে?

```
[ সার্ভারে কোনো এক্সেপশন বা এরর ঘটল ]
                  │
                  ▼
      AllExceptionsFilter একে ধরে ফেলল!
                  │
                  ▼
        ক্লায়েন্ট কোনো ক্র্যাশ দেখল না!
        বরং একটি ক্লিন JSON এরর পেল:
        {
          "success": false,
          "statusCode": 404,
          "error": "Not Found",
          "message": "Cannot GET /api/v1/wrong-url",
          "timestamp": "2026-09-17T09:15:30.000Z",
          "path": "/api/v1/wrong-url"
        }
```

ফাইল: [`src/common/filters/http-exception.filter.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/filters/http-exception.filter.ts)
* **এরর সুরক্ষাকর্মী:** সাধারণ ব্যাকএন্ডে এরর হলে সার্ভার ক্র্যাশ করতে পারে বা পুরো কোডের কুৎসিত স্ট্যাকট্রেস ক্লায়েন্টকে দেখিয়ে দেয় (যা মারাত্মক সাইবার নিরাপত্তা ঝুঁকি)।
* আমাদের ফিল্টারটি সব এররকে আটকে একটি সুন্দর, সুরক্ষিত খামে মুড়ে ক্লায়েন্টকে দেয়।

---

# ৫. Phase 4: The Shutdown Cycle (সার্ভার বন্ধের মুহূর্ত)

যখন আপনি টার্মিনালে `Ctrl + C` চাপেন:
1. অপারেটিং সিস্টেম থেকে NestJS একটি `SIGINT` বা `SIGTERM` শাটডাউন সিগন্যাল পায়।
2. NestJS সাথে সাথে বন্ধ হয় না; এটি আগে সমস্ত সার্ভিসের শাটডাউন মেথড কল করে।
3. `PrismaService` এর **`onModuleDestroy()`** মেথড চালু হয়:
   ```typescript
   async onModuleDestroy() {
     this.logger.log('Disconnecting from PostgreSQL database...');
     await this.$disconnect(); // ◄── ক্লাউড ডাটাবেজ কানেকশন নিরাপদে ক্লোজ করে
     this.logger.log('Database connection closed cleanly.');
   }
   ```
4. **ফলাফল:** মেমরিতে কোনো হাংগিং বা লিক হওয়া ডাটাবেজ কানেকশন থাকে না। সার্ভার সম্পূর্ণ পরিষ্কার ও নিরাপদে বন্ধ হয়।

---

# ৬. Quick Reference Table: ফাইলের নাম ও তাদের দায়িত্ব

| ফাইলের পাথ | ভূমিকা / দায়িত্ব | বাস্তব জগতের অ্যানালজি |
| :--- | :--- | :--- |
| [`src/main.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/main.ts) | মূল গেট ও বুটস্ট্র্যাপ ফাইল | পুরো ভবনের প্রধান অভ্যর্থনা গেট ও চাবি |
| [`src/app.module.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/app.module.ts) | সেন্ট্রাল কন্ট্রোল মডিউল | কেন্দ্রীয় পাওয়ার সুইচবোর্ড |
| [`src/prisma/prisma.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/prisma/prisma.service.ts) | ডাটাবেজ কানেকশন ম্যানেজার | ক্লাউড ব্যাংকের সাথে সরাসরি যোগাযোগকারী দূত |
| [`src/health/health.controller.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/health/health.controller.ts) | ডায়াগনস্টিক হেলথ চেক | পুরো সিস্টেম সুস্থ আছে কি না তা যাচাইকারী ডাক্তার |
| [`src/common/interceptors/transform.interceptor.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/interceptors/transform.interceptor.ts) | রেসপন্স স্ট্যান্ডার্ডাইজার | সফল খাবার সুন্দর প্যাকেটে মোড়ানো গিফট র‍্যাপার |
| [`src/common/filters/http-exception.filter.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/filters/http-exception.filter.ts) | এরর ইন্টারসেপ্টর | যেকোনো দুর্ঘটনা বা ক্র্যাশ সামলানো দক্ষ প্যারামেডিক |

---
*এই গাইডটি আপনার প্রজেক্টের লাইফটাইম রেফারেন্স হিসেবে তৈরি করা হয়েছে।*
