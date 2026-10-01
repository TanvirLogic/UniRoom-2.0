# 🇧🇩 মাইলস্টোন ২: অথেনটিকেশন, সিকিউরিটি, ইমেইল ভেরিফিকেশন ও মেটাডেটা ইঞ্জিন
> **ভাষা:** 🇧🇩 বাংলা | **English Version:** [`milestone_two.md`](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_two.md)  
> **টার্গেট পাঠক:** তানভীর (ফুল-স্ট্যাক সফটওয়্যার ইঞ্জিনিয়ার ও একাডেমি ডিফেন্স ক্যান্ডিডেট)  
> **স্ট্যাটাস:** `[x]` সম্পন্ন (COMPLETED)  
> **ফাইল লোকেশন:** `project explanation/milestone_two_bangla.md`

---

## 📑 সূচিপত্র (Table of Contents)
1. [অথেনটিকেশন বনাম অথোরাইজেশন: এয়ারপোর্ট মানসিক মডেল](#১-অথেনটিকেশন-বনাম-অথোরাইজেশন-এয়ারপোর্ট-মানসিক-মডেল)
2. [ক্রিপ্টোগ্রাফিক পাসওয়ার্ড সিকিউরিটি: Bcrypt কেন?](#২-ক্রিপ্টোগ্রাফিক-পাসওয়ার্ড-সিকিউরিটি-bcrypt-কেন)
3. [JSON Web Tokens (JWT) ও ডুয়াল-টোকেন রোটেশন প্যাটার্ন](#৩-json-web-tokens-jwt-ও-ডুয়াল-টোকেন-রোটেশন-প্যাটার্ন)
4. [NestJS সিকিউরিটি পাইপলাইন: গার্ডস, স্ট্র্যাটেজি ও ডেকোরেটরস](#৪-nestjs-সিকিউরিটি-পাইপলাইন-গার্ডস-স্ট্র্যাটেজি-ও-ডেকোরেটরস)
   - [৪.১ `jwt.strategy.ts` লাইন-বাই-লাইন](#৪১-jwtstrategyts-লাইন-বাই-লাইন)
   - [৪.২ `roles.guard.ts` ও `@Roles()` ডেকোরেটর](#৪২-rolesguardts-ও-roles-ডেকোরেটর)
   - [৪.৩ মাল্টি-টেন্যান্ট আইসোলেশন: `tenant.guard.ts`](#৪৩-মাল্টি-টেন্যান্ট-আইসোলেশন-tenantguardts)
   - [৪.৪ প্যারামিটার এক্সট্রাকশন: `@CurrentUser()`](#৪৪-প্যারামিটার-এক্সট্রাকশন-currentuser)
5. [দুই-ধাপের প্রাতিষ্ঠানিক ইমেইল পিন ভেরিফিকেশন ইঞ্জিন ($0 খরচে Gmail SMTP)](#৫-দুই-ধাপের-প্রাতিষ্ঠানিক-ইমেইল-পিন-ভেরিফিকেশন-ইঞ্জিন-0-খরচে-gmail-smtp)
   - [৫.১ `EmailVerificationPin` ডাটাবেজ মডেল](#৫১-emailverificationpin-ডাটাবেজ-মডেল)
   - [৫.২ CSPRNG পিন জেনারেশন বনাম সাধারণ Math.random()](#৫২-csprng-পিন-জেনারেশন-বনাম-সাধারণ-mathrandom)
   - [৫.৩ ক্রিপ্টোগ্রাফিক SHA-256 ওয়ান-ওয়ে হ্যাশিং](#৫৩-ক্রিপ্টোগ্রাফিক-sha-256-ওয়ান-ওয়ে-হ্যাশিং)
   - [৫.৪ ৫-অ্যাটেম্পট ব্রুট-ফোর্স লিমিট ও ৬০ সেকেন্ডের কুলডাউন](#৫৪-৫-অ্যাটেম্পট-ব্রুট-ফোর্স-লিমিট-ও-৬০-সেকেন্ডের-কুলডাউন)
   - [৫.৫ জিরো-কনফিগ ডেভেলপমেন্ট কনসোল লগার ফলব্যাক](#৫৫-জিরো-কনফিগ-ডেভেলপমেন্ট-কনসোল-লগার-ফলব্যাক)
6. [পাসওয়ার্ড রিকভারি লাইফসাইকেল (Forgot & Reset Password)](#৬-পাসওয়ার্ড-রিকভারি-লাইফসাইকেল-forgot--reset-password)
7. [মেটাডেটা ও ব্যাচ ইঞ্জিন (`MetaModule`) লাইন-বাই-লাইন ব্যবচ্ছেদ](#৭-মেটাডেটা-ও-ব্যাচ-ইঞ্জিন-metamodule-লাইন-বাই-লাইন-ব্যবচ্ছেদ)
   - [৭.১ `AcademicBatch` মডেল ও PostgreSQL Native Array](#৭১-academicbatch-মডেল-ও-postgresql-native-array)
   - [৭.২ Data Transfer Objects (`create-batch.dto.ts`)](#৭২-data-transfer-objects-create-batchdtots)
   - [৭.৩ কন্ট্রোলার লেয়ার (`meta.controller.ts`) লাইন-বাই-লাইন](#৭৩-কন্ট্রোলার-লেয়ার-metacontrollerts-লাইন-বাই-লাইন)
   - [৭.৪ সার্ভিস লেয়ার (`meta.service.ts`) লাইন-বাই-লাইন](#৭৪-সার্ভিস-লেয়ার-metaservicets-লাইন-বাই-লাইন)
   - [৭.৫ রুটিন স্লট অটো-ডিসকভারি সিঙ্ক ইঞ্জিন](#৭৫-রুটিন-স্লট-অটো-ডিসকভারি-সিঙ্ক-ইঞ্জিন)
8. [বাস্তব রিকোয়েস্টের এন্ড-টু-এন্ড ভ্রমণ কাহিনী (Traces)](#৮-বাস্তব-রিকোয়েস্টের-এন্ড-টু-এন্ড-ভ্রমণ-কাহিনী-traces)
9. [মাইলস্টোন ২ এর ভাইভা ও ইন্টারভিউ প্রস্তুতি প্রশ্নোত্তর](#৯-মাইলস্টোন-২-এর-ভাইভা-ও-ইন্টারভিউ-প্রস্তুতি-প্রশ্নোত্তর)

---

# ১. অথেনটিকেশন বনাম অথোরাইজেশন: এয়ারপোর্ট মানসিক মডেল

ব্যাকএন্ড ইঞ্জিনিয়ারিংয়ে নতুনরা প্রায়ই **Authentication (AuthN)** এবং **Authorization (AuthZ)** গুলিয়ে ফেলে। এটি বোঝার সবচেয়ে সেরা উপমা হলো বিমানবন্দরের ট্রাফিক সিস্টেম:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        এয়ারপোর্ট মানসিক মডেল                          │
├────────────────────────────────────────────────────────────────────────┤
│ ১. AUTHENTICATION (আপনি কে?):                                          │
│    এয়ারপোর্টের সিকিউরিটিতে আপনি আপনার ছবিযুক্ত আসল পাসপোর্ট দেখালেন।    │
│    অফিসার যাচাই করে নিশ্চিত হলেন আপনি সত্যিই সেই ব্যক্তি।              │
│    -> UniRoom-Live এ: ছাত্র যখন ইমেইল ও পাসওয়ার্ড দিয়ে                  │
│       POST /api/v1/auth/login এ হিট করে, সার্ভার তার Bcrypt হ্যাশ       │
│       মিলিয়ে দেখে একটি ক্রিপ্টোগ্রাফিক JWT পাসপোর্ট বানিয়ে দেয়।          │
│                                                                        │
│ ২. AUTHORIZATION (আপনার কী অধিকার আছে?):                               │
│    পাসপোর্ট দিয়ে এয়ারপোর্টে ঢোকা গেলেও আপনি যেকোনো বিমানে বা পাইলটের     │
│    ককপিটে ঢুকে যেতে পারেন না! তার জন্য আপনার বোর্ডিং পাসে নির্দিষ্ট     │
│    সিট ও পারমিশন থাকতে হবে।                                            │
│    -> UniRoom-Live এ: টোকেন থাকলেও ইউজার যদি STUDENT হয়, আমাদের       │
│       RolesGuard তাকে কখনোই সুপার এডমিনের ব্যাচ পরিবর্তন বা ডিলিট       │
│       করতে দেবে না (HTTP 403 Forbidden)।                               │
└────────────────────────────────────────────────────────────────────────┘
```

---

# ২. ক্রিপ্টোগ্রাফিক পাসওয়ার্ড সিকিউরিটি: Bcrypt কেন?

### প্লেইন টেক্সট পাসওয়ার্ড কেন রাখা যাবে না?
ডাটাবেজে যদি পাসওয়ার্ড সরাসরি প্লেইন টেক্সটে রাখা হয় (`"Password123!"`), ডাটাবেজ কখনো লিক হলে সকল ইউজারের একাউন্ট এবং সেই সাথে তাদের অন্য সব অ্যাকাউন্টের নিরাপত্তা নিমেষেই ধ্বংস হয়ে যায়।

### দ্রুতগতির অ্যালগরিদম (MD5 বা SHA-256) কেন পাসওয়ার্ডে ব্যবহার করা হয় না?
* SHA-256 ডাটা ইন্টেগ্রিটির জন্য চমৎকার, কিন্তু পাসওয়ার্ডের জন্য বিপজ্জনকভাবে দ্রুত।
* আধুনিক একটি GPU প্রতি সেকেন্ডে **১০ বিলিয়নের বেশি** SHA-256 হ্যাশ গণনা করতে পারে।
* হ্যাকাররা **Rainbow Table** (কোটি কোটি পাসওয়ার্ডের প্রি-কম্পিউটেড হ্যাশ ডিকশনারি) দিয়ে চোখের পলকে SHA-256 ভেঙে ফেলে।

### UniRoom-Live এ Bcrypt কীভাবে সুরক্ষা দেয়:
1. **অ্যাডাপ্টিভ ওয়ার্ক ফ্যাক্টর (`saltRounds = 10`):**
   * এটি ইচ্ছাকৃতভাবে হ্যাশিং প্রসেসকে $2^{10} = 1,024$ বার চক্রে চালায়।
   * প্রতিটি পাসওয়ার্ড যাচাই করতে সার্ভারে প্রায় ১০০ মিলিসেকেন্ড সময় লাগে। একজন মানুষের জন্য ১০০ মিলিসেকেন্ড অনুভব করা অসম্ভব, কিন্তু হ্যাকারের অটোমেটেড ব্রুট-ফোর্স স্ক্রিপ্টকে এটি সম্পূর্ণ থামিয়ে দেয়।
2. **ক্রিপ্টোগ্রাফিক সল্ট (Salt):**
   * Bcrypt প্রতিটি ইউজারের জন্য স্বয়ংক্রিয়ভাবে ১২৮-বিটের ইউনিক র‍্যান্ডম সল্ট যোগ করে।
   * ৫০০ জন শিক্ষার্থী যদি একই পাসওয়ার্ড `"Password123!"` দেয়, ডাটাবেজে প্রত্যেকের হ্যাশ স্ট্রিং হবে সম্পূর্ণ ভিন্ন। ফলে রেইনবো টেবিল দিয়ে হ্যাক করা ১০০% অসম্ভব!

---

# ৩. JSON Web Tokens (JWT) ও ডুয়াল-টোকেন রোটেশন প্যাটার্ন

### একটি JWT এর অভ্যন্তরীণ গঠন:
একটি JWT তিনটি অংশে বিভক্ত থাকে, যা ডট (`.`) দিয়ে আলাদা করা:
`Header.Payload.Signature`

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1dWlkLTIwMjYiLCJlbWFpbCI6InRhbnZpckB1dHRhcmEuZWR1LmJkIiwicm9sZSI6IlNVUEVSX0FETUlOIn0.CryptographicSignature
```

### ডুয়াল-টোকেন আর্কিটেকচার:
1. **শর্ট-লিভড এক্সেস টোকেন (১৫ মিনিট):** এটি স্টেটলেস এবং সার্ভার সিক্রেট দিয়ে ক্রিপ্টোগ্রাফিক সাইন করা। পাবলিক ওয়াইফাইয়ে প্যাকেট স্নাইফিং হলেও ১৫ মিনিট পর এটি অকেজো হয়ে যায়।
2. **লং-লিভড রিফ্রেশ টোকেন (৭ দিন):** ডাটাবেজে সেভ থাকে। ফলে শিক্ষার্থীকে বারবার পাসওয়ার্ড টাইপ করতে হয় না।
3. **টোকেন রোটেশন (Token Rotation):** প্রতিবার রিফ্রেশ এপিআই কল হলে পুরনো রিফ্রেশ টোকেনটি নষ্ট করে সম্পূর্ণ নতুন একটি টোকেন পেয়ার দেওয়া হয়। যদি হ্যাকার কোনো চুরি করা টোকেন ব্যবহারের চেষ্টা করে, সিস্টেমের অ্যানোমালি ডিটেকশন সাথে সাথে ওই সেশন বাতিল করে দেয়।

---

# ৪. NestJS সিকিউরিটি পাইপলাইন: গার্ডস, স্ট্র্যাটেজি ও ডেকোরেটরস

## ৪.১ `jwt.strategy.ts` লাইন-বাই-লাইন
ফাইল: [`backend/src/modules/auth/strategies/jwt.strategy.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/auth/strategies/jwt.strategy.ts)

```typescript
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    const secret = configService.get<string>('JWT_SECRET');
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: JwtPayload) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: { id: true, email: true, fullName: true, role: true, universityId: true, isEmailVerified: true },
    });

    if (!user) {
      throw new UnauthorizedException('User account no longer exists');
    }

    return user; // স্বয়ংক্রিয়ভাবে request.user অবজেক্টে বসে যায়!
  }
}
```
* **`ExtractJwt.fromAuthHeaderAsBearerToken()`**: রিকোয়েস্টের হেডার থেকে `Authorization: Bearer <token>` স্বয়ংক্রিয়ভাবে পার্স করে।
* **`ignoreExpiration: false`**: মেয়াদোত্তীর্ণ টোকেন এলে সার্ভার নিজে থেকেই `401 Unauthorized` ফেরত দেয়।
* **`validate(payload)`**: টোকেন ভ্যালিড হলে ডাটাবেজ থেকে ইউজারের অস্তিত্ব নিশ্চিত করে এবং তাকে `request.user` এ যুক্ত করে দেয়।

---

## ৪.২ `roles.guard.ts` ও `@Roles()` ডেকোরেটর
ফাইল: [`backend/src/common/guards/roles.guard.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/guards/roles.guard.ts)

```typescript
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles) return true; // কোনো রেস্ট্রিকশন নেই

    const { user } = context.switchToHttp().getRequest();
    const hasRole = requiredRoles.includes(user.role as Role);

    if (!hasRole) {
      throw new ForbiddenException(
        `Role '${user.role}' is not authorized to access this resource. Required role(s): [${requiredRoles.join(', ')}]`,
      );
    }

    return true;
  }
}
```
* **`Reflector`**: রুটের ওপর লাগানো `@Roles(Role.SUPER_ADMIN)` মেটাডেটা পড়ে।
* **Early Halting**: ইউজারের রোল উপযুক্ত না হলে রিকোয়েস্ট মাঝপথেই আটকে যায় এবং `403 Forbidden` দেয়। কন্ট্রোলারের কোনো কোড এক্সিকিউটই হয় না।

---

## ৪.৩ মাল্টি-টেন্যান্ট আইসোলেশন: `tenant.guard.ts`
ফাইল: [`backend/src/common/guards/tenant.guard.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/guards/tenant.guard.ts)
* নিশ্চিত করে যে উত্তরা ইউনিভার্সিটির কোনো ছাত্র বা সিআর ভুল করেও অন্য বিশ্ববিদ্যালয়ের ডেটা দেখতে বা এডিট করতে পারবে না।

---

## ৪.৪ প্যারামিটার এক্সট্রাকশন: `@CurrentUser()`
ফাইল: [`backend/src/common/decorators/current-user.decorator.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/decorators/current-user.decorator.ts)
* কন্ট্রোলারে আর কষ্ট করে `req.user.id` লিখতে হয় না। সরাসরি `@CurrentUser('id') userId: string` লিখলেই ইউজার আইডি পাওয়া যায়।

---

# ৫. দুই-ধাপের প্রাতিষ্ঠানিক ইমেইল পিন ভেরিফিকেশন ইঞ্জিন ($0 খরচে Gmail SMTP)

## ৫.১ `EmailVerificationPin` ডাটাবেজ মডেল
ফাইল: [`backend/prisma/schema.prisma`](file:///e:/Varsity%20Project/UniRoom-Live/backend/prisma/schema.prisma)

```prisma
model EmailVerificationPin {
  id        String   @id @default(uuid())
  email     String
  pinHash   String
  expiresAt DateTime
  attempts  Int      @default(0)
  createdAt DateTime @default(now())

  @@index([email])
  @@map("email_verification_pins")
}
```

---

## ৫.২ CSPRNG পিন জেনারেশন বনাম সাধারণ Math.random()
```typescript
private generateSixDigitPin(): string {
  return crypto.randomInt(100000, 1000000).toString();
}
```
* **`Math.random()` কেন নয়?**  
  `Math.random()` হলো সিউডো-র‍্যান্ডম। গাণিতিক ফর্মুলা মেনে চলায় পূর্বের আউটপুট থেকে হ্যাকাররা ভবিষ্যৎ পিন অনুমান করতে পারে।
* **`crypto.randomInt` কেন?**  
  অপারেটিং সিস্টেমের হার্ডওয়্যার এন্ট্রপি (CSPRNG) থেকে র‍্যান্ডমনেস নেয়, ফলে এই পিন অনুমান করা গাণিতিকভাবে অসম্ভব।

---

## ৫.৩ ক্রিপ্টোগ্রাফিক SHA-256 ওয়ান-ওয়ে হ্যাশিং
```typescript
const pin = this.generateSixDigitPin();
const pinHash = crypto.createHash('sha256').update(pin).digest('hex');
```
* ডাটাবেজে কখনো প্লেইন টেক্সট ওটিপি থাকে না। সার্ভার ডাটাবেজ লিক হলেও কোনো আক্রমণকারী আসল পিন দেখতে পারে না।

---

## ৫.৪ ৫-অ্যাটেম্পট ব্রুট-ফোর্স লিমিট ও ৬০ সেকেন্ডের কুলডাউন
1. **৫-অ্যাটেম্পট সীমা:** প্রতিটি ভুল পিনে `attempts` বাড়ে। ৫ বার ভুল হলেই পিনটি ডাটাবেজ থেকে মুছে যায়।
2. **৬০ সেকেন্ডের কুলডাউন:** স্প্যামারদের বারবার ক্লিক করে জিমেইলের ৫০০ ইমেইলের ফ্রি কোটা শেষ করা থেকে রক্ষা করে।

---

## ৫.৫ জিরো-কনফিগ ডেভেলপমেন্ট কনসোল লগার ফলব্যাক
ফাইল: [`backend/src/modules/email/email.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/email/email.service.ts)
* যদি কোনো ডেভেলপার এখনো `.env` এ এসএমটিপি পাসওয়ার্ড না দেয়, সার্ভার ক্র্যাশ করবে না। পিনটি সুন্দরভাবে টার্মিনাল কনসোলে প্রিন্ট হয়ে যাবে। ফলে অফলাইনেও টেস্টিং চলতে থাকবে।

---

# ৬. পাসওয়ার্ড রিকভারি লাইফসাইকেল (Forgot & Reset Password)

```mermaid
sequenceDiagram
    actor User as Mobile App
    participant API as NestJS AuthService
    participant Mail as Gmail SMTP (Nodemailer)
    participant DB as Neon PostgreSQL

    User->>API: POST /auth/forgot-password { email }
    API->>DB: ইউজার চেক ও ৬০ সেকেন্ডের কুলডাউন পরীক্ষা
    API->>DB: PasswordResetPin টেবিলে হ্যাশ সেভ (১০ মিনিট)
    API->>Mail: সিকিউরিটি অ্যালার্ট HTML ইমেইল পাঠানো
    API-->>User: 200 OK ("Reset PIN sent")

    User->>API: POST /auth/verify-reset-pin { email, pin }
    API->>DB: হ্যাশ যাচাই ও ৫-বারের ভুল ট্রাই পরীক্ষা
    API-->>User: 200 OK ("PIN verified")

    User->>API: POST /auth/reset-password { email, pin, newPassword }
    API->>DB: চূড়ান্ত পিন যাচাই ও নতুন পাসওয়ার্ড Bcrypt দিয়ে হ্যাশ করা
    API->>DB: user.passwordHash আপডেট ও ব্যবহৃত পিন ডিলিট
    API-->>User: 200 OK ("Password reset successfully")
```

---

# ৭. মেটাডেটা ও ব্যাচ ইঞ্জিন (`MetaModule`) লাইন-বাই-লাইন ব্যবচ্ছেদ

## ৭.১ `AcademicBatch` মডেল ও PostgreSQL Native Array

```prisma
model AcademicBatch {
  id           String     @id @default(uuid())
  departmentId String
  department   Department @relation(fields: [departmentId], references: [id], onDelete: Cascade)
  name         String     // যেমন: "68", "67", "Spring-24"
  sections     String[]   // PostgreSQL native text array: ["A", "B", "C"]
  isActive     Boolean    @default(true)
  createdAt    DateTime   @default(now())
  updatedAt    DateTime   @updatedAt

  @@unique([departmentId, name])
  @@index([departmentId])
  @@map("academic_batches")
}
```

### পোস্টগ্রেস্কেল নেটিভ অ্যারের সুবিধা:
আলাদা জয়েন টেবিল বানালে প্রতিবার ডাটাবেজে ব্যয়বহুল SQL `JOIN` কুয়েরি চালাতে হয়। নেটিভ `text[]` অ্যারে ব্যবহারের ফলে একই রো-তে সব সেকশন থাকে, যার ফলে **জিরো-ল্যাটেন্সিতে একক কুয়েরিতে** সমস্ত ডেটা রিড করা যায়।

---

## ৭.২ Data Transfer Objects (`create-batch.dto.ts`)
ফাইল: [`backend/src/modules/meta/dto/create-batch.dto.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/meta/dto/create-batch.dto.ts)

```typescript
export class CreateAcademicBatchDto {
  @ApiProperty({ example: 'CSE', description: 'Department ID' })
  @IsString()
  @IsNotEmpty({ message: 'Department ID is required' })
  departmentId!: string;

  @ApiProperty({ example: '68', description: 'Academic batch name' })
  @IsString()
  @IsNotEmpty({ message: 'Batch name is required' })
  name!: string;

  @ApiProperty({ example: ['A', 'B', 'C'], description: 'List of active sections' })
  @IsArray({ message: 'Sections must be an array of strings' })
  @IsString({ each: true, message: 'Each section must be a string' })
  @ArrayNotEmpty({ message: 'At least one section must be specified' })
  sections!: string[];

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
```

---

## ৭.২ হায়ারার্কিক্যাল ডাটা ট্রান্সফার অবজেক্ট (`create-batch.dto.ts`)
ফাইল: [`backend/src/modules/meta/dto/create-batch.dto.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/meta/dto/create-batch.dto.ts)

সুপার এডমিন যাতে ডাটাবেজের দুর্বোধ্য UUID খোঁজাখুঁজি না করেই অত্যন্ত সহজে এবং দ্রুততম সময়ে রুটিন বা ব্যাচ ইনপুট দিতে পারেন, সেজন্য আমরা একটি চমৎকার হায়ারার্কিক্যাল DTO আর্কিটেকচার তৈরি করেছি:  
`University` $\to$ `Department` $\to$ `List of Batches (with list of sections)`

```typescript
// ১. প্রতিটি ব্যাচ আইটেমের DTO (নাম এবং সেকশনের তালিকা)
export class BatchItemDto {
  @ApiProperty({ example: '68', description: 'ব্যাচের নম্বর বা নাম' })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: ['A', 'B', 'C'], description: 'এই ব্যাচের সেকশনগুলোর তালিকা' })
  @IsArray()
  @IsString({ each: true })
  @ArrayNotEmpty()
  sections!: string[];

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

// ২. ডিপার্টমেন্ট অনুযায়ী ব্যাচ ইনসার্ট DTO (University -> Department -> Batches)
export class CreateAcademicBatchDto {
  @ApiPropertyOptional({ example: 'UU', description: 'বিশ্ববিদ্যালয়ের কোড (যেমন: "UU"), নাম বা UUID' })
  @IsOptional()
  @IsString()
  university?: string;

  @ApiPropertyOptional({ example: 'CSE', description: 'ডিপার্টমেন্ট কোড (যেমন: "CSE"), নাম বা UUID' })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    type: [BatchItemDto],
    description: 'উক্ত ডিপার্টমেন্টের অধীনস্থ ব্যাচ ও সেকশনগুলোর বাল্ক তালিকা',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BatchItemDto)
  batches?: BatchItemDto[];

  // সিঙ্গেল ব্যাচ তৈরির ফলব্যাক ফিল্ডসমূহ
  @ApiPropertyOptional({ example: '68' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: ['A', 'B'] })
  @IsOptional()
  @IsArray()
  sections?: string[];

  @ApiPropertyOptional({ description: 'সরাসরি ডিপার্টমেন্ট UUID দেওয়ার সুবিধা' })
  @IsOptional()
  @IsString()
  departmentId?: string;
}

// ৩. সম্পূর্ণ বিশ্ববিদ্যালয়ের সমস্ত ডিপার্টমেন্ট ও ব্যাচের ট্রি একসাথে সিঙ্ক করার DTO
export class UniversityCohortTreeDto {
  @ApiProperty({ example: 'UU', description: 'বিশ্ববিদ্যালয়ের কোড বা নাম' })
  @IsString()
  @IsNotEmpty()
  university!: string;

  @ApiProperty({ type: [DepartmentBatchesDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DepartmentBatchesDto)
  departments!: DepartmentBatchesDto[];
}
```

---

## ৭.৩ কন্ট্রোলার লেয়ার (`meta.controller.ts`) লাইন-বাই-লাইন
ফাইল: [`backend/src/modules/meta/meta.controller.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/meta/meta.controller.ts)

* **পাবলিক এন্ডপয়েন্ট (`GET /meta/registration-options`):**  
  নতুন শিক্ষার্থী বা সিআর রেজিস্ট্রেশনের সময় বিশ্ববিদ্যালয়, ডিপার্টমেন্ট, ব্যাচ ও সেকশনের ক্যাসকেডিং ড্রপডাউন লোড করার জন্য কোনো টোকেন ছাড়াই উন্মুক্ত।
* **এডমিন ফিল্টার কুয়েরি (`GET /admin/batches?university=UU&department=CSE`):**  
  সুপার এডমিন সরাসরি মানবিক কোড (`"UU"`, `"CSE"`) দিয়ে কুয়েরি করে ওই ডিপার্টমেন্টের সমস্ত ব্যাচের বর্তমান অবস্থা দেখতে পারেন।
* **হায়ারার্কিক্যাল ইনসার্ট (`POST /admin/batches`):**  
  কঠোরভাবে `@Roles(Role.SUPER_ADMIN)` দিয়ে লক করা। এডমিন এক কলেই একটি নির্দিষ্ট ডিপার্টমেন্টের অধীনে যত খুশি ব্যাচ ও সেকশন পুশ করতে পারেন।
* **ইউনিভার্সিটি ট্রি সিঙ্ক (`POST /admin/batches/university-tree`):**  
  নতুন সেমিস্টার শুরু হলে বা নতুন বিশ্ববিদ্যালয় প্ল্যাটফর্মে অনবোর্ড করার সময় এডমিন একটিমাত্র JSON রিকোয়েস্টে সব ডিপার্টমেন্টের সমস্ত ব্যাচ ডাটাবেজে ম্যাপিং করে ফেলতে পারেন!

---

## ৭.৪ সার্ভিস লেয়ার (`meta.service.ts`): ইউনিভার্সাল এন্টিটি রিজলভার ও অ্যাটমিক আপসার্ট
ফাইল: [`backend/src/modules/meta/meta.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/meta/meta.service.ts)

### ১. ইউনিভার্সাল এন্টিটি রিজলভার (`resolveDepartment`):
প্র্যাক্টিক্যাল সফটওয়্যারে এডমিনদের কখনোই ডাটাবেজ থেকে UUID কপি-পেস্ট করা উচিত নয়। আমাদের রিজলভার স্বয়ংক্রিয়ভাবে কেস-ইনসেনসিটিভ কোড (`"UU"`, `"cse"`) বা নাম দিয়ে ডাটাবেজ থেকে আসল রেকর্ড খুঁজে নেয়:
```typescript
private async resolveDepartment(options: {
  university?: string;
  department?: string;
  departmentId?: string;
}) {
  // ১. ইনপুট দেওয়া ইউনিভার্সিটি কোড বা নাম দিয়ে ইউনিভার্সিটি বের করা
  if (uniInput) {
    const university = await this.prisma.university.findFirst({
      where: {
        OR: [
          { id: uniInput },
          { code: { equals: uniInput, mode: 'insensitive' } },
          { name: { contains: uniInput, mode: 'insensitive' } },
        ],
      },
    });
    if (!university) {
      throw new NotFoundException(`University '${uniInput}' not found.`);
    }
  }
  // ২. ওই বিশ্ববিদ্যালয়ের আন্ডারে ডিপার্টমেন্ট কোড বা নাম দিয়ে ডিপার্টমেন্ট বের করা
  ...
}
```

### ২. সেকশন স্যানিটাইজেশন এবং অ্যাটমিক `upsert`:
এডমিন যদি ভুল করে সেকশন ইনপুটে ছোটহাতের অক্ষর বা ডুপ্লিকেট দিয়ে দেন (যেমন: `['A', 'b', 'B', 'a']`), আমাদের সার্ভিস লেয়ার ডাটাবেজে পাঠানোর আগেই স্বয়ংক্রিয়ভাবে ক্লিন করে ফেলে:
```typescript
// ট্রিম, আপারকেস রূপান্তর, Set দিয়ে ডুপ্লিকেট রিমুভ ও বর্ণানুক্রমিক সর্টিং:
const cleanSections = Array.from(
  new Set(b.sections.map((s) => s.trim().toUpperCase())),
).sort(); // ফলাফল: ['A', 'B']

const record = await this.prisma.academicBatch.upsert({
  where: {
    departmentId_name: {
      departmentId: department.id,
      name: b.name.trim(),
    },
  },
  update: { sections: cleanSections, isActive: b.isActive ?? true },
  create: {
    departmentId: department.id,
    name: b.name.trim(),
    sections: cleanSections,
    isActive: b.isActive ?? true,
  },
});
```
* **কেন `upsert` ও `departmentId_name`?**  
  প্রিজমা স্কিমায় `@@unique([departmentId, name])` দেওয়া আছে। ফলে এডমিন একই রিকোয়েস্ট একাধিকবার চালালেও ডাটাবেজে ক্র্যাশ বা ডুপ্লিকেট কী ভায়োলেশন ইরর (`23505`) হবে না; ডাটাবেজ বুদ্ধিমানের মতো বিদ্যমান রো-টিকে নতুন সেকশন দিয়ে আপডেট করে নিবে।

---

## ৭.৫ সুপার এডমিনের জন্য বাস্তব JSON পেলোড উদাহরণ

### উদাহরণ ১: সিএসই ডিপার্টমেন্টের জন্য একসাথে একাধিক ব্যাচ এন্ট্রি
**এন্ডপয়েন্ট:** `POST /api/v1/admin/batches`  
**হেডার:** `Authorization: Bearer <SUPER_ADMIN_JWT>`  
**বডি:**
```json
{
  "university": "UU",
  "department": "CSE",
  "batches": [
    { "name": "68", "sections": ["A", "B", "C"] },
    { "name": "69", "sections": ["A", "B"] },
    { "name": "70", "sections": ["A", "B", "C", "D"] }
  ]
}
```

### উদাহরণ ২: পুরো বিশ্ববিদ্যালয়ের সমস্ত ডিপার্টমেন্ট ও ব্যাচের ট্রি একসাথে সিঙ্ক
**এন্ডপয়েন্ট:** `POST /api/v1/admin/batches/university-tree`  
**হেডার:** `Authorization: Bearer <SUPER_ADMIN_JWT>`  
**বডি:**
```json
{
  "university": "UU",
  "departments": [
    {
      "department": "CSE",
      "batches": [
        { "name": "68", "sections": ["A", "B", "C"] },
        { "name": "69", "sections": ["A", "B"] }
      ]
    },
    {
      "department": "EEE",
      "batches": [
        { "name": "64", "sections": ["A", "B"] }
      ]
    }
  ]
}
```

---

## ৭.৬ রুটিন স্লট অটো-ডিসকভারি সিঙ্ক ইঞ্জিন
```typescript
async syncBatchesFromRoutineSlots(
  slots: Array<{ departmentId: string; batch: string; section: string }>,
) {
  const batchMap = new Map<string, { departmentId: string; batch: string; sections: Set<string> }>();

  for (const slot of slots) {
    const key = `${slot.departmentId}_${slot.batch.trim()}`;
    if (!batchMap.has(key)) {
      batchMap.set(key, {
        departmentId: slot.departmentId,
        batch: slot.batch.trim(),
        sections: new Set<string>(),
      });
    }
    batchMap.get(key)!.sections.add(slot.section.trim().toUpperCase());
  }

  const results = [];
  for (const item of batchMap.values()) {
    const sectionList = Array.from(item.sections).sort();
    const record = await this.prisma.academicBatch.upsert({
      where: {
        departmentId_name: { departmentId: item.departmentId, name: item.batch },
      },
      update: { sections: { push: sectionList }, isActive: true },
      create: { departmentId: item.departmentId, name: item.batch, sections: sectionList, isActive: true },
    });
    results.push(record);
  }
  return results;
}
```
* **ইন-মেমোরি হ্যাশ ম্যাপ গ্রুপিং:** হাজার হাজার রুটিন স্লটকে আগে মেমোরিতে গ্রুপ করে নেয়, ফলে শত শত ডাটাবেজ রাউন্ড-ট্রিপ কমে মাত্র কয়েকটি আপসার্টে নেমে আসে (৫০ গুণ দ্রুত)।
* **অ্যাটমিক `upsert` ও `push`:** পূর্বের কোনো ব্যাচ থাকলে নতুন সেকশন তার সাথে অ্যাপেন্ড হয়ে যায়।

---

# ৮. বাস্তব রিকোয়েস্টের এন্ড-টু-এন্ড ভ্রমণ কাহিনী (Traces)

### ট্রেস ১: নতুন ইউজার রেজিস্ট্রেশন ও পিন ভেরিফিকেশন
1. ক্লায়েন্ট `POST /api/v1/auth/register` পাঠায়।
2. `ValidationPipe` ইনপুট ভ্যালিডেশন করে।
3. `AuthService` পাসওয়ার্ড Bcrypt দিয়ে ১০ রাউন্ডে হ্যাশ করে।
4. ইউজার সেভ হয় `isEmailVerified = false` অবস্থায়।
5. ৬ ডিজিটের CSPRNG পিন তৈরি হয়ে SHA-256 দিয়ে হ্যাশ হয়ে `email_verification_pins` এ ১০ মিনিটের জন্য সেভ হয়।
6. Nodemailer জিমেইল দিয়ে ছাত্রদের ইমেইলে HTML ওটিপি পাঠায়।
7. ছাত্র `POST /api/v1/auth/verify-email` এ পিন সাবমিট করে।
8. সার্ভার হ্যাশ চেক করে ইউজারের `isEmailVerified = true` করে এবং JWT টোকেন পেয়ার প্রদান করে।

### ট্রেস ২: ইমেইল ভেরিফাই না করা ইউজারের লগইন চেষ্টা
1. ইউজার `POST /api/v1/auth/login` পাঠায়।
2. পাসওয়ার্ড মিললেও ইমেইল ভেরিফিকেশন গার্ড দেখে `isEmailVerified === false`।
3. সার্ভার সাথে সাথে `401 Unauthorized` ফেরত দেয়।
4. মোবাইল অ্যাপ একটি ইন্টারঅ্যাক্টিভ স্ন্যাকবার দেখায় যা ক্লিক করলে সরাসরি ওটিপি স্ক্রিনে যাওয়া যায়।

### ট্রেস ৩: সাধারণ ছাত্র যখন সুপার এডমিন রুটে ঢোকার চেষ্টা করে
1. ছাত্র তার টোকেন নিয়ে `POST /api/v1/admin/batches` এ কল দেয়।
2. `JwtAuthGuard` টোকেন আসল নিশ্চিত করে।
3. `RolesGuard` দেখে রুটে সিলমোহর লাগানো আছে `SUPER_ADMIN`, কিন্তু ইউজারের রোল `STUDENT`।
4. কন্ট্রোলারের কাছে রিকোয়েস্ট যাওয়ার আগেই গার্ড `403 Forbidden` ছুঁড়ে দেয়।

---

# ৯. মাইলস্টোন ২ এর ভাইভা ও ইন্টারভিউ প্রস্তুতি প্রশ্নোত্তর

### ❓ প্রশ্ন ১: "ডিপার্টমেন্ট অনুযায়ী ব্যাচ আলাদা করার আর্কিটেকচারাল কারণ কী?"
> **উত্তর:** "বিশ্ববিদ্যালয়ের ডিপার্টমেন্টগুলো স্বাধীনভাবে পরিচালিত হয়। সিএসই বিভাগের ৬৮তম ব্যাচের সেকশন ও রুটিন কখনোই ট্রিপল-ই বিভাগের ৬৮তম ব্যাচের সাথে মিলবে না। তাই `AcademicBatch` মডেলে আমরা কম্পাউন্ড ইউনিক কনস্ট্রেইন্ট `@@unique([departmentId, name])` ব্যবহার করেছি। এর ফলে এক ডিপার্টমেন্টে ডুপ্লিকেট ব্যাচ তৈরি হওয়া রোধ হয়, কিন্তু ভিন্ন ডিপার্টমেন্ট একই ব্যাচ নম্বর শেয়ার করতে পারে।"

### ❓ প্রশ্ন ২: "সেকশনের জন্য আলাদা টেবিল না বানিয়ে পোস্টগ্রেস্কেলের নেটিভ `text[]` অ্যারে কেন নেওয়া হলো?"
> **উত্তর:** "সেকশনের মতো সাধারণ তথ্যের জন্য আলাদা জয়েন টেবিল বানালে প্রতিবার ডাটাবেজে ভারী SQL `JOIN` অপারেশন চালাতে হয়, যা সিস্টেমের রেসপন্স টাইম বাড়িয়ে দেয়। কিন্তু পোস্টগ্রেস্কেলের নেটিভ `text[]` অ্যারে ব্যবহার করার ফলে পুরো ব্যাচের সমস্ত সেকশন একটিমাত্র রো-তেই জমা থাকে। ফলে অতিরিক্ত কোনো টেবিল জয়েন ছাড়াই জিরো-ল্যাটেন্সিতে নিমেষেই সব সেকশন রিড করা যায়।"

### ❓ প্রশ্ন ৩: "রেজিস্ট্রেশন অপশনের এপিআই পাবলিক, কিন্তু ব্যাচ তৈরির এপিআই এডমিন-প্রটেক্টেড কেন?"
> **উত্তর:** "নতুন শিক্ষার্থী বা সিআর যখন অ্যাপে রেজিস্ট্রেশন করতে আসে, তখন সে এখনো সিস্টেমে লগইন করেনি, তাই তার কাছে কোনো JWT টোকেন নেই। তাকে সাইন-আপ ফর্মে ডিপার্টমেন্ট ও ব্যাচের ড্রপডাউন দেখাতে হবে। তাই `GET /meta/registration-options` পাবলিক রাখা হয়েছে। পক্ষান্তরে, নতুন ব্যাচ যুক্ত করা বা ডিলিট করা বিশ্ববিদ্যালয়ের সার্বিক রুটিনের উপর প্রভাব ফেলে, তাই এটি কঠোরভাবে `@Roles(Role.SUPER_ADMIN)` দিয়ে সুরক্ষিত রাখা হয়েছে।"

### ❓ প্রশ্ন ৪: "ইমেইল ভেরিফিকেশনের ওটিপি বা পিন ডাটাবেজে প্লেইন টেক্সট না রেখে হ্যাশ করে রাখা হয়েছে কেন?"
> **উত্তর:** "এটি সিকিউরিটির 'ডিফেন্স-ইন-ডেপথ' (Defense-in-Depth) মূলনীতি। যদি কোনো কারণে ডাটাবেজের রিড অ্যাক্সেস হ্যাকারদের হাতে চলে যায়, ডাটাবেজে ওটিপি প্লেইন টেক্সটে থাকলে তারা যেকোনো বৈধ ইউজারের ওটিপি দেখে তাদের একাউন্ট দখল করতে পারত। আমরা SHA-256 দিয়ে ওটিপি হ্যাশ করে রাখি, যাতে সার্ভার ডাটাবেজে শুধুই ক্রিপ্টোগ্রাফিক হ্যাশ থাকে এবং আসল পিন কেউ দেখতে না পারে।"

### ❓ প্রশ্ন ৫: "পিন তৈরিতে `Math.random()` ব্যবহার না করে `crypto.randomInt` কেন ব্যবহার করা হয়েছে?"
> **উত্তর:** "`Math.random()` হলো সিউডো-র‍্যান্ডম যা গাণিতিক অ্যালগরিদমে চলে, তাই পূর্ববর্তী আউটপুট বিশ্লেষণ করে পরবর্তী সংখ্যা অনুমান করা সম্ভব। কিন্তু `crypto.randomInt` সরাসরি অপারেটিং সিস্টেমের কার্নেল এন্ট্রপি (CSPRNG) থেকে র‍্যান্ডমনেস সংগ্রহ করে। ফলে এই ৬ ডিজিটের পিন কোনো হ্যাকারের পক্ষে অনুমান করা গাণিতিকভাবে অসম্ভব।"

---
*পরবর্তী ধাপ: [মাইলস্টোন ৩ হ্যান্ডবুক](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_three_bangla.md) (রুম ইনভেন্টরি ও রিয়েল-টাইম অ্যাভেইল্যাবিলিটি ইঞ্জিন)।*
