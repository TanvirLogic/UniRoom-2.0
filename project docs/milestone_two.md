# 🔑 Milestone 2: Multi-Tenant Authentication & Cryptographic RBAC
> **UniRoom-Live 2.0 — Milestone 2 Technical Specifications & Architecture Document**  
> *Target Audience: Engineering Team & Technical Defense*  
> *Location: `project docs/milestone_two.md`*

---

## 📌 1. Milestone Overview & Objectives
Milestone 2 implements the complete authentication, cryptographic security, and multi-tenant authorization subsystem for UniRoom-Live 2.0.

### Core Objectives:
1. **Cryptographic User Registration & Login**: Zero plaintext passwords; all credentials hashed with `bcrypt` (10 salt rounds).
2. **Dual-Token Architecture**: Short-lived Access Tokens (15 minutes) + Refresh Token Rotation (7 days).
3. **Multi-Tenant Logical Isolation**: Every user strictly scoped to a `universityId` and `departmentId`.
4. **4-Role Role-Based Access Control (RBAC)**: Fine-grained permissions enforced via NestJS decorators and reflection guards (`SUPER_ADMIN`, `FACULTY`, `CR`, `STUDENT`).
5. **Interactive Swagger 3.0 Documentation**: Live testable OpenAPI documentation with Bearer JWT support at `/api/docs`.

---

## 🛡️ 2. Security Architecture & Cryptographic Principles

### 2.1 Password Hashing with Bcrypt
Plaintext passwords are never persisted to the database. We utilize `bcrypt` with salt rounds $N = 10$, ensuring that even if the database were compromised, rainbow table and brute-force attacks are mathematically infeasible.

### 2.2 Short-Lived Access Tokens + Refresh Token Rotation
```
┌─────────────────┐                                  ┌─────────────────┐
│  Mobile Client  │                                  │  NestJS Backend │
└────────┬────────┘                                  └────────┬────────┘
         │                                                    │
         │  1. POST /auth/login { email, password }           │
         ├───────────────────────────────────────────────────►│
         │                                                    │ ◄─ bcrypt.compare()
         │  2. Return { accessToken (15m), refreshToken (7d)} │
         │◄───────────────────────────────────────────────────┤
         │                                                    │
         │  3. GET /protected [Header: Bearer accessToken]    │
         ├───────────────────────────────────────────────────►│
         │                                                    │ ◄─ JwtStrategy validates
         │  4. Return 200 OK with requested data              │
         │◄───────────────────────────────────────────────────┤
         │                                                    │
         │  [After 15 minutes: Access Token Expires]          │
         │                                                    │
         │  5. POST /auth/refresh { refreshToken }            │
         ├───────────────────────────────────────────────────►│
         │                                                    │ ◄─ Verify signature
         │  6. Invalidate old & Return fresh token pair       │
         │◄───────────────────────────────────────────────────┤
```

### 2.3 JWT Payload Structure
```json
{
  "sub": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
  "email": "cr.batch68a@uttara.edu.bd",
  "role": "CR",
  "universityId": "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed",
  "departmentId": "2c8e7a6f-a8c1-4f3d-b4b1-e4f6a7b8c9d0",
  "batch": "68",
  "section": "A",
  "iat": 1774160000,
  "exp": 1774160900
}
```

---

## 👥 3. The 4 Core Roles & Permission Hierarchy

| Role | Target Users | Allowed Operations |
| :--- | :--- | :--- |
| **`SUPER_ADMIN`** | University Central Admin | Master routine ingestion, room management, department configuration, cross-tenant auditing. |
| **`FACULTY`** | Teachers & Professors | View personal schedule, request daily class shifts, release room early. |
| **`CR`** | Section Class Representatives | Book available rooms for ad-hoc make-up classes, cancel daily section classes. Must match `batch` and `section`. |
| **`STUDENT`** | Enrolled Students | Read-only access to live room occupancy and class timetable. |

---

## 📡 4. API Endpoints Specification

### 4.1 `POST /api/v1/auth/register`
* **Access**: Public
* **Request Body**:
  ```json
  {
    "email": "student2@uttara.edu.bd",
    "password": "Password123!",
    "fullName": "Rahim Ahmed",
    "universityId": "<valid-university-uuid>",
    "departmentId": "<valid-department-uuid>",
    "role": "STUDENT",
    "batch": "68",
    "section": "A"
  }
  ```
* **Response (201 Created)**:
  ```json
  {
    "success": true,
    "statusCode": 201,
    "data": {
      "user": {
        "id": "...",
        "email": "student2@uttara.edu.bd",
        "fullName": "Rahim Ahmed",
        "role": "STUDENT",
        "universityId": "...",
        "departmentId": "..."
      },
      "accessToken": "ey...",
      "refreshToken": "ey...",
      "tokenType": "Bearer",
      "expiresIn": "15m"
    },
    "timestamp": "2026-09-22T..."
  }
  ```

### 4.2 `POST /api/v1/auth/login`
* **Access**: Public
* **Request Body**: `{ "email": "admin@uttara.edu.bd", "password": "Password123!" }`
* **Response (200 OK)**: Returns user profile and fresh token pair.

### 4.3 `POST /api/v1/auth/refresh`
* **Access**: Public
* **Request Body**: `{ "refreshToken": "ey..." }`
* **Response (200 OK)**: Returns a new Access Token and a new Refresh Token.

### 4.4 `GET /api/v1/auth/me`
* **Access**: Protected (`JwtAuthGuard`)
* **Headers**: `Authorization: Bearer <accessToken>`
* **Response (200 OK)**: Returns full session profile including university name and department code.

### 4.5 `GET /api/v1/auth/admin-test`
* **Access**: Protected (`JwtAuthGuard` + `RolesGuard` `@Roles(SUPER_ADMIN)`)
* **Behavior**: Returns 200 OK for `SUPER_ADMIN`. Returns 403 Forbidden for `STUDENT`, `CR`, or `FACULTY`.

---

## ⚙️ 5. Implementation File Manifest

| File Path | Purpose |
| :--- | :--- |
| [`backend/src/common/decorators/current-user.decorator.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/decorators/current-user.decorator.ts) | Custom `@CurrentUser()` param decorator. |
| [`backend/src/common/decorators/roles.decorator.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/decorators/roles.decorator.ts) | Custom `@Roles(...)` metadata decorator. |
| [`backend/src/common/guards/jwt-auth.guard.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/guards/jwt-auth.guard.ts) | Passport JWT guard enforcing authentication. |
| [`backend/src/common/guards/roles.guard.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/guards/roles.guard.ts) | RBAC guard enforcing role authorizations. |
| [`backend/src/common/guards/tenant.guard.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/common/guards/tenant.guard.ts) | Multi-tenant boundary guard. |
| [`backend/src/modules/auth/dto/`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/auth/dto/) | DTOs for Register, Login, and Refresh Token. |
| [`backend/src/modules/auth/strategies/jwt.strategy.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/auth/strategies/jwt.strategy.ts) | Passport JWT verification strategy. |
| [`backend/src/modules/auth/auth.service.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/auth/auth.service.ts) | Business logic for hashing, login, token generation. |
| [`backend/src/modules/auth/auth.controller.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/auth/auth.controller.ts) | HTTP routes and Swagger documentation. |
| [`backend/src/modules/auth/auth.module.ts`](file:///e:/Varsity%20Project/UniRoom-Live/backend/src/modules/auth/auth.module.ts) | NestJS module registering Passport and JWT. |
