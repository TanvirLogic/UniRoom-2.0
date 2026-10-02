# 🎓 UniRoom-Live 2.0 Backend Masterclass
## Chapter 4: Authentication Module Deep Dive (`src/modules/auth/`)

The Authentication Module is where users register, verify their university email addresses, log in, manage tokens, reset passwords, and load their classmate rosters.

Let's break down the DTOs, the Controller, and the Service line by line.

---

## 1. What is a DTO? (Data Transfer Object)

When a mobile app sends data over HTTP (like an email and password), it sends raw JSON text.
A **DTO (Data Transfer Object)** defines:
1. What shape of data the server expects.
2. The rules each field must follow (must be a valid email, password must be $\ge 6$ chars, role must be valid enum).

In NestJS, we use the `class-validator` library to decorate DTO fields.

### Example: `src/modules/auth/dto/register.dto.ts` Line by Line
```typescript
import { IsEmail, IsNotEmpty, IsString, MinLength, IsEnum, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Role } from '@prisma/client';

export class RegisterDto {
  @ApiProperty({ example: 'student@uttara.edu.bd' })
  @IsEmail({}, { message: 'Must be a valid email address' })
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'SecurePassword123' })
  @IsString()
  @MinLength(6, { message: 'Password must be at least 6 characters long' })
  password: string;

  @ApiProperty({ example: 'Md Tanvir Ahmed' })
  @IsString()
  @IsNotEmpty({ message: 'Full name is required' })
  fullName: string;

  @ApiProperty({ example: 'c7a2b918-4e89-4d62-8172-ef19a86e7362' })
  @IsString()
  @IsNotEmpty({ message: 'University ID is required' })
  universityId: string;

  @ApiProperty({ example: 'd3f1a2b8-1c94-4d62-9172-ba19a86e1122' })
  @IsString()
  @IsNotEmpty({ message: 'Department ID is required' })
  departmentId: string;

  @ApiProperty({ enum: Role, example: Role.STUDENT })
  @IsEnum(Role, { message: 'Role must be STUDENT, CR, or FACULTY' })
  role: Role;

  @ApiPropertyOptional({ example: '2241081422' })
  @IsOptional()
  @IsString()
  studentId?: string;

  @ApiPropertyOptional({ example: '68' })
  @IsOptional()
  @IsString()
  batch?: string;

  @ApiPropertyOptional({ example: 'B' })
  @IsOptional()
  @IsString()
  section?: string;

  @ApiPropertyOptional({ example: 'DNS' })
  @IsOptional()
  @IsString()
  facultyId?: string;
}
```
- **`@IsEmail()`**: Rejects strings like `"notanemail"` before they ever touch the database.
- **`@MinLength(6)`**: Enforces minimum password strength.
- **`@IsEnum(Role)`**: Ensures the user role can only be one of the predefined roles (`STUDENT`, `CR`, `FACULTY`).
- **`@IsOptional()`**: Fields like `batch` and `section` are only needed for students and CRs, not for visiting admins.
- **`@ApiProperty()`**: Documents these fields in Swagger UI automatically.

---

## 2. Auth Controller: `src/modules/auth/auth.controller.ts` Line by Line

The Controller is the **traffic conductor**. It listens for HTTP requests, extracts parameters, and passes them to `AuthService`. It contains no heavy database logic itself.

```typescript
1: import {
2:   Controller,
3:   Post,
4:   Get,
5:   Put,
6:   Body,
7:   UseGuards,
8:   HttpCode,
9:   HttpStatus,
10: } from '@nestjs/common';
11: import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
12: import { AuthService } from './auth.service';
13: import { RegisterDto } from './dto/register.dto';
14: import { LoginDto } from './dto/login.dto';
15: import { VerifyEmailDto } from './dto/verify-email.dto';
16: import { ResendVerificationDto } from './dto/resend-verification.dto';
17: import { ForgotPasswordDto } from './dto/forgot-password.dto';
18: import { VerifyResetPinDto } from './dto/verify-reset-pin.dto';
19: import { ResetPasswordDto } from './dto/reset-password.dto';
20: import { RefreshTokenDto } from './dto/refresh-token.dto';
21: import { UpdateProfileDto } from './dto/update-profile.dto';
22: import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
23: import { CurrentUser, JwtPayload } from '../../common/decorators/current-user.decorator';
```

