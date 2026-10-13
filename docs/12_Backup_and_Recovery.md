# 12 · Backup & Recovery

> 🧑‍💻 **Audience:** DevOps, system administrators

---

## 1. Overview

FieldTrack ships an automated backup script (`backend/scripts/backup.sh`) that covers **three** critical assets:

1. **PostgreSQL database** (`pg_dump`)
2. **Media uploads** (`storage/`)
3. **Configuration** (`.env`, PM2 ecosystem, Nginx config)

---

## 2. Backup Script (`scripts/backup.sh`)

### What it does (daily)
```bash
# 1. Creates dated backup directories
# 2. Dumps DB → gzip + SHA-256 checksum
pg_dump -U postgres fieldtrack | gzip > fieldtrack-YYYY-MM-DD.sql.gz
sha256sum ... > fieldtrack-YYYY-MM-DD.sql.gz.sha256

# 3. Tars the media storage dir → gzip + checksum
tar -czf uploads-YYYY-MM-DD.tar.gz -C /var/www/fieldtrack/backend storage

# 4. Tars config files (.env, ecosystem.config.cjs, nginx conf) → gzip + checksum

# 5. Retention cleanup: deletes backups older than 14 days
find ... -mtime +14 -delete
```

### Configuration
| Setting | Value | Notes |
|---------|-------|-------|
| `BACKUP_ROOT` | `/opt/backups` | Adjust as needed |
| `DB_USER` | `postgres` | Use `.pgpass` for non-interactive dumps |
| `DB_NAME` | `fieldtrack` | |
| `RETENTION_DAYS` | `14` | Retention window |
| `APP_DIR` | `/var/www/fieldtrack/backend` | Source of uploads/config |

### Schedule with cron
```cron
# Run every day at 2:00 AM
0 2 * * * /var/www/fieldtrack/backend/scripts/backup.sh >> /var/log/fieldtrack-backup.log 2>&1
```

---

## 3. Backup Layout

```
/opt/backups/
├── database/
│   ├── fieldtrack-2025-01-06.sql.gz
│   └── fieldtrack-2025-01-06.sql.gz.sha256
├── uploads/
│   ├── uploads-2025-01-06.tar.gz
│   └── uploads-2025-01-06.tar.gz.sha256
└── config/
    ├── config-2025-01-06.tar.gz
    └── config-2025-01-06.tar.gz.sha256
```

---

## 4. Off-Site / Cloud Sync (Phase 2)

The script's footer includes a placeholder for **S3 synchronization**:

```bash
# Phase 2: Add S3 synchronization here
# e.g., aws s3 sync /opt/backups s3://your-bucket-name/backups --delete
```

Recommended additions:
- `aws s3 sync` or `rclone` to object storage (S3-compatible).
- Encrypt backups before upload (GPG / KMS).
- Keep **≥ 3 copies**: local, off-site, and a monthly immutable snapshot.

---

## 5. Restore Process

### 5.1 Database restore
```bash
gunzip -c /opt/backups/database/fieldtrack-YYYY-MM-DD.sql.gz | psql -U postgres fieldtrack
# Verify checksum first:
sha256sum -c fieldtrack-YYYY-MM-DD.sql.gz.sha256
```

### 5.2 Uploads restore
```bash
tar -xzf /opt/backups/uploads/uploads-YYYY-MM-DD.tar.gz -C /var/www/fieldtrack/backend
# Ensure correct ownership:
chown -R fieldtrack:fieldtrack /var/www/fieldtrack/backend/storage
```

### 5.3 Config restore
```bash
tar -xzf /opt/backups/config/config-YYYY-MM-DD.tar.gz -C /var/www/fieldtrack/backend
pm2 restart fieldtrack-api
```

### 5.4 Post-restore verification
```bash
curl http://127.0.0.1:3000/health
curl http://127.0.0.1:3000/storage/<some-file>   # media serving OK
pm2 status                                       # app online
```

---

## 6. Backup Strategy Summary

| Aspect | Strategy |
|--------|----------|
| Frequency | Daily (cron @ 2 AM) |
| Retention | 14 days local |
| Integrity | SHA-256 checksums for every artifact |
| Coverage | DB + uploads + config |
| Media | Incremental/full tar of `storage/` |
| Manual trigger | Admin panel → `POST /admin/settings/backup` (logs `MANUAL_BACKUP` audit entry) |
| Off-site | Phase 2: S3 sync |
| RPO | ≤ 24 hours (daily) |
| RTO | ~ 30–60 minutes (restore + smoke test) |

---

## 7. Monitoring Backups

- Add a cron wrapper that alerts on failure (e.g., sends an email if `backup.sh` exits non-zero).
- Watch `/var/log/fieldtrack-backup.log`.
- Verify a restore **at least quarterly**.

