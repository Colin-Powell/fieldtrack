#!/bin/bash
# FieldTrack Backup Script
# Automatically creates daily backups, generates checksums, and purges old backups.

# Directories
BACKUP_ROOT="/opt/backups"
DB_BACKUP_DIR="$BACKUP_ROOT/database"
UPLOAD_BACKUP_DIR="$BACKUP_ROOT/uploads"
CONFIG_BACKUP_DIR="$BACKUP_ROOT/config"
APP_DIR="/var/www/fieldtrack/backend" # Update with actual path

# Timestamp
DATE=$(date +%Y-%m-%d)
RETENTION_DAYS=14

# Database Config
DB_USER="postgres"
DB_NAME="fieldtrack"
# Consider using .pgpass for passwordless pg_dump

echo "Starting FieldTrack Backup for $DATE..."

# 1. Create Directories
mkdir -p "$DB_BACKUP_DIR" "$UPLOAD_BACKUP_DIR" "$CONFIG_BACKUP_DIR"

# 2. Database Backup
DB_FILE="fieldtrack-$DATE.sql.gz"
echo "Backing up PostgreSQL database to $DB_FILE..."
pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$DB_BACKUP_DIR/$DB_FILE"
sha256sum "$DB_BACKUP_DIR/$DB_FILE" > "$DB_BACKUP_DIR/$DB_FILE.sha256"

# 3. Uploads (Media) Backup
UPLOAD_FILE="uploads-$DATE.tar.gz"
echo "Backing up uploads to $UPLOAD_FILE..."
if [ -d "$APP_DIR/storage" ]; then
  tar -czf "$UPLOAD_BACKUP_DIR/$UPLOAD_FILE" -C "$APP_DIR" storage
  sha256sum "$UPLOAD_BACKUP_DIR/$UPLOAD_FILE" > "$UPLOAD_BACKUP_DIR/$UPLOAD_FILE.sha256"
else
  echo "Uploads directory not found at $APP_DIR/storage, skipping."
fi

# 4. Config Backup
CONFIG_FILE="config-$DATE.tar.gz"
echo "Backing up configuration to $CONFIG_FILE..."
tar -czf "$CONFIG_BACKUP_DIR/$CONFIG_FILE" -C "$APP_DIR" .env ecosystem.config.cjs nginx/fieldtrack.conf 2>/dev/null
sha256sum "$CONFIG_BACKUP_DIR/$CONFIG_FILE" > "$CONFIG_BACKUP_DIR/$CONFIG_FILE.sha256"

# 5. Retention Cleanup
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$DB_BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete
find "$UPLOAD_BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete
find "$CONFIG_BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete

echo "Backup process completed successfully."
# Phase 2: Add S3 synchronization here
# e.g., aws s3 sync /opt/backups s3://your-bucket-name/backups --delete
