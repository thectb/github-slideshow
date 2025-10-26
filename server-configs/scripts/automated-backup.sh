#!/bin/bash
#
# Automated WordPress + Database Backup Script
# Backs up WordPress files and MySQL database daily
#

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d-%H%M%S)
RETENTION_DAYS=7  # Keep backups for 7 days
LOGFILE="/var/log/backup.log"

# WordPress installation
SITE_PATH="/var/www/ribbonfoldedpeptides.com/html"
SITE_NAME="ribbonfoldedpeptides"

# Database credentials (read from wp-config.php)
if [ -f "$SITE_PATH/wp-config.php" ]; then
    DB_NAME=$(grep "DB_NAME" "$SITE_PATH/wp-config.php" | cut -d"'" -f4)
    DB_USER=$(grep "DB_USER" "$SITE_PATH/wp-config.php" | cut -d"'" -f4)
    DB_PASS=$(grep "DB_PASSWORD" "$SITE_PATH/wp-config.php" | cut -d"'" -f4)
else
    echo "[ERROR] wp-config.php not found!" | tee -a "$LOGFILE"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

log "=== Backup Started ==="

# ============================================
# 1. Backup Database
# ============================================
log "Backing up database: $DB_NAME"

mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "$BACKUP_DIR/${SITE_NAME}_db_${DATE}.sql.gz"

if [ $? -eq 0 ]; then
    DB_SIZE=$(du -h "$BACKUP_DIR/${SITE_NAME}_db_${DATE}.sql.gz" | cut -f1)
    log "✓ Database backup complete ($DB_SIZE)"
else
    log "✗ Database backup FAILED"
fi

# ============================================
# 2. Backup WordPress Files
# ============================================
log "Backing up WordPress files: $SITE_PATH"

# Exclude cache and temporary files
tar -czf "$BACKUP_DIR/${SITE_NAME}_files_${DATE}.tar.gz" \
    --exclude="$SITE_PATH/wp-content/cache/*" \
    --exclude="$SITE_PATH/wp-content/uploads/wc-logs/*" \
    --exclude="$SITE_PATH/wp-content/debug.log" \
    "$SITE_PATH" 2>/dev/null

if [ $? -eq 0 ]; then
    FILES_SIZE=$(du -h "$BACKUP_DIR/${SITE_NAME}_files_${DATE}.tar.gz" | cut -f1)
    log "✓ Files backup complete ($FILES_SIZE)"
else
    log "✗ Files backup FAILED"
fi

# ============================================
# 3. Backup NGINX Configuration
# ============================================
log "Backing up NGINX configuration"

tar -czf "$BACKUP_DIR/nginx_config_${DATE}.tar.gz" \
    /etc/nginx/conf.d/ \
    /etc/nginx/sites-available/ \
    /etc/nginx/sites-enabled/ 2>/dev/null

# ============================================
# 4. Delete Old Backups
# ============================================
log "Cleaning old backups (older than $RETENTION_DAYS days)"

find "$BACKUP_DIR" -name "${SITE_NAME}_*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "nginx_*.gz" -mtime +$RETENTION_DAYS -delete

BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/${SITE_NAME}_*.gz 2>/dev/null | wc -l)
log "Current backups: $BACKUP_COUNT"

# ============================================
# 5. Calculate Total Backup Size
# ============================================
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
DISK_FREE=$(df -h "$BACKUP_DIR" | tail -1 | awk '{print $4}')

log "Total backup size: $TOTAL_SIZE"
log "Disk space free: $DISK_FREE"

# ============================================
# 6. Optional: Sync to Remote Location
# ============================================
# Uncomment and configure if you want off-site backups

# Using rsync to remote server:
# log "Syncing to remote backup server..."
# rsync -avz --delete "$BACKUP_DIR/" user@backup-server:/backups/ribbonfoldedpeptides/

# Using rclone to cloud storage (Google Drive, S3, etc):
# if command -v rclone &> /dev/null; then
#     log "Syncing to cloud storage..."
#     rclone sync "$BACKUP_DIR" remote:backups/ribbonfoldedpeptides/
# fi

log "=== Backup Complete ==="
echo ""

# ============================================
# Summary Email (if mail is configured)
# ============================================
if command -v mail &> /dev/null && [ -n "$BACKUP_EMAIL" ]; then
    {
        echo "Backup Summary for $(date '+%Y-%m-%d')"
        echo ""
        echo "Database backup: $DB_SIZE"
        echo "Files backup: $FILES_SIZE"
        echo "Total backups: $BACKUP_COUNT"
        echo "Total size: $TOTAL_SIZE"
        echo "Disk free: $DISK_FREE"
    } | mail -s "Backup Report: ribbonfoldedpeptides.com" "$BACKUP_EMAIL"
fi

exit 0
