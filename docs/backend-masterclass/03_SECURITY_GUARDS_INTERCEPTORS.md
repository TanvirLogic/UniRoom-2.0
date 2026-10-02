# 🎓 UniRoom-Live 2.0 Backend Masterclass
## Chapter 3: Security, Authentication Guards, Roles & Interceptors

In web and mobile development, **Security is not an afterthought—it is the foundation**.
If your endpoints are not properly protected, anyone with `curl` or Postman could delete entire university routines, impersonate teachers, or book classrooms they don't belong to.

This chapter breaks down every security mechanism in `backend/src/common/` line by line.

---

## 1. How JWT Authentication Works (The Airport Boarding Pass Analogy)

When you fly on an airplane:
1. You show your passport at check-in.
2. The airline gives you a signed **Boarding Pass**.
3. At the gate, security doesn't call headquarters to look up your birth certificate. They simply scan the digital signature on your boarding pass! If the barcode signature is genuine and not expired, you board immediately.

A **JWT (JSON Web Token)** is a digital boarding pass:
- **Header**: Algorithm used (e.g., HMAC-SHA256).
- **Payload**: User info (`userId`, `email`, `role`, `universityId`, `batch`, `section`).
- **Signature**: Encrypted cryptographic signature signed with our server's secret key (`JWT_ACCESS_SECRET`).

Because the token is mathematically signed, nobody can tamper with it (e.g. changing `"role": "STUDENT"` to `"SUPER_ADMIN"` without invalidating the signature).

---

## 2. JWT Strategy: `src/modules/auth/strategies/jwt.strategy.ts` Line by Line

NestJS uses **Passport.js** to automatically extract and verify JWT tokens from incoming HTTP request headers:

```typescript
1: import { Injectable, UnauthorizedException } from '@nestjs/common';
2: import { PassportStrategy } from '@nestjs/passport';
3: import { ExtractJwt, Strategy } from 'passport-jwt';
4: import { ConfigService } from '@nestjs/config';
5: import { JwtPayload } from '../../../common/decorators/current-user.decorator';
```
- Imports `PassportStrategy`, `ExtractJwt`, and `Strategy` from `passport-jwt`.

```typescript
7: @Injectable()
8: export class JwtStrategy extends PassportStrategy(Strategy) {
9:   constructor(private readonly configService: ConfigService) {
10:    super({
11:      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
12:      ignoreExpiration: false,
13:      secretOrKey: configService.get<string>('JWT_ACCESS_SECRET')!,
14:    });
15:  }
```
- **Line 8**: Extends `PassportStrategy(Strategy)`.
- **Line 11 (`fromAuthHeaderAsBearerToken`)**: Tells Passport to look at the HTTP header:
  `Authorization: Bearer <eyJhbGciOi...>`
- **Line 12 (`ignoreExpiration: false`)**: Rejects any token that has expired.
- **Line 13 (`secretOrKey`)**: Validates the mathematical signature using our server's secret key.

```typescript
17:  async validate(payload: JwtPayload) {
18:    if (!payload.sub || !payload.email) {
19:      throw new UnauthorizedException('Invalid or malformed authentication token');
20:    }
21:    return payload;
22:  }
23: }
```
- **Lines 17-22**: If the signature and expiration are valid, Passport calls `validate()`. Whatever this method returns is automatically attached to the Express request object as `req.user`!

---

## 3. JWT Guard: `src/common/guards/jwt-auth.guard.ts` Line by Line

```typescript
1: import { Injectable } from '@nestjs/common';
2: import { AuthGuard } from '@nestjs/passport';
3: 
4: @Injectable()
5: export class JwtAuthGuard extends AuthGuard('jwt') {}
```
- A simple, clean wrapper around Passport's JWT authentication guard.
- When placed above a controller method:
  `@UseGuards(JwtAuthGuard)`
  It intercepts the request. If the user doesn't provide a valid Bearer token, it immediately returns `401 Unauthorized` without running a single line of your controller code!

---

## 4. Role-Based Access Control (RBAC): `roles.decorator.ts` & `roles.guard.ts`

Not all logged-in users have equal authority:
- A Student can only view routines.
- A CR can cancel classes for their section.
- A Super Admin can delete universities.

How do we enforce this elegantly? Through custom **Decorators** and **Guards**.

