# 🎓 UniRoom-Live 2.0 Backend Masterclass
## Chapter 1: The Big Picture, Request Lifecycle & Application Bootstrap

Welcome to the comprehensive backend breakdown of **UniRoom-Live 2.0**.
This guide is written for anyone who knows basic programming and wants to understand how an enterprise-grade backend is structured, line by line, from first principles to production.

---

## 1. What Actually IS a Backend? (The Restaurant Analogy)

Imagine you go to a fine-dining restaurant:
- **The Customer** is the **Mobile App (Flutter)** or Web Browser.
- **The Waiter** is the **API (Application Programming Interface)** — they take your order to the kitchen and bring food back.
- **The Kitchen Manager / Head Chef** is the **Backend Framework (NestJS)** — they coordinate ingredients, recipes, chefs, and orders.
- **The Pantry & Refrigerator** is the **Database (PostgreSQL via Neon.tech)** — where ingredients and historical food orders are safely preserved forever.
- **The Security Guard at the Door** is **Authentication & Guards (JWT, RBAC)** — checking if you have a reservation and whether you're allowed in the VIP lounge.

When you tap "Sign In" on your phone:
1. The phone packages your email and password into an HTTP request.
2. It sends it over the internet to our backend server.
3. The server checks the password against PostgreSQL.
4. If correct, the server issues a cryptographic digital passport called a **JWT (JSON Web Token)**.
5. The phone stores this passport and attaches it to every future request so the server knows who you are.

---

## 2. The NestJS Request Lifecycle Architecture

NestJS organizes backend code using a **layered, modular design**. A single HTTP request passes through a clear sequence of checkpoints before returning a response:

```
[ Client Request (Phone/Web) ]
           │
           ▼
┌──────────────────────────────────────┐
│  1. CORS & Global Middleware         │ (Checks origins, headers)
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  2. Guards (Authentication & RBAC)  │ (Is user logged in? Are they a CR/Faculty?)
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  3. Validation Pipes (DTOs)          │ (Validates input format, types, limits)
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  4. Controller (Routing & HTTP)      │ (Extracts params, calls Service)
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  5. Service (Business Logic)         │ (Calculations, collisions, rules)
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  6. Prisma ORM (Data Layer)          │ (Converts TypeScript into raw SQL)
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  7. PostgreSQL Database              │ (Persists data on disk)
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  8. Response Interceptor             │ (Envelopes response into clean JSON)
└──────────────────┬───────────────────┘
                   │
                   ▼
[ Client Response (HTTP 200 OK) ]
```

If anything fails along this path (e.g. invalid password, missing permissions, server error), execution halts immediately and jumps to the **Global Exception Filter**, which formats a clean error message back to the phone.

---

## 3. Project Configuration: `package.json` Line by Line

Let's examine `backend/package.json`, which tells Node.js which libraries are needed and what scripts can run:

```json
{
  "name": "uniroom-backend",
  "version": "1.0.0",
  "description": "UniRoom-Live 2.0 - Enterprise Multi-Tenant Classroom & Routine Orchestration API",
  "author": "UniRoom Engineering Team",
  "private": true,
  "license": "MIT",
```
- **Line 1-7**: Standard metadata identifying our project, version, and licensing. `"private": true` prevents accidental publication to public npm registries.

