# 02 · System Architecture

> 🧑‍💻 **Audience:** Developers, maintainers, DevOps

---

## 1. High-Level Architecture

```mermaid
flowchart TB
    subgraph Clients
        A1[Flutter App<br/>Student Portal]
        A2[Flutter App<br/>Supervisor Portal]
        A3[Flutter App<br/>Admin Portal]
        A4[Flutter Web]
    end

    subgraph Edge
        N1[Nginx<br/>Reverse Proxy · SSL · Static /storage]
    end

    subgraph Application
        PM2[PM2 Cluster<br/>Express API :3000]
    end

    subgraph Middleware
        M1[JWT Auth<br/>authenticate + authorizeRole]
        M2[Zod Validation]
        M3[Rate Limiting]
        M4[Winston Logging]
        M5[Helmet + CORS]
    end

    subgraph Data
        DB[(PostgreSQL)]
        ST[Local Storage<br/>images · videos · documents · avatars]
    end

    A1 & A2 & A3 & A4 -->|HTTPS / REST /api/v1| N1
    N1 --> PM2
    PM2 --> M1 --> M2 --> M3 --> M4 --> M5
    PM2 --> DB
    PM2 --> ST
```

---

## 2. Request Flow

```mermaid
sequenceDiagram
    participant C as Flutter Client
    participant I as Interceptors<br/>(Auth · Connectivity · Cache · Retry)
    participant N as Nginx
    participant A as Express API
    participant D as PostgreSQL

    C->>I: dio.request(method, path, data)
    I->>I: Offline? non-GET → enqueue & return 202
    I->>I: Attach Authorization: Bearer <jwt>
    I->>N: HTTPS request
    N->>A: proxy_pass :3000
    A->>A: authenticate → authorizeRole → validate
    A->>D: Prisma query / mutation
    D-->>A: result
    A-->>N: JSON response
    N-->>I: response
    I-->>C: parsed result
```

---

## 3. Backend Layered Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ Route Layer  (src/**/*.routes.ts)                           │
│   • Define endpoints, wire middlewares & controllers        │
├──────────────────────────────────────────────────────────────┤
│ Middleware Layer (auth.middleware.ts, validation, rate limit)│
│   • authenticate (JWT) • authorizeRole (RBAC) • validate    │
├──────────────────────────────────────────────────────────────┤
│ Controller Layer (src/**/*.controller.ts)                   │
│   • HTTP concerns: req parsing, res status codes, errors    │
├──────────────────────────────────────────────────────────────┤
│ Service Layer (src/**/*.service.ts)                         │
│   • Business logic (sessions, activities, reviews, media)   │
├──────────────────────────────────────────────────────────────┤
│ Data Layer (Prisma ORM + pg adapter)                        │
│   • PostgreSQL via @prisma/adapter-pg (connection pool)     │
└──────────────────────────────────────────────────────────────┘
```

---

## 4. Frontend Architecture (Flutter)

```mermaid
flowchart LR
    subgraph UI
        S[Screens / Features]
        W[Shared Widgets]
    end
    subgraph State
        RP[Riverpod Providers]
        CP[Provider / ChangeNotifier]
    end
    subgraph Routing
        GR[GoRouter<br/>role-based redirects]
    end
    subgraph Networking
        DIO[Dio Client]
        AU[Auth Interceptor]
        CN[Connectivity Interceptor]
        CA[Cache Interceptor]
        RT[Retry Interceptor]
        HQ[Hive Offline Queue]
    end
    subgraph Services
        FCM[Firebase Messaging<br/>+ Local Notifications]
        GEO[geolocator]
        MAP[flutter_map]
        MED[image_picker · record · file_picker]
    end

    S --> RP
    RP --> DIO
    S --> GR
    DIO --> AU & CN & CA & RT
    CN --> HQ
    S --> FCM & GEO & MAP & MED
```

---

## 5. Technology Stack

### Backend
| Layer | Technology |
|-------|-----------|
| Runtime | Node.js + Express 5 (TypeScript, ESM) |
| ORM | Prisma 7 (`@prisma/client`, `@prisma/adapter-pg`) |
| Database | PostgreSQL |
| Validation | Zod |
| Auth | `jsonwebtoken` (JWT) + `bcrypt` |
| Media | `multer`, `sharp`, `fluent-ffmpeg` + `@ffmpeg-installer/ffmpeg` |
| Logging | `winston` + `winston-daily-rotate-file` |
| Security | `helmet`, `cors`, `express-rate-limit` |
| Email | `nodemailer` |
| Ops | PM2 (`ecosystem.config.cjs`), Nginx, Docker/K8s manifests |

### Frontend
| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Android / Web / Desktop) |
| State | `flutter_riverpod`, `provider` |
| Routing | `go_router` |
| Networking | `dio` + `dio_smart_retry` + `dio_cache_interceptor` |
| Offline | `hive` / `hive_flutter` |
| Maps/GPS | `flutter_map`, `latlong2`, `geolocator` |
| Media | `image_picker`, `file_picker`, `record`, `video_player`, `audioplayers` |
| Notifications | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| Secure storage | `flutter_secure_storage` |
| Env | `flutter_dotenv` |
| Charts | `fl_chart`, `shimmer` |

### Deployment Targets
| Target | Notes |
|--------|-------|
| Ubuntu 22.04 / 24.04 | Server OS (Nginx + PM2) |
| Kubernetes | `backend/k8s/` manifests |
| Vercel | Frontend web static hosting (`frontend/vercel.json`) |

---

## 6. Deployment Topology (Production)

```mermaid
flowchart TB
    U[User] -->|HTTPS 443| NG[Nginx :443 SSL]
    NG -->|proxy :3000| P1[PM2 instance 1]
    NG -->|proxy :3000| P2[PM2 instance 2]
    NG -->|proxy :3000| P3[PM2 instance N]
    P1 & P2 & P3 -->|pg| PGC[(PostgreSQL)]
    P1 & P2 & P3 --> ST[(Storage dir)]
    NG -->|/storage/* static| ST
```

- PM2 runs in **cluster mode** (`instances: max`) across all CPUs.
- Nginx serves `/storage/*` directly for maximum media performance.
- Nginx forwards the real client IP (`X-Real-IP` / `X-Forwarded-For`) so rate limiting works correctly.