### Decorator: `src/common/decorators/roles.decorator.ts`
```typescript
1: import { SetMetadata } from '@nestjs/common';
2: import { Role } from '@prisma/client';
3: 
4: export const ROLES_KEY = 'roles';
5: export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);
```
- `SetMetadata('roles', roles)` attaches custom metadata to a controller route.
- Usage in controllers:
  ```typescript
  @Roles(Role.CR, Role.FACULTY, Role.SUPER_ADMIN)
  @Post('cancel-class')
  ```

### Guard: `src/common/guards/roles.guard.ts` Line by Line
```typescript
1: import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
2: import { Reflector } from '@nestjs/core';
3: import { Role } from '@prisma/client';
4: import { ROLES_KEY } from '../decorators/roles.decorator';
5: 
6: @Injectable()
7: export class RolesGuard implements CanActivate {
8:   constructor(private reflector: Reflector) {}
```
- **Line 7-8**: Implements `CanActivate`. Injects `Reflector`, which reads metadata attached by `@Roles()`.

```typescript
10:  canActivate(context: ExecutionContext): boolean {
11:    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
12:      context.getHandler(),
13:      context.getClass(),
14:    ]);
15: 
16:    // If no roles are specified, the endpoint is accessible to any authenticated user
17:    if (!requiredRoles || requiredRoles.length === 0) {
18:      return true;
19:    }
```
- **Lines 10-18**: Reads the required roles from the route. If no roles were required, returns `true` (access granted).

```typescript
21:    const { user } = context.switchToHttp().getRequest();
22: 
23:    if (!user || !user.role) {
24:      throw new ForbiddenException('Access denied. No user identity or role found in session.');
25:    }
26: 
27:    const hasRole = requiredRoles.includes(user.role as Role);
28: 
29:    if (!hasRole) {
30:      throw new ForbiddenException(
31:        `Access denied. Role '${user.role}' is not authorized to access this resource. Required role(s): [${requiredRoles.join(', ')}]`,
32:      );
33:    }
34: 
35:    return true;
36:  }
37: }
```
- **Lines 21-36**: Inspects `user.role` from the JWT token.
  - If the user's role is in `requiredRoles`, returns `true`!
  - If not (e.g. a Student trying to hit a CR endpoint), throws a `403 Forbidden` with a detailed error message!

---

## 5. Multi-Tenant Guard: `src/common/guards/tenant.guard.ts` Line by Line

In a multi-university system, student Alice from University A (`UU`) must **never** be allowed to view or modify resources in University B (`DU`).

```typescript
1: import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
2: import { Role } from '@prisma/client';
3: 
4: @Injectable()
5: export class TenantGuard implements CanActivate {
6:   canActivate(context: ExecutionContext): boolean {
7:     const request = context.switchToHttp().getRequest();
8:     const user = request.user;
9: 
10:    if (!user) {
11:      return true; // Authentication guard should run first
12:    }
13: 
14:    // Super Admin has cross-tenant authority
15:    if (user.role === Role.SUPER_ADMIN) {
16:      return true;
17:    }
18: 
19:    const requestedUniversityId =
20:      request.params?.universityId ||
21:      request.body?.universityId ||
22:      request.query?.universityId;
23: 
24:    if (requestedUniversityId && requestedUniversityId !== user.universityId) {
25:      throw new ForbiddenException(
26:        'Cross-tenant violation: You cannot access or modify resources belonging to another university.',
27:      );
28:    }
29: 
30:    return true;
31:  }
32: }
```
- **Lines 14-17**: `SUPER_ADMIN` has global authority across all universities.
- **Lines 19-28**: If a regular student/CR passes a `universityId` in URL params, query string, or JSON body that does NOT match their own token's `universityId`, the request is immediately rejected with `403 Forbidden`!

---

## 6. Convenient User Extraction: `src/common/decorators/current-user.decorator.ts`

When a controller needs to know who is calling the endpoint, writing `req.user` everywhere is messy and weakly typed.

