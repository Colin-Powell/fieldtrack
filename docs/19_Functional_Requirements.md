# 19 · Functional Requirements

> 🎓 **Audience:** Academic / project report readers, QA, product owners

---

## 1. Functional Requirements (FR)

### FR-1 · Authentication & Account Management

| ID | Requirement | Priority | Status |
|----|-------------|:--------:|:------:|
| FR-1.1 | Users can log in with **email** or **registration number** + password | Must | ✅ |
| FR-1.2 | First-time / admin-created users are **forced to change their password** | Must | ✅ |
| FR-1.3 | Users can recover their password via **email OTP** | Must | ✅ |
| FR-1.4 | OTP is 6 digits and expires after **10 minutes** | Must | ✅ |
| FR-1.5 | Accounts lock after **5 failed attempts** for **15 minutes** | Must | ✅ |
| FR-1.6 | Sessions use **JWT access + refresh tokens** with rotation | Must | ✅ |
| FR-1.7 | Users can view and **revoke active sessions** | Should | ✅ |
| FR-1.8 | Users can **deactivate** their account | Should | ✅ |

### FR-2 · Student Field Operations

| ID | Requirement | Priority | Status |
|----|-------------|:--------:|:------:|
| FR-2.1 | Student can **check in** to a field session with GPS coords + accuracy | Must | ✅ |
| FR-2.2 | System **blocks duplicate active sessions** for the same day | Must | ✅ |
| FR-2.3 | Student can **check out** — duration, distance, avg accuracy recorded | Must | ✅ |
| FR-2.4 | Student can **log field activities** (title, description, methodology, objectives, findings, remarks) | Must | ✅ |
| FR-2.5 | Activities follow a **draft → submit → review** lifecycle | Must | ✅ |
| FR-2.6 | Student can **upload evidence** (images, videos, documents) geo-tagged | Must | ✅ |
| FR-2.7 | Evidence is **compressed/thumbnailed** server-side | Should | ✅ |
| FR-2.8 | Student can **view supervisor feedback** on each activity | Must | ✅ |
| FR-2.9 | Student can **revise and resubmit** when revision is requested | Must | ✅ |

### FR-3 · Supervisor Monitoring & Review

| ID | Requirement | Priority | Status |
|----|-------------|:--------:|:------:|
| FR-3.1 | Supervisor sees a **dashboard** with assigned-student stats | Must | ✅ |
| FR-3.2 | Supervisor can view **live map** of students in the field | Must | ✅ |
| FR-3.3 | Supervisor can open a **student profile** (sessions, logs, stats, timeline) | Must | ✅ |
| FR-3.4 | Supervisor can **review activities** (approve / reject / request revision) with rating & comments | Must | ✅ |
| FR-3.5 | Supervisor can generate **reports** filtered by week/month/quarter/year | Must | ✅ |
| FR-3.6 | Supervisor can **export/print** reports | Should | ✅ |
| FR-3.7 | Supervisor can view a student's **GPS ping history** | Should | ✅ |

### FR-4 · Administration

| ID | Requirement | Priority | Status |
|----|-------------|:--------:|:------:|
| FR-4.1 | Admin can **create student & supervisor accounts** (temp password) | Must | ✅ |
| FR-4.2 | Admin can **edit users** and change their status | Must | ✅ |
| FR-4.3 | Admin can **reassign supervisors** to students | Must | ✅ |
| FR-4.4 | Admin can **reset passwords** | Must | ✅ |
| FR-4.5 | Admin can **archive (soft-delete)** users | Must | ✅ |
| FR-4.6 | Admin can **manage departments** (create, drill-down) | Must | ✅ |
| FR-4.7 | Admin can view **projects** with progress | Should | ✅ |
| FR-4.8 | Admin can **broadcast notifications** to all users | Must | ✅ |
| FR-4.9 | Admin can review the **audit log** (paginated) | Must | ✅ |
| FR-4.10 | Admin can configure **system settings** (GPS radius, SMTP, backup, password policy…) | Must | ✅ |
| FR-4.11 | Admin can view an **institution-wide live map** | Should | ✅ |
| FR-4.12 | Admin can **trigger manual backup** | Should | ✅ |

### FR-5 · Dashboards & Reports

| ID | Requirement | Priority | Status |
|----|-------------|:--------:|:------:|
| FR-5.1 | Student dashboard shows status, hours logged, approvals, recent logs | Must | ✅ |
| FR-5.2 | Supervisor dashboard shows in-field/checked-in/checked-out, pending approvals, trends | Must | ✅ |
| FR-5.3 | Admin dashboard shows totals, trends, department stats, system activity | Must | ✅ |
| FR-5.4 | Reports support period filters (Week / Month / Quarter / Year) | Must | ✅ |
| FR-5.5 | Trend charts adapt interval granularity to the period | Should | ✅ |

