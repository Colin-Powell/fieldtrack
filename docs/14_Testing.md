# 14 · Testing

> 🧑‍💻 **Audience:** Developers, QA

---

## 1. Testing Strategy

FieldTrack follows a **layered testing strategy**:

| Layer | What is tested | Current status |
|-------|----------------|----------------|
| Unit tests | Isolated functions, services, providers | ⚠️ Partial (frontend widget test present) |
| Integration tests | API + DB flows (auth, sessions, reviews) | ⏳ Planned |
| Manual tests | Portal workflows, GPS, offline sync | ✅ Manual QA runs |
| Acceptance tests | End-to-end user journeys | ⏳ Planned |
| Performance tests | API load, media throughput | ⏳ Planned |

---

## 2. Frontend Testing

```bash
cd frontend
flutter test
```

Existing test: `test/widget_test.dart` (basic widget smoke test).

### Recommended coverage
| Area | Test type | Files |
|------|-----------|-------|
| Auth provider | Unit (mocked Dio) | `test/providers/auth_provider_test.dart` |
| Router redirects | Widget/unit | `test/router/` |
| Offline queue | Unit (Hive box) | `test/network/offline_queue_test.dart` |
| Check-in provider | Unit | `test/providers/checkin_provider_test.dart` |
| Key screens | Widget | `test/features/` |

---

## 3. Backend Testing

```bash
cd backend
npm test
```

> Test runner setup (e.g., Vitest/Jest) is not yet configured — recommended as a next step.

### Recommended coverage
| Module | Test cases |
|--------|-----------|
| Auth | login success/failure, lockout, refresh rotation, OTP expiry, RBAC 401/403 |
| Sessions | check-in duplicate, checkout without session, ping validation |
| Activities | draft→submit lifecycle, cannot edit after submit |
| Reviews | valid/invalid status, cannot review non-existent activity |
| Reports | period filtering correctness (week/month/quarter/year) |
| Admin | user CRUD, supervisor reassignment, audit log creation |

---

## 4. Manual Test Checklist

### Student portal
- [ ] Login with email and with registration number.
- [ ] First-login forced password change.
- [ ] Forgot password → OTP email → reset.
- [ ] Check-in blocked until GPS fix available.
- [ ] Check-in → create activity → upload image/video/document → submit.
- [ ] Offline mode: create activity → see "queued" → reconnect → synced.
- [ ] View feedback after supervisor review.

### Supervisor portal
- [ ] Dashboard stats reflect assigned students.
- [ ] Live map shows in-field students.
- [ ] Student profile shows sessions, activities, evidence, stats, timeline.
- [ ] Review flow: approve / reject / revision, rating & comments.
- [ ] Reports period filter (Week/Month/Quarter/Year) updates charts & export.

### Admin portal
- [ ] Create student & supervisor (temp password returned).
- [ ] Reassign supervisor; verify student profile updates.
- [ ] Departments CRUD and drill-down.
- [ ] Broadcast notification reaches student/supervisor in-app lists.
- [ ] Audit log captures actions.
- [ ] Settings update persists; history records changes.

---

## 5. Acceptance Criteria (sample)

| Journey | Given | When | Then |
|---------|-------|------|------|
| Student submits activity | student logged in, in field | submits activity with evidence | status `SUBMITTED`, supervisor sees it as pending |
| Supervisor approves | activity submitted | approves with rating | student sees `APPROVED` + feedback |
| Admin creates user | admin logged in | creates student | user appears in list, can log in with temp password |
| Offline sync | device offline | create + submit activity | queued; after reconnect, appears on server |

---

## 6. Performance Testing (Planned)

| Scenario | Target |
|----------|--------|
| Concurrent logins | ≥ 200 req/s |
| Check-in throughput | ≥ 100 req/s |
| Media upload (5 MB image) | p95 < 2 s |
| Reports (This Year) | p95 < 500 ms |
| Sustained pings (10 Hz × 100 students) | stable under load |

Tools: `k6` or `Artillery` for load; `artillery` + Nginx access logs for latency.

---

## 7. CI/CD Recommendations

```yaml
# .github/workflows/ci.yml (suggested)
- backend: install → lint (tsc) → test → build
- frontend: flutter analyze → flutter test → build apk/web
```

Add a PostgreSQL service container for backend integration tests.

