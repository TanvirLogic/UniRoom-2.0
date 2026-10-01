# 📘 Milestone 2: Authentication, Cryptographic Security & Metadata Engine
> **Language:** 🇬🇧 English | **বাংলা সংস্করণ:** [`milestone_two_bangla.md`](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_two_bangla.md)  
> **Target Audience:** Tanvir (Full-Stack SWE & Academic Defense Candidate)  
> **Status:** `[x]` COMPLETED  
> **File Location:** `project explanation/milestone_two.md`

---

## 📑 Table of Contents
1. [Authentication vs. Authorization: The Airport Mental Model](#1-authentication-vs-authorization-the-airport-mental-model)
2. [Cryptographic Password Security: Why Bcrypt?](#2-cryptographic-password-security-why-bcrypt)
3. [JSON Web Tokens (JWT) & Dual-Token Rotation Pattern](#3-json-web-tokens-jwt--dual-token-rotation-pattern)
4. [NestJS Security Pipeline: Guards, Strategies & Decorators](#4-nestjs-security-pipeline-guards-strategies--decorators)
   - [4.1 `jwt.strategy.ts` Line-by-Line](#41-jwtstrategyts-line-by-line)
   - [4.2 `roles.guard.ts` & `@Roles()` Decorator](#42-rolesguardts--roles-decorator)
   - [4.3 Multi-Tenant Isolation: `tenant.guard.ts`](#43-multi-tenant-isolation-tenantguardts)
   - [4.4 Parameter Extraction: `@CurrentUser()`](#44-parameter-extraction-currentuser)
5. [Two-Phase Email PIN Verification Engine ($0 Cost Gmail SMTP)](#5-two-phase-email-pin-verification-engine-0-cost-gmail-smtp)
   - [5.1 The `EmailVerificationPin` Database Model](#51-the-emailverificationpin-database-model)
   - [5.2 CSPRNG PIN Generation vs. Pseudo-Random Math.random()](#52-csprng-pin-generation-vs-pseudo-random-mathrandom)
   - [5.3 Cryptographic SHA-256 One-Way Hashing](#53-cryptographic-sha-256-one-way-hashing)
   - [5.4 5-Attempt Brute-Force Threshold & 60s Spam Cooldown](#54-5-attempt-brute-force-threshold--60s-spam-cooldown)
   - [5.5 Zero-Config Development Console Logger Fallback](#55-zero-config-development-console-logger-fallback)
6. [Password Recovery Lifecycle (Forgot & Reset Password)](#6-password-recovery-lifecycle-forgot--reset-password)
7. [Institutional Cohort & Metadata Engine (`MetaModule`)](#7-institutional-cohort--metadata-engine-metamodule)
   - [7.1 The `AcademicBatch` Database Model & PostgreSQL Native Arrays](#71-the-academicbatch-database-model--postgresql-native-arrays)
   - [7.2 Data Transfer Objects (`create-batch.dto.ts` & `update-batch.dto.ts`)](#72-data-transfer-objects-create-batchdtots--update-batchdtots)
   - [7.3 Controller Layer (`meta.controller.ts`) Line-by-Line](#73-controller-layer-metacontrollerts-line-by-line)
   - [7.4 Service Layer (`meta.service.ts`) Line-by-Line](#74-service-layer-metaservicets-line-by-line)
   - [7.5 Routine Slot Auto-Discovery Sync Engine](#75-routine-slot-auto-discovery-sync-engine)
8. [End-to-End Request Traces](#8-end-to-end-request-traces)
   - [Trace 1: Two-Phase User Registration & PIN Verification](#trace-1-two-phase-user-registration--pin-verification)
   - [Trace 2: Login Attempt by Unverified Account](#trace-2-login-attempt-by-unverified-account)
   - [Trace 3: Student Attempting to Access Super Admin Endpoint (RBAC 403)](#trace-3-student-attempting-to-access-super-admin-endpoint-rbac-403)
9. [Milestone 2 Interview & Thesis Defense Q&A](#9-milestone-2-interview--thesis-defense-qa)

---

# 1. Authentication vs. Authorization: The Airport Mental Model

In modern software engineering, beginners often conflate **Authentication (AuthN)** and **Authorization (AuthZ)**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THE AIRPORT MENTAL MODEL                        │
├────────────────────────────────────────────────────────────────────────┤
│ 1. AUTHENTICATION (Who are you?):                                      │
│    At the security checkpoint, you show your Government Passport with  │
│    your picture. The officer verifies that you are indeed who you say  │
│    you are.                                                            │
│    -> In UniRoom-Live: Sending institutional email & password to       │
│       POST /api/v1/auth/login. The server validates your Bcrypt hash   │
│       and issues a cryptographically signed JWT Passport.              │
│                                                                        │
│ 2. AUTHORIZATION (What are you allowed to do?):                        │
│    Having a valid passport gets you into the airport terminal, but it  │
│    does NOT let you fly Flight 204 or walk into the airplane cockpit!  │
│    You need a specific Boarding Pass with the right seat/clearance.    │
│    -> In UniRoom-Live: Even with a valid JWT, if your role is STUDENT, │
│       our RolesGuard prevents you from accessing POST /admin/batches   │
│       or booking faculty lounges (HTTP 403 Forbidden).                 │
└────────────────────────────────────────────────────────────────────────┘
```

---

# 2. Cryptographic Password Security: Why Bcrypt?

### Why Plaintext Passwords are a Catastrophic Flaw
Storing plaintext passwords (`"Password123!"`) exposes all users to credential stuffing and identity theft if the database is ever breached.

### Why Not Fast Hashes (MD5 or SHA-256) for Passwords?
* Modern GPUs compute **over 10 billion SHA-256 hashes per second**.
* Attackers use **Rainbow Tables** (precomputed dictionaries of billions of hashes) to reverse fast hashes in seconds.

### How Bcrypt Protects UniRoom-Live:
1. **Adaptive Work Factor (`saltRounds = 10`):**
   * Bcrypt runs $2^{10} = 1,024$ hashing iterations per password.
   * Takes ~100ms per attempt on the server: imperceptible to an individual user logging in, but completely halts automated brute-force attacks.
2. **Cryptographic Salting:**
   * Bcrypt automatically injects a unique 128-bit random salt for every user before hashing.
   * Even if 500 students select `"Password123!"`, every single hash stored in PostgreSQL will look completely different. Precomputed rainbow tables are rendered completely useless!

---

# 3. JSON Web Tokens (JWT) & Dual-Token Rotation Pattern

### The Structure of a JWT
A JWT is a compact, URL-safe string composed of three base64url-encoded parts separated by dots:
`Header.Payload.Signature`

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1dWlkLTIwMjYiLCJlbWFpbCI6InRhbnZpckB1dHRhcmEuZWR1LmJkIiwicm9sZSI6IlNVUEVSX0FETUlOIn0.CryptographicSignature
```

### The Dual-Token Lifecycle Architecture:
```mermaid
sequenceDiagram
    autonumber
    actor Client as Mobile Client (Flutter)
    participant Server as NestJS API Gateway
    participant DB as Neon PostgreSQL

    Client->>Server: POST /auth/login { email, password }
    Server->>DB: Verify credentials & email verification status
    Server->>DB: Store hashed Refresh Token
    Server-->>Client: Return Access Token (15m) + Refresh Token (7d)
    
    Note over Client,Server: For the next 15 minutes, Client makes fast stateless API calls
    Client->>Server: GET /meta/registration-options (Header: Bearer <AccessToken>)
    Server-->>Client: 200 OK (Stateless verification)

    Note over Client,Server: After 15 minutes: Access Token expires (401)
    Client->>Server: POST /auth/refresh { refreshToken }
    Server->>DB: Match refresh token & rotate with a fresh pair
    Server-->>Client: Return new Access Token (15m) + new Refresh Token (7d)
```

1. **Short-Lived Access Token (15 minutes):** Stateless and signed with `JWT_SECRET`. If intercepted on a public Wi-Fi network, the window of vulnerability is strictly limited to 15 minutes.
2. **Long-Lived Refresh Token (7 days):** Persisted in PostgreSQL. Allows legitimate mobile users to stay logged in without typing their passwords repeatedly.
3. **Token Rotation:** Every time `/auth/refresh` is called, the old refresh token is destroyed and a brand-new token pair is issued. If a stolen refresh token is reused, the anomaly triggers instant revocation of the session.

---

# 4. NestJS Security Pipeline: Guards, Strategies & Decorators

## 4.1 `jwt.strategy.ts` Line-by-Line
Located at [`backend/src/modules/auth/strategies/jwt.strategy.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/auth/strategies/jwt.strategy.ts):

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

    return user; // Automatically binds to request.user!
  }
}
```
* **`ExtractJwt.fromAuthHeaderAsBearerToken()`**: Automatically parses `Authorization: Bearer <token>`.
* **`ignoreExpiration: false`**: Rejects expired tokens automatically with HTTP 401.
* **`validate(payload)`**: Verifies that the user still exists in PostgreSQL. Returning `user` here automatically injects it into `request.user` across all downstream controllers!

---

## 4.2 `roles.guard.ts` & `@Roles()` Decorator
Located at [`backend/src/common/guards/roles.guard.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/guards/roles.guard.ts):

```typescript
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles) return true; // Public route

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
* **`Reflector`**: Reads metadata attached by the `@Roles(Role.SUPER_ADMIN)` decorator.
* **Early Halting**: If the user's role does not match, execution halts immediately with HTTP 403. The controller logic is never executed.

---

## 4.3 Multi-Tenant Isolation: `tenant.guard.ts`
Located at [`backend/src/common/guards/tenant.guard.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/guards/tenant.guard.ts):
```typescript
if (user.role === Role.SUPER_ADMIN) return true;

if (requestedUniversityId && requestedUniversityId !== user.universityId) {
  throw new ForbiddenException('Cross-tenant data violation: Access denied.');
}
```
* Ensures that a CR from Uttara University can never modify or view data belonging to another university.

---

## 4.4 Parameter Extraction: `@CurrentUser()`
Located at [`backend/src/common/decorators/current-user.decorator.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/decorators/current-user.decorator.ts):
```typescript
export const CurrentUser = createParamDecorator(
  (data: keyof JwtPayload | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return data ? request.user[data] : request.user;
  },
);
```
* Usage in controllers: `@CurrentUser('id') userId: string`. Clean, type-safe, and avoids manual typecasting.

---

# 5. Two-Phase Email PIN Verification Engine ($0 Cost Gmail SMTP)

## 5.1 The `EmailVerificationPin` Database Model
File: [`backend/prisma/schema.prisma`](file:///e:/Varsity%20Project/UniRoom-Live/backend/prisma/schema.prisma)

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

## 5.2 CSPRNG PIN Generation vs. Pseudo-Random Math.random()
```typescript
private generateSixDigitPin(): string {
  return crypto.randomInt(100000, 1000000).toString();
}
```
* **Why not `Math.random()`?**  
  `Math.random()` uses a deterministic PRNG algorithm. Given a few previous outputs, an attacker can mathematically reconstruct the internal seed state and predict future PINs.  
* **Why `crypto.randomInt`?**  
  Draws directly from the Operating System kernel's hardware entropy pool (CSPRNG), making future outputs mathematically unguessable.

---

## 5.3 Cryptographic SHA-256 One-Way Hashing
```typescript
const pin = this.generateSixDigitPin();
const pinHash = crypto.createHash('sha256').update(pin).digest('hex');
```
* Plaintext PINs are **never stored** in the database. Even if a database backup is leaked, an attacker cannot extract valid 6-digit verification codes.

---

## 5.4 5-Attempt Brute-Force Threshold & 60s Spam Cooldown
1. **5-Attempt Threshold:** Each incorrect guess increments `attempts`. Upon the 5th failed attempt, the record is immediately purged from PostgreSQL, completely closing automated brute-force attacks.
2. **60-Second Cooldown:** Prevents malicious actors or buggy clients from exhausting Gmail SMTP's 500 emails/day quota by repeatedly calling resend endpoints.

---

## 5.5 Zero-Config Development Console Logger Fallback
Located in [`email.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/email/email.service.ts):
* If SMTP credentials are not yet configured in `.env`, the PIN prints cleanly in the terminal console. Local development and automated testing are never blocked!

---

# 6. Password Recovery Lifecycle (Forgot & Reset Password)

```mermaid
sequenceDiagram
    actor User as Mobile App
    participant API as NestJS AuthService
    participant Mail as Gmail SMTP (Nodemailer)
    participant DB as Neon PostgreSQL

    User->>API: POST /auth/forgot-password { email }
    API->>DB: Check user exists & verify 60s cooldown
    API->>DB: Store hashed PIN in PasswordResetPin table (10m)
    API->>Mail: Send security recovery HTML email
    API-->>User: 200 OK ("Reset PIN sent")

    User->>API: POST /auth/verify-reset-pin { email, pin }
    API->>DB: Validate hash & verify attempts < 5
    API-->>User: 200 OK ("PIN verified")

    User->>API: POST /auth/reset-password { email, pin, newPassword }
    API->>DB: Validate PIN & hash new password with Bcrypt (10 rounds)
    API->>DB: Update user.passwordHash & delete reset PIN records
    API-->>User: 200 OK ("Password reset successfully")
```

---

# 7. Institutional Cohort & Metadata Engine (`MetaModule`)

## 7.1 The `AcademicBatch` Database Model & PostgreSQL Native Arrays

```prisma
model AcademicBatch {
  id           String     @id @default(uuid())
  departmentId String
  department   Department @relation(fields: [departmentId], references: [id], onDelete: Cascade)
  name         String     // e.g. "68", "67", "Spring-24"
  sections     String[]   // Native text array: ["A", "B", "C"]
  isActive     Boolean    @default(true)
  createdAt    DateTime   @default(now())
  updatedAt    DateTime   @updatedAt

  @@unique([departmentId, name])
  @@index([departmentId])
  @@map("academic_batches")
}
```

### Why Native `text[]` Arrays Over Join Tables?
In traditional schemas, storing sections requires a join table (`BatchSections`). To fetch 10 batches and their sections, the database must perform expensive SQL JOINs across multiple tables. Storing sections as a native PostgreSQL array (`text[]`) allows **zero-latency single-row reads** without joining extra tables.

---

## 7.2 Hierarchical Data Transfer Objects (`create-batch.dto.ts`)
File: [`backend/src/modules/meta/dto/create-batch.dto.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/meta/dto/create-batch.dto.ts)

Super Admins must never be forced to look up and copy-paste database UUIDs. To make management intuitive, the DTOs support human-readable entity references (`"UU"`, `"CSE"`), bulk batch listings, and even full university-wide tree syncing:

```typescript
// 1. Single Batch Item under a Department
export class BatchItemDto {
  @ApiProperty({ example: '68', description: 'Batch number or cohort name' })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: ['A', 'B', 'C'], description: 'List of sections in this batch' })
  @IsArray()
  @IsString({ each: true })
  @ArrayNotEmpty()
  sections!: string[];

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

// 2. Department Cohort Ingestion (University -> Department -> Batches)
export class CreateAcademicBatchDto {
  @ApiPropertyOptional({ example: 'UU', description: 'University code (e.g. "UU"), name, or UUID' })
  @IsOptional()
  @IsString()
  university?: string;

  @ApiPropertyOptional({ example: 'CSE', description: 'Department code (e.g. "CSE"), name, or UUID' })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    type: [BatchItemDto],
    description: 'Bulk array of batches with sections for this department',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BatchItemDto)
  batches?: BatchItemDto[];

  // Fallback for single batch creation
  @ApiPropertyOptional({ example: '68' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: ['A', 'B'] })
  @IsOptional()
  @IsArray()
  sections?: string[];

  @ApiPropertyOptional({ description: 'Raw department UUID fallback' })
  @IsOptional()
  @IsString()
  departmentId?: string;
}

// 3. Full University Cohort Tree Sync
export class UniversityCohortTreeDto {
  @ApiProperty({ example: 'UU', description: 'University code, name, or UUID' })
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

## 7.3 Controller Layer (`meta.controller.ts`) Line-by-Line
File: [`backend/src/modules/meta/meta.controller.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/meta/meta.controller.ts)

* **Public Endpoint (`GET /meta/registration-options`):**  
  Accessible without authentication so unregistered users can populate cascade dropdowns on sign-up: `University` $\to$ `Department` $\to$ `Batch` $\to$ `Section`.
* **Admin Query (`GET /admin/batches?university=UU&department=CSE`):**  
  Allows Super Admins to filter batches by human-readable university and department codes without touching UUIDs.
* **Hierarchical Insertion (`POST /admin/batches`):**  
  Protected by `@Roles(Role.SUPER_ADMIN)`. Accepts university, department, and a bulk list of batches and sections in one intuitive call.
* **Complete Cohort Tree Sync (`POST /admin/batches/university-tree`):**  
  Enables the Super Admin to provision or update an entire university's academic hierarchy (all departments, batches, and sections) in a single API call!

---

## 7.4 Service Layer (`meta.service.ts`): Universal Entity Resolution & Atomic Upsert
File: [`backend/src/modules/meta/meta.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/meta/meta.service.ts)

### 1. Universal Entity Resolver (`resolveDepartment`):
Eliminates UUID friction by resolving university and department from either UUID, unique code (`"UU"`, `"CSE"`), or name (case-insensitive):
```typescript
private async resolveDepartment(options: {
  university?: string;
  department?: string;
  departmentId?: string;
}) {
  // 1. Resolve university by UUID, code (case-insensitive), or name
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
  // 2. Resolve department within the university scope
  ...
}
```

### 2. Section Sanitization & Compound Unique Upsert:
Before writing to the database, sections are cleaned of duplicates, trimmed, and converted to uppercase:
```typescript
const cleanSections = Array.from(
  new Set(b.sections.map((s) => s.trim().toUpperCase())),
).sort();

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
* **Why `upsert` with `departmentId_name`?**  
  Because the Prisma schema defines `@@unique([departmentId, name])`, re-running this endpoint will safely update sections instead of throwing duplicate key violation errors (`23505`).

---

## 7.5 Practical Super Admin JSON Payloads

### Example 1: Ingesting Multiple Batches for CSE Department
**Endpoint:** `POST /api/v1/admin/batches`  
**Headers:** `Authorization: Bearer <SUPER_ADMIN_JWT>`  
**Body:**
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

### Example 2: Complete University Cohort Tree Ingestion
**Endpoint:** `POST /api/v1/admin/batches/university-tree`  
**Headers:** `Authorization: Bearer <SUPER_ADMIN_JWT>`  
**Body:**
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

## 7.6 Routine Slot Auto-Discovery Sync Engine
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
* **In-Memory Hash Map Aggregation:** Reduces hundreds of potential routine slot database round-trips down to a few batch operations.
* **Atomic `upsert` with `push`:** Seamlessly updates existing batches with newly discovered sections without overwriting historical records.

---

# 8. End-to-End Request Traces

### Trace 1: Two-Phase User Registration & PIN Verification
1. Client sends `POST /api/v1/auth/register` with student details.
2. `ValidationPipe` validates `RegisterDto`.
3. `AuthService` hashes password via `bcrypt` (10 salt rounds).
4. User record is inserted in PostgreSQL with `isEmailVerified: false`.
5. 6-digit CSPRNG PIN is generated, SHA-256 hashed, and stored in `email_verification_pins` with a 10-minute expiry.
6. `EmailService` sends responsive HTML email via Gmail SMTP.
7. User submits `POST /api/v1/auth/verify-email` with 6-digit PIN.
8. `AuthService` verifies SHA-256 hash and attempt count ($< 5$).
9. `user.isEmailVerified` is updated to `true`, PIN record is deleted, and signed JWT token pair is returned!

### Trace 2: Login Attempt by Unverified Account
1. Unverified user calls `POST /api/v1/auth/login`.
2. Password hash matches, but `user.isEmailVerified === false`.
3. Server halts execution and returns `401 Unauthorized` with clear guidance.
4. Mobile app presents an interactive SnackBar leading directly to the PIN verification screen.

### Trace 3: Student Attempting to Access Super Admin Endpoint (RBAC 403)
1. Student calls `POST /api/v1/admin/batches` with valid Bearer token.
2. `JwtAuthGuard` confirms valid token signature and attaches student user object.
3. `RolesGuard` detects route requires `SUPER_ADMIN` but user role is `STUDENT`.
4. Request is rejected with `403 Forbidden` before controller logic ever executes!

---

# 9. Milestone 2 Interview & Thesis Defense Q&A

### ❓ Question 1: "Why do we separate AcademicBatches by department?"
**Answer:**
"Departments at universities operate independently. Batch 68 in CSE has different sections, faculty routines, and class sizes than Batch 68 in EEE. Modeling `AcademicBatch` with a compound unique key `@@unique([departmentId, name])` isolates department cohorts while preventing duplicate batch numbers within the same department."

### ❓ Question 2: "Why use a native PostgreSQL `text[]` array for sections instead of an extra join table?"
**Answer:**
"In relational databases, creating a join table (`BatchSections`) for simple strings requires an expensive SQL JOIN operation on every query. Using PostgreSQL's native `text[]` array allows sections (`['A', 'B', 'C']`) to be stored directly in the `academic_batches` row, providing zero-latency single-row lookups while maintaining full type safety."

### ❓ Question 3: "Why is the registration options endpoint public while batch CRUD is protected?"
**Answer:**
"New students and CRs cannot register without seeing available departments, batches, and sections. Therefore, `GET /api/v1/meta/registration-options` is public. However, creating or modifying batches affects the institutional routine hierarchy, so `admin/batches` is strictly restricted to `Role.SUPER_ADMIN`."

### ❓ Question 4: "Why do we hash 6-digit verification PINs before storing them?"
**Answer:**
"Storing plaintext PINs in a database violates the Principle of Least Privilege and OWASP storage guidelines. If an attacker gains read access to the database (via SQL injection or backup snapshot leaks), they could hijack accounts before users verify their emails. By storing only the SHA-256 hash, the database holds zero usable credentials."

### ❓ Question 5: "Why do we use `crypto.randomInt` instead of `Math.random()`?"
**Answer:**
"`Math.random()` is a deterministic pseudo-random generator (PRNG) whose seed can be calculated by analyzing previous outputs. `crypto.randomInt` draws from the operating system's cryptographic entropy source (CSPRNG), ensuring that the generated 6-digit PINs are mathematically unguessable."

---
*Next Step: Proceed to [Milestone 3 Handbook](file:///e:/Varsity%20Project/UniRoom-Live/project%20explanation/milestone_three.md) (Room Inventory & Real-Time Availability Engine).*
