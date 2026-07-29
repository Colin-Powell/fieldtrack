# Admin Department Management - Remove Hardcoded Data & Real API Integration

## Steps

### Backend

- [ ] 1. Add `SystemSetting` model to Prisma schema for settings storage
- [ ] 2. Add backend endpoints in `admins.controller.ts`:
  - [ ] `/admin/departments` - GET departments with student/supervisor counts
  - [ ] `/admin/projects` - GET aggregated project data from field logs
  - [ ] `/admin/audit-logs` - GET paginated audit logs
  - [ ] `/admin/notifications` - GET all notifications
  - [ ] `/admin/settings` - GET/PUT system settings
- [ ] 3. Register new routes in `admins.routes.ts`

### Frontend

- [ ] 4. Update `admin_departments_screen.dart` - Replace hardcoded cards with API data
- [ ] 5. Update `admin_projects_screen.dart` - Replace hardcoded table rows with API data
- [ ] 6. Update `admin_reports_screen.dart` - Connect report generation to backend
- [ ] 7. Update `admin_map_screen.dart` - Fetch markers from backend API
- [ ] 8. Update `admin_notifications_screen.dart` - Connect to notification API
- [ ] 9. Update `admin_audit_screen.dart` - Connect to audit log API
- [ ] 10. Update `admin_settings_screen.dart` - Connect to settings API

### Verify & Test

- [ ] 11. Ensure backend compiles and endpoints return valid data
- [ ] 12. Ensure frontend compiles without errors