```json
  "scripts": {
    "build": "nest build",
    "format": "prettier --write \"src/**/*.ts\" \"test/**/*.ts\"",
    "start": "nest start",
    "start:dev": "nest start --watch",
    "start:debug": "nest start --debug --watch",
    "start:prod": "node dist/main",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:studio": "prisma studio",
    "prisma:seed": "ts-node prisma/seed.ts"
  },
```
- **Line 9 (`nest build`)**: Compiles TypeScript files (`.ts`) into pure JavaScript files (`.js`) in the `dist/` folder so Node.js can execute them.
- **Line 12 (`nest start --watch`)**: Development mode. Whenever you edit and save a file, the server restarts automatically in ~1 second.
- **Line 14 (`node dist/main`)**: Production startup command used when running on cloud servers (e.g. Render, AWS, Docker). Runs pre-compiled JS.
- **Line 16 (`prisma generate`)**: Reads our database schema (`schema.prisma`) and automatically generates TypeScript types and methods tailored specifically to our database tables.
- **Line 17 (`prisma migrate dev`)**: Synchronizes database schema changes with PostgreSQL by creating SQL migration scripts.
- **Line 18 (`prisma studio`)**: Opens a visual browser dashboard to view and edit database rows like a spreadsheet.
- **Line 19 (`prisma:seed`)**: Runs our seed script (`prisma/seed.ts`) to populate default data (like universities, departments, SuperAdmin).

### Key Dependencies Breakdown:
- **`@nestjs/common`, `@nestjs/core`, `@nestjs/platform-express`**: The core NestJS framework built on top of Express.js.
- **`@nestjs/jwt`, `passport`, `passport-jwt`**: Industrial-standard libraries for issuing, signing, and decrypting JSON Web Tokens.
- **`@prisma/client`**: The high-performance database client library for querying PostgreSQL.
- **`bcrypt`**: The cryptographic hashing algorithm used to securely store user passwords with salt rounds.
- **`class-validator`, `class-transformer`**: Decorators that validate user input on incoming HTTP requests before code touches the database.
- **`firebase-admin`**: Google Firebase SDK used to broadcast instant push notifications to mobile phones.
- **`nodemailer`**: Node.js mailer library used to send 6-digit verification PINs and password reset emails via SMTP.
- **`@nestjs/swagger`, `swagger-ui-express`**: Automatically generates interactive API documentation with a "Try it out" button accessible at `/api/docs`.

---

## 4. Application Entry Point: `src/main.ts` Line by Line

`src/main.ts` is the very first file that executes when the backend starts up. Let's inspect every single line:

```typescript
1: import { NestFactory } from '@nestjs/core';
2: import { Logger, ValidationPipe } from '@nestjs/common';
3: import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
4: import { AppModule } from './app.module';
5: import { AllExceptionsFilter } from './common/filters/http-exception.filter';
6: import { TransformInterceptor } from './common/interceptors/transform.interceptor';
```
- **Lines 1-6**: Imports needed tools from NestJS and our custom helper classes (`AllExceptionsFilter`, `TransformInterceptor`, and the root `AppModule`).

```typescript
8: async function bootstrap() {
9:   const logger = new Logger('Bootstrap');
10:  const app = await NestFactory.create(AppModule);
```
- **Line 8-10**: Defines the asynchronous `bootstrap()` function. `NestFactory.create(AppModule)` initializes the NestJS Dependency Injection container, reads all modules, and starts the Express HTTP engine. `Logger` provides formatted console logging with timestamps and colors.

```typescript
12:  // Enable Cross-Origin Resource Sharing (CORS)
13:  app.enableCors({
14:    origin: true,
15:    credentials: true,
16:  });
```
- **Lines 13-16**: Enables **CORS**. In web browsers, security prevents a website (e.g., `localhost:5173`) from making requests to an API on another domain (`localhost:3000`) unless CORS headers allow it. Setting `origin: true` and `credentials: true` allows authorized mobile and web clients to connect smoothly.

```typescript
18:  // Global API Version Prefix
19:  app.setGlobalPrefix('api/v1');
```
- **Lines 18-19**: Prefixes every endpoint with `/api/v1/`. For example, instead of `/auth/login`, the URL becomes `/api/v1/auth/login`. This is professional API versioning—if we ever release v2 with breaking changes, v1 clients won't crash!

