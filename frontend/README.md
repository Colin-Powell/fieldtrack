# FieldTrack — Frontend (Flutter)

Flutter application for the **FieldTrack** digital field activity supervision platform. Provides three role-based portals: **Student**, **Supervisor**, and **Admin** — plus offline-first data collection.

---

## ✨ Features

- **Three portals** in one codebase (separate entry points for dedicated builds)
- **Offline-first** — Hive mutation queue + connectivity interceptor + request replay
- **GPS check-in/check-out** with accuracy tracking and live maps (flutter_map)
- **Evidence capture** — images, videos, audio, documents
- **Push notifications** — Firebase Cloud Messaging + local notifications
- **Role-based routing** via GoRouter redirects
- **Resilient networking** — Dio with auth, connectivity, cache, and retry interceptors

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.x (Dart ≥ 3.11)
- Android Studio / Xcode (for mobile)
- A running backend (see [`../backend/README.md`](../backend/README.md))

### 1. Install dependencies

```bash
cd frontend
flutter pub get
```

### 2. Configure environment

Create `frontend/.env`:

```env
# Base URL of the FieldTrack backend API
API_URL=http://127.0.0.1:3000/api/v1
```

> On an Android emulator, use `http://10.0.2.2:3000/api/v1`. On a physical device, use your machine's LAN IP (e.g., `http://192.168.x.x:3000/api/v1`).

### 3. Run the app

| Command | Description |
|---------|-------------|
| `flutter run -d chrome` | Web |
| `flutter run -d windows` | Windows desktop |
| `flutter run -d <android-device>` | Android device/emulator |
| `flutter run -d <ios-simulator>` | iOS simulator (macOS only) |
| `flutter build apk --release` | Release APK |

### Entry Points

| Entry point | Target portal | Notes |
|-------------|---------------|-------|
| `lib/main.dart` | Unified app (all roles) | Redirects by role; includes student + admin routes |
| `lib/main_supervisor.dart` | Supervisor-only build | Separate supervisor router |
| `lib/main_admin.dart` | Admin-only build | Separate admin router |

> The unified `main.dart` also supports the supervisor dashboard endpoints via the shared supervisor router — pick the entry point that matches your build target.

---

## 🗂️ Project Structure

```
lib/
├── main.dart                  # Unified app entry
├── main_supervisor.dart       # Supervisor portal entry
├── main_admin.dart            # Admin portal entry
├── core/
│   ├── app_setup.dart         # Env loading
│   ├── constants/             # AppConstants (colors, API URL resolution)
│   ├── network/               # Dio client + interceptors (auth, connectivity, cache, retry)
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   ├── auth_interceptor.dart
│   │   ├── connectivity_interceptor.dart
│   │   ├── connectivity_service.dart
│   │   ├── offline_queue_service.dart
│   │   └── error_handler.dart
│   ├── providers/             # Riverpod providers (auth, checkin, location, app)
│   ├── router/                # GoRouter configs (app, supervisor, admin)
│   ├── services/              # NotificationService (FCM + local)
│   ├── theme/                 # Material theme
│   ├── utils/                 # Image/time/toast helpers
│   └── widgets/               # Shared widgets (OfflineBanner, AppAvatar)
├── features/
│   ├── auth/                  # Splash, welcome, login, OTP, password reset
│   ├── dashboard/             # Student dashboard
│   ├── field_session/         # Active field session UI
│   ├── activities/            # Activity log CRUD
│   ├── map/                   # Student map
│   ├── notifications/         # In-app notifications
│   ├── profile/               # User profile
│   ├── settings/              # Preferences & settings
│   ├── checkin/               # GPS check-in screen
│   ├── admin/                 # Admin portal (users, departments, projects, audit…)
│   └── supervisor/            # Supervisor portal (dashboard, students, review, reports…)
├── shared/
│   ├── models/                # Shared data models
│   ├── screens/               # Router error screen
│   └── widgets/               # Empty state, skeleton loaders
└── assets/
    └── images/                # App assets
```

---

## 🔌 Networking Layer

The `ApiClient` (singleton) configures Dio with:

1. **ConnectivityInterceptor** — detects offline; queues non-GET mutations in Hive and returns a `202 queued` response.
2. **AuthenticationInterceptor** — attaches `Authorization: Bearer <jwt>`; on `401`, attempts a refresh-token rotation and replays the request.
3. **DioCacheInterceptor** — Hive-backed GET cache with 7-day stale-while-revalidate.
4. **RetryInterceptor** — up to 3 retries with exponential backoff for timeouts/socket errors.
5. **LogInterceptor** — request logging for debugging.

When connectivity is restored, `ApiClient.syncOfflineMutations()` replays the queued requests.

---

## 🧭 Routing

Routing is handled by **GoRouter** with role-based redirects:

- **Unified** (`lib/core/router/app_router.dart`): `/welcome`, `/login`, `/portal` (student), `/admin/*` (admin), `/force-password-change`, etc.
- **Supervisor** (`lib/core/router/supervisor_router.dart`): `/supervisor/login`, `/supervisor/dashboard`, `/supervisor/students`, `/supervisor/student/:id/*`, `/supervisor/reports`, `/supervisor/map`, …
- **Admin** (`lib/core/router/admin_router.dart`): `/admin/login`, `/admin/dashboard`, `/admin/users`, `/admin/departments`, `/admin/projects`, `/admin/audit`, …

Each router guards access by the authenticated user's role and forces a password change when `mustChangePassword` is true.

---

## 📱 Platform Notes

- **Android:** Firebase config (`google-services.json`) is required for push notifications. Verify `android/app/build.gradle.kts` and the manifest include the FCM/messaging setup.
- **Web:** `vercel.json` is present for static hosting. Firebase messaging is skipped on web (`kIsWeb`).
- **Offline queue & secure storage:** tokens are kept in `flutter_secure_storage`; offline queue uses `hive_flutter`.

---

## 🧪 Testing

```bash
cd frontend
flutter test
```

Tests live under `test/` (see `test/widget_test.dart`).

---

## 📚 Related Documentation

- Backend setup: [`../backend/README.md`](../backend/README.md)
- Full documentation set: [`../docs/00_README.md`](../docs/00_README.md)

