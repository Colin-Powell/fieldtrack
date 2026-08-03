# 15 · User Manual

> 👤 **Audience:** Students, supervisors, administrators, IT support

---

## Part A — Student Guide

### 1. Getting Started
1. Install the **FieldTrack** app (Android) or open the web version.
2. Log in with your **university email** or **registration number** and your password.
3. On your **first login**, you will be asked to **change your password**. Choose a strong password and keep it private.

> Forgot your password? Tap **Forgot Password** on the login screen. Enter your email, use the 6-digit OTP you receive, and set a new password.

### 2. Checking In (Starting a Field Session)
1. Make sure **GPS/Location** is enabled on your device.
2. From the Home screen, tap **Check In**.
3. Wait for the GPS fix (the button stays disabled until your location is accurate).
4. Your field session begins. You can now log activities and attach evidence.

### 3. Recording an Activity
1. Tap the **+** (Add Activity) button.
2. Fill in:
   - **Title** (e.g., *Water sampling at Kilifi creek*)
   - **Description**
   - **Methodology**, **Objectives**, **Findings**, **Remarks** (as required)
3. Your GPS coordinates are attached automatically.
4. Save as **Draft**, or **Submit for Review** when complete.

### 4. Adding Evidence
- Tap **Add Evidence** on an activity.
- Choose from:
  - 📷 **Photo** (camera/gallery)
  - 🎥 **Video** (record/select)
  - 📄 **Document** (PDF/DOCX)
- Your photos/videos are automatically compressed and **geo-tagged** for authenticity.

### 5. Submitting & Tracking
- Submit your activity when ready — it moves to **Under Review**.
- Check the activity detail screen for your supervisor's **feedback**.
- If **revision is requested**, edit and resubmit.

### 6. Checking Out
- When done in the field, tap **Check Out**.
- Your session duration, distance, and average GPS accuracy are recorded.

### 7. Offline Mode
- **No internet?** No problem. Actions are **queued** on your device and synchronized automatically when you reconnect.
- You'll see a message confirming your action is queued.

### 8. Notifications & Profile
- **Notifications** tab: review system updates and supervisor messages.
- **Settings**: manage notification preferences, theme, date/time format, and security.
- **Profile**: update your avatar and contact details.

---

## Part B — Supervisor Guide

### 1. Getting Started
1. Log in with your **university email** and password (use **Forgot Password** if needed).
2. On first login, set a new password.

### 2. Dashboard
The dashboard shows at a glance:
- Students **in the field**, **checked in**, and **checked out**
- **Pending approvals** (activities awaiting your review)
- Recent activity and trends

### 3. Monitoring Students
- **Students** list: view every assigned student with live status.
- Open a **student profile** to see:
  - Field sessions & check-in history
  - All field logs with evidence
  - Statistics (field days, activities, distance travelled, GPS accuracy)
  - Timeline of activity

### 4. Live Map
- Open **Map** to see real-time positions of students currently in the field.
- Tap a marker to see student details.

### 5. Reviewing Activities
1. Open a submitted activity.
2. Review the log and **evidence**.
3. Decide:
   - ✅ **Approve** — mark as completed.
   - 🔄 **Request Revision** — ask the student to improve specific parts.
   - ❌ **Reject** — reject with comments.
4. Add a **rating** and **comments** to guide the student.

### 6. Reports
- Open **Reports**.
- Choose a period: **This Week / This Month / This Quarter / This Year**.
- Review stats, methodology breakdown, trend charts, and the recent-activity feed.
- Use **Export/Print** to save or share the report.

### 7. Settings & Profile
- Adjust notification preferences, security settings, and personal profile.
- Use **Log out all other sessions** if you suspect unauthorized access.

---

## Part C — Administrator Guide

### 1. Getting Started
- Log in with the administrator account provided by IT.
- On first login, change your password.

### 2. Dashboard
Institution-wide overview:
- Total students & active supervisors
- Students in field, submissions, pending reviews
- Activity/attendance trends, submission status, department stats
- Recent users & system activity

### 3. Managing Users
**Create a Student:**
1. **Users → Add User → Student**
2. Enter names, registration number, email, programme, department, faculty, research topic.
3. Optionally assign a supervisor.
4. The system returns a **temporary password** — share it securely with the student.

**Create a Supervisor:**
1. **Users → Add User → Supervisor**
2. Enter full name, email, staff number, department, specialization, office, capacity.
3. Share the temporary password.

**Other actions:**
- **Edit** user details.
- **Change status** (Active / Suspended / Locked / Archived).
- **Reset password** (generates a new temporary password).
- **Reassign supervisor**.
- **Archive** (soft-delete) a user.

### 4. Departments
- **Departments** screen: view departments with student/supervisor/project counts.
- **Add Department**: name, code, faculty, description.
- Open a department to see its students, supervisors, and projects.

### 5. Projects
- **Projects** screen lists research projects with topic, supervisor, student, and progress.

### 6. Live Map
- **Map** shows all active field sessions across the institution.

### 7. Notifications & Broadcast
- **Notifications**: recent system notifications.
- **Broadcast**: send an announcement to all active students and supervisors (title + message).

### 8. Audit Logs
- **Audit** screen shows a paginated history of admin actions (who did what, when, and from where).

### 9. System Settings
Configure:
- University name & contact info
- Session timeout
- 2FA / SSO toggles
- GPS deviation radius & sync interval
- SMTP (email) settings
- Backup frequency & auto-backup
- Password policy & max login attempts
- S3 bucket / Slack webhook (optional integrations)

### 10. Backups
- The system performs **automatic daily backups** (see [12_Backup_and_Recovery.md](./12_Backup_and_Recovery.md)).
- Use **Settings → Backup** to trigger a manual backup (logged to audit).

---

## Part D — Installation & Deployment

> For detailed deployment instructions, see the [09_Deployment_Guide.md](./09_Deployment_Guide.md).

### Quick local setup
```bash
# Backend
cd backend
npm install
cp .env.example .env   # set DATABASE_URL, JWT_SECRET, ADMIN_EMAIL, ADMIN_PASSWORD
npx prisma db push
npm run dev

# Frontend
cd frontend
flutter pub get
flutter run -d chrome   # or your preferred device
```

---

## Part E — Troubleshooting

| Issue | Solution |
|-------|----------|
| **Can't log in** | Verify email/reg number + password. Use **Forgot Password** to reset. Check account status with your admin. |
| **Check-in button disabled** | Enable device GPS and wait for the location fix. Try moving to an open area. |
| **"No internet" / actions queued** | You're offline. Actions sync automatically when connectivity returns. |
| **Upload fails** | Ensure the file is ≤ 50 MB and a supported type (JPEG, PNG, WebP, MP4, WebM, PDF, DOC/DOCX). |
| **Not receiving push notifications** | Enable notifications for FieldTrack in device settings; ensure FCM is configured. |
| **App shows stale data** | Pull to refresh; cached data refreshes in the background. |
| **Forgot where something is** | Use the **Search** bar in the Admin portal for users, departments, and projects. |

---

## Part F — Support & Feedback

- **Support email:** as configured by your institution (default: `support@fieldtrack.com`).
- Report bugs or suggest features to your system administrator.