```typescript
25: @ApiTags('Authentication & Identity')
26: @Controller('auth')
27: export class AuthController {
28:   constructor(private readonly authService: AuthService) {}
```
- `@ApiTags(...)`: Groups all auth routes under one section in Swagger.
- `@Controller('auth')`: Maps these routes to `/api/v1/auth`.
- `constructor(...)`: **Dependency Injection**. NestJS automatically creates an instance of `AuthService` and injects it here.

```typescript
30:   @Post('register')
31:   @ApiOperation({ summary: 'Register a new institutional user (Student, CR, Faculty)' })
32:   async register(@Body() dto: RegisterDto) {
33:     return this.authService.register(dto);
34:   }
```
- Listens for `POST /api/v1/auth/register`. `@Body()` extracts the parsed JSON body and validates it against `RegisterDto`.

```typescript
36:   @Post('verify-email')
37:   @HttpCode(HttpStatus.OK)
38:   @ApiOperation({ summary: 'Verify email using 6-digit cryptographic PIN' })
39:   async verifyEmail(@Body() dto: VerifyEmailDto) {
40:     return this.authService.verifyEmail(dto);
41:   }
```
- `@HttpCode(HttpStatus.OK)`: By default, `POST` requests return `201 Created`. For verification, we override it to return a standard `200 OK`.

```typescript
43:   @Post('login')
44:   @HttpCode(HttpStatus.OK)
45:   @ApiOperation({ summary: 'Log in with institutional email & password' })
46:   async login(@Body() dto: LoginDto) {
47:     return this.authService.login(dto);
48:   }
```
- Authenticates the user and returns their JWT token pair + user profile object.

```typescript
50:   @Post('refresh')
51:   @HttpCode(HttpStatus.OK)
52:   @ApiOperation({ summary: 'Rotate and exchange refresh token for a fresh access token' })
53:   async refresh(@Body() dto: RefreshTokenDto) {
54:     return this.authService.refresh(dto.refreshToken);
55:   }
```
- When the 7-day access token is near expiry, the mobile app silently calls this endpoint to get a fresh access token without logging the user out!

```typescript
57:   @Get('me')
58:   @UseGuards(JwtAuthGuard)
59:   @ApiBearerAuth('JWT-auth')
60:   @ApiOperation({ summary: 'Get caller profile information' })
61:   async getProfile(@CurrentUser('sub') userId: string) {
62:     return this.authService.getProfile(userId);
63:   }
```
- Protected by `@UseGuards(JwtAuthGuard)`. Extracts `sub` (user UUID) from the verified token and fetches their profile from PostgreSQL.

```typescript
65:   @Get('section-students')
66:   @UseGuards(JwtAuthGuard)
67:   @ApiBearerAuth('JWT-auth')
68:   @ApiOperation({ summary: 'Get all enrolled classmates in the callers section' })
69:   async getSectionStudents(@CurrentUser('sub') userId: string) {
70:     return this.authService.getSectionStudents(userId);
71:   }
```
- Powers the CR Section Attendance feature in the mobile app! Returns all classmates enrolled in the same department, batch, and section.

---

## 3. Auth Service: `src/modules/auth/auth.service.ts` Deep Dive

The Service contains the **core business logic and security algorithms**.

### 1. Generating Cryptographic 6-Digit PINs
```typescript
private generateSixDigitPin(): string {
  return crypto.randomInt(100000, 1000000).toString();
}
```
- **Why not `Math.random()`?**
  `Math.random()` is pseudo-random and predictable—a hacker could guess future PINs.
  Node.js's native `crypto.randomInt()` uses the operating system's **CSPRNG (Cryptographically Secure Pseudo-Random Number Generator)**, making PINs mathematically impossible to predict!

### 2. Password Hashing with Bcrypt
```typescript
private readonly saltRounds = 10;
const passwordHash = await bcrypt.hash(dto.password, this.saltRounds);
```
- Bcrypt generates a random 128-bit salt and runs the hashing algorithm $2^{10} = 1024$ times.
- Result: Even identical passwords (`password123`) produce completely different hashes:
  `$2b$10$e7mZ9r8qLp3x...` vs `$2b$10$wK4p1mN9aB2...`
- Rainbow tables (precomputed password lists used by hackers) are completely useless against salted Bcrypt!

