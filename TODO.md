# TODO - Session Expiry Redirection Fix

## Tasks
- [ ] 1. Fix `backend/src/developer/developer.html` - `expireSession()` should explicitly redirect to `/developer-login`
- [ ] 2. Add `onSessionExpired` static callback in `frontend/lib/core/network/auth_interceptor.dart` to notify app on 401
- [ ] 3. Register `onSessionExpired` in `frontend/lib/core/providers/auth_provider.dart` to clear auth state (triggers router redirect)
- [ ] 4. Verify with `flutter analyze`
