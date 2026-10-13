# 16 · Developer Guide

> 🧑‍💻 **Audience:** Developers contributing to FieldTrack

---

## 1. Repository Layout

```
fieldtrack/
├── backend/                 # Express + Prisma API
│   ├── src/
│   │   ├── auth/            # JWT, middleware, controller, schemas, email
│   │   ├── admins/          # Admin endpoints
│   │   ├── activities/      # FieldLog CRUD
│   │   ├── sessions/        # Check-in/out + pings
│   │   ├── media/           # Upload & processing
│   │   ├── reviews/         # Review logic
│   │   ├── reports/         # Supervisor reports
│   │   ├── notifications/   # In-app notifications
│   │   ├── settings/        # Profile/preferences
│   │   ├── dashboard/       # Aggregated stats
│   │   ├── services/        # Audit log
│   │   └── utils/           # Winston loggers
│   ├── prisma/schema.prisma
│   ├── k8s/ nginx/ scripts/
│   └── ecosystem.config.cjs
├── frontend/                # Flutter app
│   ├── lib/
│   │   ├── core/            # network, router, providers, theme, services
│   │   ├── features/        # feature modules
│   │   └── shared/          # shared models/widgets
│   └── test/
└── docs/                    # this documentation set
```

---

## 2. Architecture Principles

### Backend
- **Layering:** routes → middlewares → controllers → services → Prisma.
- **Route files** define HTTP surface and wire middleware.
- **Controllers** own HTTP concerns (status codes, error mapping).
- **Services** hold business logic and should be unit-testable.
- **Prisma** is the only data-access layer; no raw SQL outside migrations (with pg adapter pool).
- Use `AuditLogService.log(...)` for any sensitive/admin action.

### Frontend
- **Feature-first** structure: each portal (student/supervisor/admin) is a folder under `features/`.
- **State management:** Riverpod (`StateNotifierProvider` / `Provider`) for app-wide state; `ChangeNotifier`/`provider` where simpler (e.g., `DashboardState`).
- **Routing:** GoRouter with dedicated router files per entry point (`app_router.dart`, `supervisor_router.dart`, `admin_router.dart`). Redirects must handle auth state and role.
- **Networking:** always go through `ApiClient().dio` so interceptors (auth, connectivity, cache, retry) apply.
- **API paths:** reference `ApiEndpoints` constants — never hardcode strings.

---

## 3. Coding Standards

### Backend (TypeScript)
- TypeScript in **ESM** mode (`"type": "module"`). Import with `.js` extensions in relative imports.
- Use `zod` schemas for request validation (see `auth/auth.schema.ts`).
- Controllers return JSON with `{ success, ... }` or `{ error }` consistently.
- Log via the dedicated Winston logger for the module (`authLogger`, `uploadsLogger`, `appLogger`).
- Keep Prisma schema changes reviewed; run `npx prisma generate` after edits.

### Frontend (Dart/Flutter)
- Follow `analysis_options.yaml` (flutter_lints). Run `flutter analyze` before committing.
- Prefer **const constructors** and immutable state classes with `copyWith`.
- Use named routes via GoRouter; avoid `Navigator.push` hacks.
- Format with `dart format .`.
- Keep providers focused; one StateNotifier per domain.

---

## 4. API Conventions

- Base path: `/api/v1`.
- Auth: `Authorization: Bearer <JWT>`.
- Errors: `{ "error": "message" }` with appropriate 4xx/5xx code.
- Success payloads often include `{ "success": true, ... }`.
- Role-gate every protected route with `authenticate` + `authorizeRole([...])`.

See [04_API_Reference.md](./04_API_Reference.md) for the full contract and [openapi.yaml](./openapi.yaml) for the machine-readable spec.

---

## 5. State Management Guidelines

| Concern | Tool | Example |
|---------|------|---------|
| Auth session | Riverpod `StateNotifierProvider` | `authProvider` |
| Check-in state | Riverpod `StateNotifierProvider` | `checkInProvider` |
| Location | Riverpod | `locationProvider` |
| Supervisor dashboard | `ChangeNotifierProvider` (provider) | `DashboardState` |
| Student activities | Riverpod | `student_activities_provider.dart` |
| Router | Riverpod `Provider<GoRouter>` | `routerProvider` |

---

## 6. Offline & Sync Development

- New mutations must flow through `ApiClient().dio` — the `ConnectivityInterceptor` handles queueing automatically.
- Cache policy lives in `api_client.dart` (`CacheOptions`). Add `hitCacheOnErrorExcept` codes deliberately.
- When adding endpoints, ensure GET responses are cache-friendly (stable keys, no per-request randomness).

---

## 7. Database Changes

```bash
cd backend
npx prisma db push     # dev only — push schema directly
npx prisma generate    # regenerate client
npx prisma studio      # inspect
```

For production: use `prisma migrate dev` to generate SQL migrations and commit them under `prisma/migrations/`.

---

## 8. Testing & Quality Gates

```bash
# Backend
cd backend && npm run build   # type-check + compile

# Frontend
cd frontend
flutter analyze               # lints
flutter test                  # tests
```

See [14_Testing.md](./14_Testing.md) for the full strategy.

---

## 9. Deployment Process

1. Merge to `main` after passing CI (analyze/test/build).
2. Backend: `cd backend && npm install && npm run build`, restart PM2:
   ```bash
   pm2 reload fieldtrack-api --update-env
   ```
3. Frontend web: `flutter build web --release`, deploy `build/web`.
4. Mobile: build release APK and distribute.
5. Verify `/health`, login, and a sample field flow.

See [09_Deployment_Guide.md](./09_Deployment_Guide.md).

---

## 10. Contribution Guidelines

1. **Fork** the repository and create a feature branch (`feature/…` or `fix/…`).
2. Keep changes small and focused; reference the issue.
3. Follow the coding standards in this guide.
4. Run backend `build` and frontend `analyze` + `test` before pushing.
5. Update relevant documentation (`docs/`) when behavior changes.
6. Open a **pull request** with a clear description and test notes.
7. A maintainer will review; address feedback in follow-up commits.

### Commit message style
```
feat(activities): add resubmit endpoint
fix(auth): handle refresh token rotation edge case
docs(api): document /reports/supervisor period param
```

