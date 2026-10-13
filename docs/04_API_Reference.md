# 04 · API Reference

> 🧑‍💻 **Audience:** Developers integrating with the backend

- **Base URL:** `/api/v1`
- **Auth:** `Authorization: Bearer <JWT>` (except public auth endpoints)
- **Content-Type:** `application/json`
- **Machine-readable spec:** [`openapi.yaml`](./openapi.yaml)

---

## Conventions

| Code | Meaning |
|------|---------|
| `200` | Success |
| `201` | Created |
| `400` | Bad request / validation |
| `401` | Unauthorized (missing/invalid token) |
| `403` | Forbidden (insufficient role) |
| `404` | Not found |
| `409` | Conflict |
| `429` | Too many requests (rate limited) |
| `500` | Internal server error |

Rate limiting (global): **100 requests / 15 min / IP** on `/api`. Login-specific: **5 attempts / 15 min / IP**.

---

## 1. Auth — `/auth`

### POST `/auth/login`
Authenticate with email **or** registration number.

```jsonc
// Request
{ "email": "student@univ.ac.ke", "password": "****" }
// or
{ "registrationNo": "SC/0001/20", "password": "****" }

// Response 200
{
  "success": true,
  "token": "<access-token>",
  "refreshToken": "<refresh-token>",
  "user": {
    "id": "…", "name": "…", "email": "…",
    "role": "STUDENT", "mustChangePassword": false
  }
}
```

**Errors:** `400` (missing fields) · `401` (invalid credentials) · `403` (locked / inactive) · `429` (rate limit)

### POST `/auth/logout`
Body: `{ "refreshToken": "…" }` — revokes the refresh token. *Auth required.*

### POST `/auth/refresh`
Body: `{ "refreshToken": "…" }` — validates, revokes the old token, and issues a new pair (token rotation).

### POST `/auth/change-password`
Body: `{ "currentPassword": "…", "newPassword": "…" }` — updates password and revokes all refresh tokens. *Auth required.*

### POST `/auth/forgot-password`
Body: `{ "email": "…" }` — sends a 6-digit OTP to the email (10-min expiry). Returns generic success to prevent email enumeration.

### POST `/auth/verify-otp`
Body: `{ "email": "…", "otp": "123456" }` — on success returns a short-lived `token` used for `reset-password`.

### POST `/auth/reset-password`
Body: `{ "newPassword": "…" }` — uses the OTP-verified token. *Auth required (temp token).*

### GET `/auth/me`
Returns the authenticated user's profile (role-specific fields). *Auth required.*

### PUT `/auth/fcm-token`
Body: `{ "fcmToken": "…" }` — registers the device push token. *Auth required.*

---

## 2. Admin — `/admin` *(all routes require `ADMIN` role)*

### Users
| Method | Path | Description |
|--------|------|-------------|
| POST | `/users/students` | Create student (returns temporary password) |
| POST | `/users/supervisors` | Create supervisor (returns temporary password) |
| GET | `/users` | List all users (with profiles) |
| GET | `/users/:id` | Full user details incl. audit logs, sessions |
| PUT | `/users/:id` | Update user/profile fields |
| PATCH | `/users/:id/status` | Update status (ACTIVE/SUSPENDED/LOCKED/…) |
| PATCH | `/users/:id/supervisor` | Reassign a student's supervisor |
| POST | `/users/:id/reset-password` | Force password reset (returns temp password) |
| DELETE | `/users/:id` | Soft-delete (archive + revoke sessions) |

**Create student — request example**
```jsonc
{
  "firstName": "Jane", "lastName": "Doe",
  "registrationNo": "SC/0001/20", "email": "jane@univ.ac.ke",
  "phone": "07xx…", "programme": "BSc Environmental Science",
  "department": "Environmental Sciences", "faculty": "Science",
  "researchTopic": "…", "supervisorId": "<supervisor-user-id>"
}
```

### Departments & Projects
| Method | Path | Description |
|--------|------|-------------|
| GET | `/departments` | List departments with student/supervisor/project counts |
| POST | `/departments` | Create department `{ name, code?, faculty?, description? }` |
| GET | `/departments/:id` | Department details (students, supervisors, projects) |
| GET | `/search?q=…` | Global search across users, departments, projects |
| GET | `/projects` | Research projects list with progress |

### Audit, Notifications, Settings, Map
| Method | Path | Description |
|--------|------|-------------|
| GET | `/audit-logs?page=&limit=` | Paginated audit log |
| GET | `/notifications` | Recent system notifications |
| POST | `/notifications/broadcast` | Broadcast to all active students/supervisors |
| GET | `/settings` | System settings (with defaults) |
| PUT | `/settings` | Update system settings |
| GET | `/settings/history` | Last 20 settings-change audit entries |
| POST | `/settings/backup` | Trigger manual backup (logged) |
| GET | `/map` | Active field-session markers for live map |

---

## 3. Dashboards — `/dashboard`

| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | `/dashboard/admin?period=…` | ADMIN | Total students, in-field count, submissions, trends, department stats |
| GET | `/dashboard/supervisor` | SUPERVISOR | Assigned students stats, pending approvals, recent logs, trends |
| GET | `/dashboard/student` | STUDENT | Student status, hours logged, approvals |

