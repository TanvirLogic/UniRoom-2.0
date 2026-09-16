# UniRoom-Live 2.0 🏫🚀

[![Architecture: Clean](https://img.shields.io/badge/Architecture-Clean%20Architecture-00D26A?style=for-the-badge)](complete_project.md)
[![Backend: TypeScript/NestJS](https://img.shields.io/badge/Backend-NestJS%20%2B%20TypeScript-E0234E?style=for-the-badge&logo=nestjs)](backend)
[![Database: PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL%2016-336791?style=for-the-badge&logo=postgresql)](backend)
[![Cache: Redis](https://img.shields.io/badge/Cache-Redis%207-DC382D?style=for-the-badge&logo=redis)](backend)
[![Frontend: Flutter + Riverpod 2.x](https://img.shields.io/badge/Mobile-Flutter%20%2B%20Riverpod%202.x-02569B?style=for-the-badge&logo=flutter)](mobile)
[![DevOps: Docker](https://img.shields.io/badge/DevOps-Docker%20Compose-2496ED?style=for-the-badge&logo=docker)](docker-compose.yml)

> **Enterprise-Grade Multi-Tenant University Classroom & Timetable Orchestration Platform**  
> Engineered from first principles with **Clean Architecture**, **Domain-Driven Design (DDD)**, **Sub-Second Real-Time WebSockets**, and **Strict Role-Based Access Control (RBAC)**.

---

## 📖 Master Engineering Blueprint

For the exhaustive architectural specification, 5-year job security skill matrix, entity-relationship diagrams, and design trade-offs, read the **[Master Blueprint (complete_project.md)](complete_project.md)**.

---

## 🏗️ System Architecture Overview

```mermaid
graph TD
    subgraph "Client Tier (Clean Architecture + Riverpod 2.x)"
        FlutterMobile["📱 Flutter Mobile App\n(Student & CR Dashboards)"]
    end

    subgraph "API & Real-Time Gateway Tier"
        NestGateway["🌐 NestJS Modular Monolith API Gateway\n(Swagger / OpenAPI 3.0)"]
        WSGateway["⚡ WebSocket & Socket.io Gateway\n(Real-Time Room Status)"]
    end

    subgraph "Data & In-Memory Tier"
        Postgres[("🐘 PostgreSQL 16\n(Multi-Tenant Relational Storage)")]
        Redis[("⚡ Redis 7\n(State Caching, Pub/Sub & Rate Limiting)")]
    end

    FlutterMobile -->|REST / HTTPS| NestGateway
    FlutterMobile -->|WSS / Socket.io| WSGateway
    NestGateway --> Postgres
    NestGateway --> Redis
    WSGateway --> Redis
```

---

## 📂 Monorepo Structure

```
UniRoom-Live/
├── backend/                 # Enterprise NestJS + TypeScript API
│   ├── src/
│   │   ├── common/          # Guards, Interceptors, Decorators, Filters
│   │   ├── modules/
│   │   │   ├── auth/        # JWT, Refresh Rotation, Password Hashing, RBAC
│   │   │   ├── rooms/       # Room lifecycle, status & conflict engine
│   │   │   ├── schedules/   # Dynamic timetable allocation
│   │   │   └── realtime/    # WebSockets & Redis Pub/Sub gateway
│   │   └── database/        # Prisma migrations & schema
│   ├── test/                # Unit & E2E tests (Jest + Supertest)
│   └── Dockerfile           # Multi-stage production build
├── mobile/                  # Flutter 3.x Mobile Client
│   ├── lib/
│   │   ├── core/            # Dio network client, Result/Failure monads, tokens
│   │   ├── features/        # Auth, Rooms, University (Domain, Data, Presentation)
│   │   └── main.dart        # Riverpod ProviderScope root
│   └── test/                # Unit & Widget tests (mocktail)
├── docs/                    # Architecture Decision Records (ADRs) & C4 Diagrams
├── docker-compose.yml       # One-command orchestration (API + Postgres + Redis)
├── complete_project.md      # Full architecture blueprint & career roadmap
└── README.md
```

---

## ⚡ Quick Start (Local Development)

### 1. Prerequisites
- Docker & Docker Compose
- Node.js (v20+) & npm
- Flutter SDK (v3.22+)

### 2. Boot Infrastructure & Backend
```bash
# Clone the repository
git clone https://github.com/TanvirLogic/UniRoom-Live.git
cd UniRoom-Live

# Start PostgreSQL and Redis via Docker
docker compose up -d

# Interactive Swagger API Documentation:
# Open http://localhost:3000/api/docs in your browser
```

### 3. Run Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

---

## 📜 License & Engineering Standards
Licensed under the [MIT License](LICENSE). Built adhering to Clean Architecture and modern Software Engineering standards.