```typescript
21:  // Global Validation Pipe with strict DTO stripping
22:  app.useGlobalPipes(
23:    new ValidationPipe({
24:      whitelist: true,
25:      forbidNonWhitelisted: true,
26:      transform: true,
27:      transformOptions: {
28:        enableImplicitConversion: true,
29:      },
30:    }),
31:  );
```
- **Lines 22-31**: **The Security Gatekeeper**.
  - `whitelist: true`: Strips away any field sent in the JSON body that is not explicitly defined in our DTO (Data Transfer Object). This prevents **Mass Assignment Vulnerabilities** (e.g., a hacker sending `"role": "SUPER_ADMIN"` when registering).
  - `forbidNonWhitelisted: true`: If a hacker sends extra illegal fields, the server immediately throws a `400 Bad Request` and rejects the request.
  - `transform: true`: Automatically converts plain JSON strings into typed TypeScript objects, booleans, and numbers.

```typescript
33:  // Global Exception Filter for standard error responses
34:  app.useGlobalFilters(new AllExceptionsFilter());
```
- **Lines 33-34**: Ensures that whenever any error happens anywhere in the backend (database crash, bad password, route not found), the client always receives a clean, standardized JSON response instead of an ugly HTML stack trace.

```typescript
36:  // Global Response Envelope Interceptor
37:  app.useGlobalInterceptors(new TransformInterceptor());
```
- **Lines 36-37**: Automatically wraps every successful response inside a clean standard envelope:
  `{ success: true, statusCode: 200, data: ..., timestamp: ... }`.

```typescript
39:  // OpenAPI / Swagger Documentation Setup
40:  const config = new DocumentBuilder()
41:    .setTitle('UniRoom-Live 2.0 API')
42:    .setDescription(
43:      'Enterprise Multi-Tenant Real-Time Timetable & Classroom Allocation Orchestration Engine',
44:    )
45:    .setVersion('2.0')
46:    .addBearerAuth(
47:      {
48:        type: 'http',
49:        scheme: 'bearer',
50:        bearerFormat: 'JWT',
51:        name: 'Authorization',
52:        description: 'Enter JWT Access Token',
53:        in: 'header',
54:      },
55:      'JWT-auth',
56:    )
57:    .build();
58:
59:  const document = SwaggerModule.createDocument(app, config);
60:  SwaggerModule.setup('api/docs', app, document, {
61:    customSiteTitle: 'UniRoom-Live 2.0 API Documentation',
62:  });
```
- **Lines 40-62**: Configures **Swagger / OpenAPI Documentation**. By going to `http://localhost:3000/api/docs`, developers see an interactive UI documenting every single endpoint, required parameters, and response schemas, complete with an "Authorize" button to paste JWT tokens!

