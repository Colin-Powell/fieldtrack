# FieldTrack — Backend API

Node.js + Express + Prisma + PostgreSQL backend for the **FieldTrack** digital field activity supervision platform.

---

## 🚀 Quick Start

### Prerequisites
- Node.js ≥ 18
- PostgreSQL ≥ 14
- npm

### Installation

```bash
cd backend
npm install
```

### Environment Variables

Create a `.env` file in the `backend/` directory:

```env
# ── Database ───────────────────────────────────────────────
DATABASE_URL=postgresql://user:password@localhost:5432/fieldtrack

# ── Authentication ─────────────────────────────────────────
JWT_SECRET=your-super-secret-jwt-signing-key

# ── Initial Admin Account (auto-created on boot) ───────────
ADMIN_EMAIL=admin@fieldtrack.com
ADMIN_PASSWORD=ChangeMe123!

# ── Server ─────────────────────────────────────────────────
PORT=3000

# ── Firebase Cloud Messaging (push notifications) ───────────
# Either set the full JSON content from the downloaded service account file
# or point GOOGLE_APPLICATION_CREDENTIALS to the file path.
# FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
# GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json

# ── Storage (optional, defaults to ./storage) ──────────────
# STORAGE_DIR=/var/www/fieldtrack/backend/storage

# ── Email / SMTP (for OTP password reset) ──────────────────
# SMTP_HOST=smtp.example.com
# SMTP_PORT=587
# SMTP_USER=your-smtp-user
# SMTP_PASS=your-smtp-password
# EMAIL_FROM=FieldTrack <noreply@fieldtrack.com>
```

> ⚠️ `JWT_SECRET` and `DATABASE_URL` are **required**. The server refuses to start without them.

### Database Setup

```bash
# Create tables from the Prisma schema (no migrations folder needed for dev)
npx prisma db push

# Optional: seed the initial ADMIN user (requires ADMIN_EMAIL/ADMIN_PASSWORD in .env)
npm run db:seed

# Optional: open Prisma Studio to inspect data
npm run db:studio
```

> An admin account is also **auto-synced from the environment** on every boot via `src/admin-sync.ts` (idempotent).

### Running

| Command | Description |
|---------|-------------|
| `npm run dev` | Development server with hot reload (`tsx watch src/index.ts`) |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm start` | Run compiled output (`node dist/index.js`) |
| `npm run start:prod` | Run in production via PM2 cluster (`ecosystem.config.cjs`) |
| `npm run stop:prod` | Stop the PM2 cluster |

---

## ✅ Health Check

```
GET /health
```

```json
{ "status": "ok", "message": "FieldTrack Unified Backend is running" }
```

---

## 🧱 Architecture Overview

```
Flutter App (Student / Supervisor / Admin)
        │  HTTPS / REST
        ▼
   Nginx (reverse proxy, SSL, static /storage)
        │
        ▼
   Express API  (PM2 cluster, :3000)
        │
        ├── Auth Middleware (JWT Bearer) ──► RBAC (authorizeRole)
        ├── Zod Validation Middleware
        ├── Rate Limiting (express-rate-limit)
        ├── Winston Logging (daily rotated files)
        │
        ▼
   Prisma ORM (PrismaPg adapter)
        │
        ▼
   PostgreSQL
        │
        └── Storage (images/videos/documents on disk, served via /storage)
```

### Module Map

| Module | Path | Responsibilities |
|--------|------|------------------|
| Auth | `src/auth/` | Login, refresh, logout, password reset (OTP), JWT middleware, `/me`, FCM token |
| Admin | `src/admins/` | User CRUD, supervisor assignment, departments, projects, search, audit logs, broadcast, settings, backup, map |
| Dashboard | `src/dashboard/` | Admin/Supervisor/Student aggregated dashboard stats |
| Sessions | `src/sessions/` | GPS check-in / check-out, location pings |
| Activities | `src/activities/` | FieldLog (activity) draft → submit lifecycle |
| Media | `src/media/` | Evidence upload + processing (Sharp, FFmpeg) |
| Reviews | `src/reviews/` | Supervisor review (approve / reject / revision) |
| Reports | `src/reports/` | Supervisor reports with period filters |
| Notifications | `src/notifications/` | In-app notification CRUD |
| Settings | `src/settings/` | Profile, password, security, preferences, avatar, sessions |
| Services | `src/services/` | Audit log service |
| Utils | `src/utils/` | Winston loggers |

---

## 🔐 Authentication & RBAC

All protected routes require a Bearer token:

```
Authorization: Bearer <JWT_ACCESS_TOKEN>
```

- **Access token:** expires in **30 minutes**.
- **Refresh token:** expires in **7 days**, stored hashed in the `RefreshToken` table, rotated on every refresh.
- **Roles:** `STUDENT`, `SUPERVISOR`, `ADMIN` (enforced via `authorizeRole([...])` middleware).

---

## 🗄️ Database

The Prisma schema lives at [`prisma/schema.prisma`](./prisma/schema.prisma).

Key models: `User`, `StudentProfile`, `SupervisorProfile`, `FieldSession`, `LocationPing`, `FieldLog`, `Evidence`, `Review`, `Notification`, `RefreshToken`, `AuditLog`, `SystemSetting`, `UserPreferences`, `Department`.

See [`../docs/03_Database_Design.md`](../docs/03_Database_Design.md) for the full ER design.

---

## 📦 Storage Layout

Uploaded evidence is stored on local disk (configurable via `STORAGE_DIR`):

```
storage/
├── avatars/          # User profile avatars (WebP)
├── images/           # Compressed images + thumbnails
├── videos/           # Videos + thumbnail frames
└── documents/        # PDF / DOCX files
```

Files are organized by `type/YYYY/MM/`. Media is served statically at `/storage/...` with caching and byte-range support for streaming.

---

## 📝 Logging

Winston writes daily-rotated logs under `logs/`:

```
logs/
├── application/app-YYYY-MM-DD.log   (14-day retention)
├── errors/error-YYYY-MM-DD.log      (30-day retention, error level)
├── authentication/auth-YYYY-MM-DD.log (90-day retention)
└── uploads/uploads-YYYY-MM-DD.log   (14-day retention)
```

---

## ☸️ Production & Deployment

- **PM2:** [`ecosystem.config.cjs`](./ecosystem.config.cjs) — cluster mode, auto-restart, 1 GB memory cap.
- **Nginx:** [`nginx/fieldtrack.conf`](./nginx/fieldtrack.conf) — reverse proxy, SSL, static `/storage/` serving.
- **Kubernetes:** [`k8s/deployment.yaml`](./k8s/deployment.yaml), [`k8s/service.yaml`](./k8s/service.yaml).
- **Backups:** [`scripts/backup.sh`](./scripts/backup.sh) — daily DB + uploads + config backups with SHA-256 checksums and 14-day retention.

See [`../docs/09_Deployment_Guide.md`](../docs/09_Deployment_Guide.md) and [`../docs/12_Backup_and_Recovery.md`](../docs/12_Backup_and_Recovery.md).

---

## 📚 API Reference

Full endpoint documentation is available in [`../docs/04_API_Reference.md`](../docs/04_API_Reference.md) and the machine-readable spec at [`../docs/openapi.yaml`](../docs/openapi.yaml).

Base path: `/api/v1`

