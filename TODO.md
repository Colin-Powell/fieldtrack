# Supervisor Reports - Time Filter & Export/Print Implementation

## Steps

### 1. Backend: Update `reports.controller.ts`
- [ ] Accept `period` query parameter (This Week, This Month, This Quarter, This Year)
- [ ] Calculate period start date based on selection
- [ ] Filter all stats by the period date range
- [ ] Adjust trend data intervals based on period

### 2. Frontend: Update `supervisor_reports_provider.dart`
- [ ] Accept period parameter in the API call

### 3. Frontend: Update `supervisor_reports_screen.dart`
- [ ] Pass period query param to API call in `_loadDashboard()`
- [ ] Wire time filter change to reload data from API
- [ ] Implement real export (CSV/pdf)
- [ ] Add print button and printing functionality