### FR-6 · Offline Support

| ID | Requirement | Priority | Status |
|----|-------------|:--------:|:------:|
| FR-6.1 | Non-GET requests **queue locally** when offline | Must | ✅ |
| FR-6.2 | Queued requests **replay automatically** on reconnect | Must | ✅ |
| FR-6.3 | GET requests are served from **cache** when offline (7-day stale) | Must | ✅ |
| FR-6.4 | Network failures **retry** (3 attempts with backoff) | Must | ✅ |
| FR-6.5 | Conflicts (HTTP 409) are dropped from the queue | Should | ✅ |

### FR-7 · Notifications

| ID | Requirement | Priority | Status |
|----|-------------|:--------:|:------:|
| FR-7.1 | In-app notifications for check-in/out, submissions, reviews | Must | ✅ |
| FR-7.2 | Users can **mark notifications as read** | Must | ✅ |
| FR-7.3 | Admin can **broadcast** notifications | Must | ✅ |
| FR-7.4 | **Push notifications** via Firebase Cloud Messaging | Should | ✅ |

### FR-8 · Media & Evidence

| ID | Requirement | Priority | Status |
|----|-------------|:--------:|:------:|
| FR-8.1 | Upload images, videos, and documents (max 50 MB) | Must | ✅ |
| FR-8.2 | Server validates **MIME types** and size | Must | ✅ |
| FR-8.3 | Images are resized/compressed; videos get **thumbnails** | Should | ✅ |
| FR-8.4 | Evidence is **geo-tagged** and time-stamped | Should | ✅ |
| FR-8.5 | Media streams with **byte-range support** | Should | ✅ |

---

## 2. Non-Functional Requirements (NFR)

### NFR-1 · Security
- **S1** Passwords hashed with bcrypt (cost ≥ 10). ✅
- **S2** JWT with short-lived access tokens (30 min) + rotating refresh tokens. ✅
- **S3** Role-based access control on all protected routes. ✅
- **S4** Rate limiting (global + login). ✅
- **S5** Security headers via Helmet; HTTPS in production. ✅
- **S6** Audit trail for sensitive actions. ✅
- **S7** Input validation (Zod on auth; controller checks elsewhere). ✅

### NFR-2 · Performance
- **P1** API response p95 < 500 ms for dashboard/report queries. ⏳ (target)
- **P2** Support ≥ 100 concurrent users. ⏳ (target)
- **P3** Media upload processing (image) p95 < 2 s. ⏳ (target)

### NFR-3 · Scalability
- **SC1** PM2 cluster mode across CPUs. ✅
- **SC2** Horizontal scaling via Kubernetes manifests. ✅
- **SC3** Stateless API (tokens in DB; sessions in DB) enabling multi-instance. ✅

### NFR-4 · Availability
- **A1** PM2 auto-restart on crash. ✅
- **A2** Nginx `proxy_pass` with load balancing. ✅
- **A3** Daily automated backups with checksums. ✅
- **A4** Target 99.9% uptime. ⏳ (target)

### NFR-5 · Offline / Resilience
- **O1** Offline mutation queue + replay. ✅
- **O2** GET caching (stale-while-revalidate, 7 days). ✅
- **O3** Retry with exponential backoff. ✅

### NFR-6 · Maintainability
- **M1** Layered backend architecture (routes/controllers/services). ✅
- **M2** Feature-first Flutter structure. ✅
- **M3** TypeScript + Dart static typing. ✅
- **M4** Linting (`flutter_lints`, `tsc`). ✅

### NFR-7 · Reliability
- **R1** Conflict handling on sync (409). ✅
- **R2** Validation before persistence. ✅
- **R3** Graceful error messages (`ErrorHandler`, friendly toasts). ✅

### NFR-8 · Usability
- **U1** Intuitive three-portal navigation. ✅
- **U2** Offline banner + queued-action toasts. ✅
- **U3** Skeleton loaders & empty states. ✅
- **U4** Responsive Flutter UI (mobile + web). ✅

### NFR-9 · Portability
- **PO1** Flutter targets Android, Web, Windows, macOS, iOS, Linux. ✅
- **PO2** Backend runs on any Node.js ≥ 18 host; PostgreSQL-backed. ✅
- **PO3** K8s + Docker-ready manifests. ✅

---

## 3. Requirement Traceability (sample)

| Requirement | Source | Module | Verified by |
|-------------|--------|--------|-------------|
| FR-2.1 GPS check-in | Objective 1 | `sessions/` + `checkin_provider` | Manual + API test |
| FR-3.4 Review activity | Objective 4 | `reviews/` + supervisor review screen | Manual |
| FR-4.1 Create user | Admin objective | `admins/` | Manual |
| FR-6.1 Offline queue | Objective 7 | `offline_queue_service.dart` | Manual |