### 3. Smart Handling of Incomplete Registrations
What if a student registers, but their phone dies before they enter the verification PIN?
In `auth.service.ts`:
```typescript
const existingUser = await this.prisma.user.findUnique({ where: { email } });

if (existingUser) {
  if (existingUser.isEmailVerified) {
    throw new ConflictException('An account with this email address already exists. Please log in.');
  }
  // User registered earlier but never verified: update their details and re-send PIN!
  const passwordHash = await bcrypt.hash(dto.password, this.saltRounds);
  await this.prisma.user.update({
    where: { email },
    data: { passwordHash, fullName: dto.fullName, ... },
  });
  return this.dispatchVerificationPin(email, dto.fullName);
}
```
- Instead of showing a frustrating error "Email already exists", the system intelligently detects that the email is unverified, updates their information with the new password, and dispatches a fresh PIN!

### 4. Brute-Force Rate Limiting (5 Attempts Max)
When verifying a PIN:
```typescript
if (pinRecord.attempts >= 5) {
  throw new BadRequestException('Too many failed attempts. This PIN is invalidated. Please request a fresh PIN.');
}

const isPinValid = await bcrypt.compare(dto.pin, pinRecord.pinHash);

if (!isPinValid) {
  await this.prisma.emailVerificationPin.update({
    where: { id: pinRecord.id },
    data: { attempts: { increment: 1 } },
  });
  const remaining = 5 - (pinRecord.attempts + 1);
  throw new BadRequestException(`Invalid PIN. ${remaining} attempt(s) remaining.`);
}
```
- Every incorrect guess increments `attempts` by 1.
- After 5 failed guesses, the PIN is locked forever. An attacker trying all 1,000,000 combinations has a probability of success of only $0.0005\%$.

### 5. Resend PIN Cooldown Rate Limiting (60 Seconds)
```typescript
const latestPin = await this.prisma.emailVerificationPin.findFirst({
  where: { email },
  orderBy: { createdAt: 'desc' },
});

if (latestPin) {
  const elapsedSeconds = (Date.now() - latestPin.createdAt.getTime()) / 1000;
  if (elapsedSeconds < 60) {
    const remaining = Math.ceil(60 - elapsedSeconds);
    throw new BadRequestException(`Please wait ${remaining}s before requesting another PIN.`);
  }
}
```
- Prevents malicious users or bots from spamming the email server by hammering the "Resend Code" button.

### 6. Faculty Auto-Linking on Verification
```typescript
if (verifiedUser.role === Role.FACULTY && verifiedUser.facultyId && verifiedUser.departmentId) {
  await this.prisma.scheduleSlot.updateMany({
    where: {
      departmentId: verifiedUser.departmentId,
      facultyInitials: { equals: verifiedUser.facultyId, mode: 'insensitive' },
    },
    data: {
      facultyUserId: verifiedUser.id,
    },
  });
}
```
- **Autonomous Synchronization**:
  When a university uploads a routine PDF, schedule slots are created with teacher initials like `"DNS"`.
  When teacher Dr. Nazmul (DNS) signs up and verifies his account, the backend automatically scans the routine and links all matching classes to his user ID! When he opens the app, his teaching schedule appears instantly.

### 7. Dual Token Generation (Access + Refresh)
```typescript
private async generateTokens(user: ...) {
  const payload: JwtPayload = {
    sub: user.id,
    email: user.email,
    role: user.role,
    universityId: user.universityId,
    departmentId: user.departmentId,
    studentId: user.studentId,
    batch: user.batch,
    section: user.section,
    facultyId: user.facultyId,
  };

  const [accessToken, refreshToken] = await Promise.all([
    this.jwtService.signAsync(payload, {
      secret: this.accessSecret,
      expiresIn: this.accessExpiresIn, // 7 days
    }),
    this.jwtService.signAsync(payload, {
      secret: this.refreshSecret,
      expiresIn: this.refreshExpiresIn, // 30 days
    }),
  ]);

  return {
    accessToken,
    refreshToken,
    tokenType: 'Bearer',
    expiresIn: this.accessExpiresIn,
  };
}
```
- We issue two tokens concurrently using `Promise.all`:
  1. **Access Token (7 Days)**: Attached to every request header.
  2. **Refresh Token (30 Days)**: Kept in secure phone storage. Used solely to request a new access token without re-prompting the user for their password.

---

*Continue to Chapter 5 for the deep-dive into Classroom Inventory and Optimistic Concurrency Control (OCC).*
