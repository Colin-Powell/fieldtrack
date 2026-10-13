# 09 · Deployment Guide

> 🧑‍💻 **Audience:** DevOps, system administrators

---

## 1. Target Environment

| Component | Requirement |
|-----------|-------------|
| OS | Ubuntu 22.04 / 24.04 LTS |
| Runtime | Node.js ≥ 18 (LTS recommended) |
| Database | PostgreSQL ≥ 14 |
| Process manager | PM2 |
| Reverse proxy | Nginx |
| SSL | Let's Encrypt (Certbot) |
| Optional | Docker / Kubernetes |

---

## 2. Backend Deployment (Ubuntu + Nginx + PM2)

### 2.1 Install prerequisites

```bash
sudo apt update
sudo apt install -y nginx postgresql postgresql-contrib nodejs npm
sudo npm install -g pm2

# Optional: build tools for native modules (sharp, bcrypt)
sudo apt install -y build-essential python3
```

### 2.2 Create deployment user & directory

```bash
sudo useradd -m -s /bin/bash fieldtrack
sudo mkdir -p /var/www/fieldtrack
sudo chown -R fieldtrack:fieldtrack /var/www/fieldtrack
```

### 2.3 Deploy code & install dependencies

```bash
cd /var/www/fieldtrack
git clone <repo-url> .
cd backend
npm install --production
npm run build
```

### 2.4 Configure environment

```bash
sudo -u fieldtrack vim /var/www/fieldtrack/backend/.env
```

```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://fieldtrack:STRONG_PASSWORD@localhost:5432/fieldtrack
JWT_SECRET=$(openssl rand -hex 32)
ADMIN_EMAIL=admin@university.ac.ke
ADMIN_PASSWORD=InitialStrongPass123!
STORAGE_DIR=/var/www/fieldtrack/backend/storage
# SMTP settings for password-reset emails…
SMTP_HOST=smtp.university.ac.ke
SMTP_PORT=587
SMTP_USER=noreply@university.ac.ke
SMTP_PASS=…
```

### 2.5 Initialize database

```bash
cd /var/www/fieldtrack/backend
npx prisma db push
```

### 2.6 Start with PM2

```bash
# Run the PM2 process in cluster mode using the ecosystem file
pm2 start ecosystem.config.cjs --env production
pm2 save
pm2 startup   # follow the printed instructions to enable boot-start
```

### 2.7 Verify

```bash
curl http://127.0.0.1:3000/health
# {"status":"ok","message":"FieldTrack Unified Backend is running"}
```

---

## 3. Nginx Reverse Proxy + SSL

Copy the template from `backend/nginx/fieldtrack.conf`:

```bash
sudo cp /var/www/fieldtrack/backend/nginx/fieldtrack.conf /etc/nginx/sites-available/fieldtrack.conf
sudo ln -s /etc/nginx/sites-available/fieldtrack.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

**Edit `server_name`** to your domain/IP and configure `proxy_pass http://127.0.0.1:3000`.

### 3.1 SSL with Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

The template already includes the hardened HTTPS server block (TLS 1.2/1.3, security headers, gzip, static `/storage/` alias with byte-range support) — uncomment and adjust the paths.

---

## 4. Frontend Deployment

### 4.1 Web (static hosting)

```bash
cd frontend
flutter pub get
flutter build web --release
# Output: build/web
```

Deploy `build/web/` to any static host (Nginx, Vercel — see `frontend/vercel.json`, S3, etc.).

### 4.2 Android APK

```bash
cd frontend
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 4.3 Environment configuration

Create `frontend/.env`:

```env
API_URL=https://api.yourdomain.com/api/v1
```

---

## 5. Kubernetes Deployment (optional)

```bash
cd backend
kubectl create secret generic db-secret --from-literal=DATABASE_URL=postgresql://…
kubectl create secret generic jwt-secret --from-literal=JWT_SECRET=…
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

- `deployment.yaml`: 2 replicas, env from secrets, port 3000.
- `service.yaml`: LoadBalancer → targetPort 3000.

---

## 6. Environment Variables Reference

| Variable | Required | Description |
|----------|:--------:|-------------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `JWT_SECRET` | ✅ | JWT signing key (≥ 32 chars, random) |
| `PORT` | ❌ | API port (default `3000`) |
| `ADMIN_EMAIL` | ❌* | Bootstrap admin email (auto-sync on boot) |
| `ADMIN_PASSWORD` | ❌* | Bootstrap admin password |
| `STORAGE_DIR` | ❌ | Media storage location (default `./storage`) |
| `SMTP_HOST` / `SMTP_PORT` | ❌ | Outbound email for OTP |
| `SMTP_USER` / `SMTP_PASS` | ❌ | SMTP credentials |
| `EMAIL_FROM` | ❌ | From address for emails |

*\* `ADMIN_EMAIL`/`ADMIN_PASSWORD` are required for `npm run db:seed`.*

---

## 7. Firewall & Security Checklist

- Open only ports **22** (SSH), **80/443** (HTTP/HTTPS). Do **not** expose 3000 publicly.
- Use a strong `JWT_SECRET` and rotate it periodically.
- Restrict PostgreSQL to localhost (default).
- Enable `fail2ban` for SSH.
- Configure `logrotate` for `logs/` (daily rotation already handled by Winston).
- Set `NODE_ENV=production` to enable production log levels and disable dev console logs.

---

## 8. Monitoring & Troubleshooting

```bash
pm2 logs fieldtrack-api      # tail API logs
pm2 monit                    # CPU/memory dashboard
sudo tail -f /var/log/nginx/access.log
```

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `429 Too Many Requests` | Rate limit hit | Check `express-rate-limit` config; ensure Nginx forwards `X-Forwarded-For` |
| `ECONNREFUSED` DB | DB not started / wrong URL | `systemctl status postgresql`, verify `DATABASE_URL` |
| `JWT_SECRET must be configured` | Env missing | Add to `.env` and restart |
| Media 404 on `/storage/` | Nginx alias path wrong | Align `alias` with `STORAGE_DIR` |
| Memory restarts | Heap pressure | PM2 `max_memory_restart: 1G` already set; investigate leaks |