`period` supports `Today | This Week | This Month | This Year | All Time`.

---

## 4. Sessions — `/sessions`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/checkin` | Start a field session (GPS required) |
| PATCH | `/checkout` | End the active session |
| GET | `/active?studentId=` | Get active session for a student |
| POST | `/ping` | Log a location ping for a session |
| GET | `/student/:studentId/pings` | All pings for a student (supervisor view) |

**Check-in request**
```jsonc
{
  "studentId": "…",
  "latitude": -3.3256, "longitude": 39.7166, "accuracy": 12.5,
  "batteryLevelStart": 87, "networkType": "4G", "deviceModel": "Pixel 7"
}
```

**Check-in response `201`**
```jsonc
{
  "id": "<session-id>",
  "studentId": "…",
  "checkInTime": "2025-…",
  "startLatitude": -3.3256, "startLongitude": 39.7166,
  "startAccuracy": 12.5, "status": "ACTIVE"
}
```

---

## 5. Activities — `/activities`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/` | Create a draft activity |
| PUT | `/:id` | Update a draft |
| POST | `/:id/submit` | Submit for review |
| GET | `/:id` | Get activity by ID |
| GET | `/student/all?studentId=` | All activities for a student |
| GET | `/supervisor/all?supervisorId=` | All activities for a supervisor |

**Create activity request**
```jsonc
{
  "studentId": "…",
  "title": "Water sampling at Kilifi creek",
  "description": "…",
  "latitude": -3.32, "longitude": 39.71, "gpsAccuracy": 8.0,
  "methodology": "Transect survey",
  "objectives": "…",
  "findings": "…",
  "remarks": "…"
}
```

---

## 6. Media — `/media`

### POST `/media/upload`
`multipart/form-data` — upload evidence attached to an activity.

| Field | Type | Notes |
|-------|------|-------|
| `file` | file | Max **50 MB**; allowed: jpeg, png, webp, mp4, webm, pdf, doc, docx |
| `activityId` | string | required |
| `uploaderId` | string | required |
| `gpsLatitude` / `gpsLongitude` / `gpsAccuracy` | string | optional geo-tag |
| `capturedAt` | string | optional ISO timestamp |

**Response `201`** — Evidence record (`storagePath`, `thumbnailPath`, dimensions, duration, `uploadStatus: "SUCCESS"`).

Images are resized to ≤1920px and compressed (JPEG q80) with a 256×256 thumbnail. Videos get an FFmpeg-generated thumbnail.

---

## 7. Reviews — `/reviews`

### POST `/reviews`
```jsonc
{
  "activityId": "…",
  "reviewerId": "…",
  "rating": 4.5,
  "comments": "Good methodology; revise discussion.",
  "status": "APPROVED"        // or REJECTED | REVISION_REQUESTED
}
```

---

## 8. Reports — `/reports`

### GET `/reports/supervisor?period=This+Month`
Role: `SUPERVISOR` / `ADMIN`. `period`: `This Week | This Month | This Quarter | This Year` (default `This Month`).

**Response**
```jsonc
{
  "stats": { "totalActivities": 42, "reportsSubmitted": 30, "pendingReviews": 5, "approvedLogs": 18 },
  "gaugeMap": { "Field Survey": 0.6, "Transect": 0.4 },
  "trendData": [ { "label": "Mon", "dateLabel": "Monday, Jan 6", "value": 7 } ],
  "recentActivities": [ { "id": "…", "studentName": "…", "activityTitle": "…", "time": "Jan 6", "status": "SUBMITTED" } ],
  "logSummary": [ … ],
  "period": "This Month",
  "periodStart": "2025-01-01T00:00:00.000Z"
}
```

---

## 9. Notifications — `/notifications`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/notifications` | ✅ | User's notifications (latest 50) |
| PATCH | `/notifications/:id/read` | ✅ | Mark one as read |

---

## 10. Settings — `/settings`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/info` | Help/about info (FAQs, support email, privacy policy) |
| GET | `/profile` | Current user profile (sensitive fields stripped) |
| PUT | `/profile` | Update name, phone, department, faculty, specialization, office, topic, programme |
| PUT | `/password` | Change password (current + new) |
| PUT | `/security` | Toggle `twoFactorEnabled`, `loginAlertsEnabled` |
| POST | `/logout-others` | Revoke all other refresh tokens |
| DELETE | `/deactivate` | Suspend + deactivate account |
| PUT | `/preferences` | Upsert user preferences |
| POST | `/avatar` | Upload avatar (`multipart`; converts to WebP 400×400) |
| DELETE | `/sessions/:id` | Revoke a specific session |

---

## 11. Supervisor (unified routes) — `/supervisor`

Defined in `src/index.ts` for the unified entry point:

| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | `/supervisor/dashboard/stats` | SUPERVISOR, ADMIN | checkedOut / checkedIn / inField counts |
| GET | `/supervisor/students` | SUPERVISOR, ADMIN | Assigned students with live status |
| GET | `/supervisor/students/:id` | SUPERVISOR, ADMIN | Full student profile, sessions, activities, statistics, timeline |

---

## 12. Misc

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Service health check |
| GET | `/storage/*` | Static media (30-day immutable cache, byte-range streaming) |