```typescript
import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Role } from '@prisma/client';

export interface JwtPayload {
  sub: string;       // User UUID
  email: string;
  role: Role;
  universityId?: string;
  departmentId?: string;
  studentId?: string;
  batch?: string;
  section?: string;
  facultyId?: string;
}

export const CurrentUser = createParamDecorator(
  (data: keyof JwtPayload | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    return data ? user?.[data] : user;
  },
);
```
- Creates the `@CurrentUser()` decorator.
- Now, in any controller method, you can simply write:
  ```typescript
  @Get('my-schedule')
  async getMySchedule(@CurrentUser() user: JwtPayload) {
    console.log(user.sub, user.role, user.batch);
  }
  ```
  Or pluck a single property:
  ```typescript
  async cancelClass(@CurrentUser('sub') userId: string) { ... }
  ```

---

## 7. Global Exception Filter: `src/common/filters/http-exception.filter.ts` Line by Line

When an error happens, default Express servers spit out an unformatted HTML error page or raw stack trace. That breaks mobile apps expecting JSON!

```typescript
1: import {
2:   ExceptionFilter,
3:   Catch,
4:   ArgumentsHost,
5:   HttpException,
6:   HttpStatus,
7:   Logger,
8: } from '@nestjs/common';
9: import { Request, Response } from 'express';
10: 
11: @Catch()
12: export class AllExceptionsFilter implements ExceptionFilter {
13:   private readonly logger = new Logger(AllExceptionsFilter.name);
```
- `@Catch()` without arguments catches **EVERY SINGLE ERROR** that occurs anywhere in the application.

```typescript
15:  catch(exception: unknown, host: ArgumentsHost) {
16:    const ctx = host.switchToHttp();
17:    const response = ctx.getResponse<Response>();
18:    const request = ctx.getRequest<Request>();
19: 
20:    let status = HttpStatus.INTERNAL_SERVER_ERROR;
21:    let message: string | object = 'Internal server error';
22:    let error = 'Internal Server Error';
23: 
24:    if (exception instanceof HttpException) {
25:      status = exception.getStatus();
26:      const res = exception.getResponse();
27:      if (typeof res === 'string') {
28:        message = res;
29:      } else if (typeof res === 'object' && res !== null) {
30:        const resObj = res as Record<string, any>;
31:        message = resObj.message || message;
32:        error = resObj.error || error;
33:      }
34:    } else if (exception instanceof Error) {
35:      this.logger.error(`Unhandled Exception: ${exception.message}`, exception.stack);
36:      message = exception.message;
37:    } else {
38:      this.logger.error('Unknown exception thrown', exception);
39:    }
```
- **Lines 24-39**: Intelligently inspects the exception:
  - If it's a NestJS `HttpException` (like `BadRequestException`, `NotFoundException`, `ConflictException`), it extracts the status code and error message.
  - If it's an unhandled code crash (like `NullPointerException` or database timeout), it logs the stack trace in the server console for debugging.

```typescript
41:    response.status(status).json({
42:      success: false,
43:      statusCode: status,
44:      error,
45:      message,
46:      timestamp: new Date().toISOString(),
47:      path: request.url,
48:    });
49:  }
50: }
```
- **Lines 41-49**: Returns a crystal-clear, standard JSON error envelope to the mobile app:
  ```json
  {
    "success": false,
    "statusCode": 409,
    "error": "Conflict",
    "message": "Room status was modified by another user. Please refresh.",
    "timestamp": "2026-10-02T11:20:00.000Z",
    "path": "/api/v1/rooms/5030/status"
  }
  ```

---

## 8. Response Envelope Interceptor: `src/common/interceptors/transform.interceptor.ts`

Just like errors are wrapped in a standard structure, successful responses should also have a consistent format across all endpoints:

```typescript
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ApiResponse<T> {
  success: boolean;
  statusCode: number;
  data: T;
  timestamp: string;
}

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
    const ctx = context.switchToHttp();
    const response = ctx.getResponse();
    const statusCode = response.statusCode;

    return next.handle().pipe(
      map((data) => ({
        success: true,
        statusCode,
        data,
        timestamp: new Date().toISOString(),
      })),
    );
  }
}
```
- Uses **RxJS** stream mapping.
- Whatever your controller returns (`user`, `rooms[]`, `schedule`), this interceptor packages it into:
  ```json
  {
    "success": true,
    "statusCode": 200,
    "data": [ ... ],
    "timestamp": "2026-10-02T11:20:00.000Z"
  }
  ```
  The Flutter frontend can rely on `response.data['data']` across every single screen!

---

*Continue to Chapter 4 for the complete line-by-line masterclass of the Authentication Module.*