```typescript
64:  const port = process.env.PORT || 3000;
65:  await app.listen(port, '0.0.0.0');
66:
67:  logger.log(`🚀 API Server running on port ${port} (0.0.0.0)`);
68:  logger.log(`📚 Swagger Documentation: http://localhost:${port}/api/docs`);
69: }
70:
71: bootstrap();
```
- **Lines 64-71**: Reads the server port from environment variables (`PORT`), binds to all network interfaces (`0.0.0.0` so mobile devices on the same Wi-Fi or Docker containers can reach it), logs the launch message, and calls `bootstrap()` to fire up the server!

---

## 5. Root Orchestrator: `src/app.module.ts` Line by Line

In NestJS, a **Module** is a container that bundles related controllers and services together. `AppModule` is the root module that glues all other feature modules together:

```typescript
1: import { Module } from '@nestjs/common';
2: import { ConfigModule } from '@nestjs/config';
3: import { PrismaModule } from './prisma/prisma.module';
4: import { HealthModule } from './health/health.module';
5: import { AuthModule } from './modules/auth/auth.module';
6: import { EmailModule } from './modules/email/email.module';
7: import { MetaModule } from './modules/meta/meta.module';
8: import { UniversitiesModule } from './modules/universities/universities.module';
9: import { RoomsModule } from './modules/rooms/rooms.module';
10: import { SchedulesModule } from './modules/schedules/schedules.module';
11: import { NotificationsModule } from './modules/notifications/notifications.module';
```
- **Lines 1-11**: Imports all feature modules of the UniRoom ecosystem.

```typescript
13: @Module({
14:   imports: [
15:     ConfigModule.forRoot({
16:       isGlobal: true,
17:       envFilePath: '.env',
18:     }),
```
- **Lines 13-18**: `@Module()` decorator.
  - `ConfigModule.forRoot(...)`: Loads variables from our `.env` file (e.g. `DATABASE_URL`, `JWT_ACCESS_SECRET`, `SMTP_PASS`) and makes them accessible everywhere (`isGlobal: true`) via `ConfigService`.

```typescript
19:     PrismaModule,
20:     HealthModule,
21:     EmailModule,
22:     NotificationsModule,
23:     AuthModule,
24:     MetaModule,
25:     UniversitiesModule,
26:     RoomsModule,
27:     SchedulesModule,
28:   ],
29:   controllers: [],
30:   providers: [],
31: })
32: export class AppModule {}
```
- **Lines 19-32**: Mounts all feature modules:
  - `PrismaModule`: Database connectivity.
  - `HealthModule`: Uptime monitor `/api/v1/health`.
  - `EmailModule`: SMTP email delivery.
  - `NotificationsModule`: Firebase cloud messaging.
  - `AuthModule`: Registration, login, JWT token issuing, verification PINs.
  - `MetaModule`: Dropdown feeds for academic batches & sections.
  - `UniversitiesModule`: University and department administration.
  - `RoomsModule`: Physical classroom inventory, free room calculator, OCC bookings.
  - `SchedulesModule`: Timetable routines, emergency cancellations, reschedules.

---

## 6. Database Client: `src/prisma/prisma.service.ts` Line by Line

How does NestJS actually talk to PostgreSQL? Through `PrismaService`:

```typescript
1: import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
2: import { PrismaClient } from '@prisma/client';
3: 
4: @Injectable()
5: export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
6:   private readonly logger = new Logger(PrismaService.name);
```
- **Line 4-6**: `@Injectable()` allows NestJS to inject this service into any other class (like `AuthService` or `RoomsService`). It extends `PrismaClient` so it inherits every database method (`this.user.findMany()`, `this.room.update()`, etc.).
- It implements two lifecycle hooks: `OnModuleInit` and `OnModuleDestroy`.

```typescript
8:   async onModuleInit() {
9:     this.logger.log('Connecting to PostgreSQL database...');
10:    let retries = 5;
11:    while (retries > 0) {
12:      try {
13:        await this.$connect();
14:        this.logger.log('✅ PostgreSQL connection established successfully.');
15:        break;
16:      } catch (err: any) {
17:        retries -= 1;
18:        this.logger.warn(
19:          `Database connection attempt failed (${err.message}). Retrying in 2 seconds... (${retries} retries left)`,
20:        );
21:        if (retries === 0) throw err;
22:        await new Promise((resolve) => setTimeout(resolve, 2000));
23:      }
24:    }
25:  }
```
- **Lines 8-25**: **Resilient Connection Engine**.
  When the backend starts up, it connects to PostgreSQL. Because cloud databases (like Neon.tech serverless PostgreSQL) might take 1-2 seconds to wake up from cold start, this loop retries up to 5 times with a 2-second delay instead of immediately crashing!

```typescript
27:  async onModuleDestroy() {
28:    this.logger.log('Disconnecting from PostgreSQL database...');
29:    await this.$disconnect();
30:    this.logger.log('Database connection closed cleanly.');
31:  }
32: }
```
- **Lines 27-32**: **Graceful Shutdown**.
  When the server is stopped (e.g. `Ctrl+C` or deployment), `onModuleDestroy()` cleanly terminates all database connections and frees resources on PostgreSQL without corrupting transactions.

---

## 7. Health, Diagnostics & Liveness Probes: `src/health/health.controller.ts` Line by Line

In professional production systems (Docker, Kubernetes, AWS, Render, Railway), backends must expose dedicated health endpoints. Orchestrators ping these endpoints every 15 seconds; if the backend hangs or cannot talk to PostgreSQL, the orchestrator automatically restarts the container.

Let's read `src/health/health.controller.ts` line by line:

```typescript
38: @ApiTags('Health & Diagnostics')
39: @Controller('health')
40: export class HealthController {
41:   constructor(
42:     private readonly prisma: PrismaService,
43:     private readonly emailService: EmailService,
44:     private readonly pushNotificationService: PushNotificationService,
45:   ) {}
```
- Injects `PrismaService`, `EmailService`, and `PushNotificationService` to run live diagnostics across the three pillars of the backend: Database, Emailing, and Push Notifications.

---

### 1. The Liveness Telemetry Route: `GET /api/v1/health`
```typescript
46:   @Get()
47:   @ApiOperation({ summary: 'System, Database, Email & Push Notification Health Status' })
48:   @ApiResponse({ status: 200, description: 'Operational telemetry across services' })
49:   async checkHealth() {
50:     // Ping the Neon PostgreSQL database
51:     let dbStatus = 'connected';
52:     try {
53:       await this.prisma.$queryRaw`SELECT 1`;
54:     } catch (e: any) {
55:       dbStatus = `disconnected: ${e.message}`;
56:     }
```
- **`await this.prisma.$queryRaw\`SELECT 1\``**:
  The lightest possible SQL query in PostgreSQL. It does not scan any tables or load any rows; it simply verifies that the TCP connection and database engine are alive and responding in under 5 milliseconds.

```typescript
58:     const universityCount = await this.prisma.university.count().catch(() => 0);
59:     const roomCount = await this.prisma.room.count().catch(() => 0);
60:     const slotCount = await this.prisma.scheduleSlot.count().catch(() => 0);
61: 
62:     const emailStatus = this.emailService.getStatus();
63:     const pushStatus = this.pushNotificationService.getStatus();
64: 
65:     return {
66:       status: 'ok',
67:       service: 'UniRoom-Live 2.0 Backend',
68:       database: {
69:         status: dbStatus,
70:         provider: 'PostgreSQL (Neon Serverless)',
71:         stats: {
72:           universities: universityCount,
73:           rooms: roomCount,
74:           scheduleSlots: slotCount,
75:         },
76:       },
77:       email: emailStatus,
78:       pushNotifications: pushStatus,
79:       timestamp: new Date().toISOString(),
80:     };
81:   }
```
- Returns real-time telemetry stats (number of universities, classrooms, and timetable slots), SMTP status, and Firebase FCM status.
- If any count query fails, `.catch(() => 0)` ensures the health route still returns a valid payload rather than crashing.

---

### 2. Deep Diagnostics & Live Testing Routes
```typescript
83:   @Get('diagnostics')
84:   @ApiOperation({ summary: 'Run deep live diagnostics on SMTP Mail Server and Firebase Admin SDK' })
85:   async runDiagnostics() {
86:     const emailVerify = await this.emailService.verifyConnection();
87:     const pushStatus = this.pushNotificationService.getStatus();
88: 
89:     return {
90:       service: 'UniRoom-Live 2.0',
91:       timestamp: new Date().toISOString(),
92:       email: { ...this.emailService.getStatus(), verification: emailVerify },
93:       pushNotifications: { ...pushStatus },
94:     };
95:   }
```
- **`GET /api/v1/health/diagnostics`**: Performs a full SMTP handshake test (`verifyConnection()`) to verify Gmail App Passwords and checks if Firebase credentials are fully loaded into memory.
- **`POST /api/v1/health/test-email`**: Allows administrators to send a test email to any inbox to verify TLS delivery.
- **`POST /api/v1/health/test-push`**: Dispatches a test Firebase Cloud Messaging push notification to verify phone device tokens or topic delivery without scheduling a real class.

---

*Continue to Chapter 2 for the complete line-by-line masterclass of the PostgreSQL schema and relational database models.*
