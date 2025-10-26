#!/bin/bash
#
# Daily Server Health Check
# Quick verification of server health and security
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOGFILE="/var/log/daily-check.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOGFILE"
}

error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOGFILE"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOGFILE"
}

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Daily Server Health Check${NC}"
echo -e "${GREEN}$(date)${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# ============================================
# 1. Memory Usage
# ============================================
echo -e "${GREEN}[1] Memory Status${NC}"
MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
MEM_USED=$(free -m | grep Mem | awk '{print $3}')
MEM_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($MEM_USED/$MEM_TOTAL)*100}")

echo "  Total: ${MEM_TOTAL}MB"
echo "  Used: ${MEM_USED}MB (${MEM_PERCENT}%)"

if [ "$MEM_PERCENT" -gt 80 ]; then
    warn "Memory usage high: ${MEM_PERCENT}%"
elif [ "$MEM_PERCENT" -gt 90 ]; then
    error "CRITICAL: Memory usage at ${MEM_PERCENT}%"
else
    success "Memory usage OK: ${MEM_PERCENT}%"
fi
echo ""

# ============================================
# 2. Disk Usage
# ============================================
echo -e "${GREEN}[2] Disk Status${NC}"
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_FREE=$(df -h / | tail -1 | awk '{print $4}')

echo "  Usage: ${DISK_USAGE}%"
echo "  Free: ${DISK_FREE}"

if [ "$DISK_USAGE" -gt 90 ]; then
    error "CRITICAL: Disk at ${DISK_USAGE}%"
elif [ "$DISK_USAGE" -gt 80 ]; then
    warn "Disk usage high: ${DISK_USAGE}%"
else
    success "Disk usage OK: ${DISK_USAGE}%"
fi
echo ""

# ============================================
# 3. PHP-FPM Status
# ============================================
echo -e "${GREEN}[3] PHP-FPM Status${NC}"
PHP_COUNT=$(ps aux | grep php-fpm | grep -v grep | wc -l)

echo "  Processes: $PHP_COUNT"

if [ "$PHP_COUNT" -gt 15 ]; then
    warn "High PHP-FPM process count: $PHP_COUNT"
elif [ "$PHP_COUNT" -eq 0 ]; then
    error "PHP-FPM NOT RUNNING!"
else
    success "PHP-FPM OK: $PHP_COUNT processes"
fi
echo ""

# ============================================
# 4. Services Status
# ============================================
echo -e "${GREEN}[4] Critical Services${NC}"

# Check NGINX
if ps aux | grep nginx | grep -v grep >/dev/null; then
    success "NGINX running"
else
    error "NGINX NOT RUNNING!"
fi

# Check PHP-FPM
if ps aux | grep php-fpm | grep -v grep >/dev/null; then
    success "PHP-FPM running"
else
    error "PHP-FPM NOT RUNNING!"
fi

# Check MySQL
if ps aux | grep mysql | grep -v grep >/dev/null; then
    success "MySQL running"
else
    error "MySQL NOT RUNNING!"
fi
echo ""

# ============================================
# 5. Website Availability
# ============================================
echo -e "${GREEN}[5] Website Status${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://ribbonfoldedpeptides.com)

if [ "$HTTP_CODE" == "200" ]; then
    success "Site responding: HTTP 200 OK"
else
    error "Site issue: HTTP $HTTP_CODE"
fi
echo ""

# ============================================
# 6. SSL Certificate
# ============================================
echo -e "${GREEN}[6] SSL Certificate${NC}"

if echo | timeout 5 openssl s_client -servername ribbonfoldedpeptides.com -connect ribbonfoldedpeptides.com:443 2>/dev/null | grep -q "Verify return code: 0"; then
    EXPIRY=$(echo | openssl s_client -servername ribbonfoldedpeptides.com -connect ribbonfoldedpeptides.com:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
    DAYS_LEFT=$(( ($(date -d "$EXPIRY" +%s) - $(date +%s)) / 86400 ))

    echo "  Expires: $EXPIRY"
    echo "  Days left: $DAYS_LEFT"

    if [ "$DAYS_LEFT" -lt 7 ]; then
        error "SSL expires in $DAYS_LEFT days!"
    elif [ "$DAYS_LEFT" -lt 30 ]; then
        warn "SSL expires in $DAYS_LEFT days"
    else
        success "SSL OK: $DAYS_LEFT days left"
    fi
else
    warn "SSL certificate check failed (may not be configured)"
fi
echo ""

# ============================================
# 7. Security Checks
# ============================================
echo -e "${GREEN}[7] Security Status${NC}"

# Failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date +%b\ %d)" | wc -l)
echo "  Failed logins today: $FAILED_LOGINS"

if [ "$FAILED_LOGINS" -gt 100 ]; then
    error "Excessive failed logins: $FAILED_LOGINS"
elif [ "$FAILED_LOGINS" -gt 20 ]; then
    warn "High failed login attempts: $FAILED_LOGINS"
else
    success "Login attempts normal: $FAILED_LOGINS"
fi

# Check for system updates
if command -v apt &> /dev/null; then
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    echo "  Available updates: $UPDATES"

    if [ "$UPDATES" -gt 50 ]; then
        warn "Many updates available: $UPDATES"
    fi
fi
echo ""

# ============================================
# 8. Backup Status
# ============================================
echo -e "${GREEN}[8] Backup Status${NC}"

if [ -d "/backup" ]; then
    LATEST_BACKUP=$(ls -t /backup/*.gz 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        BACKUP_AGE=$((($(date +%s) - $(stat -c %Y "$LATEST_BACKUP")) / 86400))
        BACKUP_SIZE=$(du -sh /backup 2>/dev/null | cut -f1)

        echo "  Latest backup: $(basename $LATEST_BACKUP)"
        echo "  Age: $BACKUP_AGE days"
        echo "  Total size: $BACKUP_SIZE"

        if [ "$BACKUP_AGE" -gt 2 ]; then
            warn "Last backup is $BACKUP_AGE days old"
        else
            success "Backups current"
        fi
    else
        warn "No backups found in /backup"
    fi
else
    warn "Backup directory not configured"
fi
echo ""

# ============================================
# Summary
# ============================================
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}================================${NC}"
log "Daily check completed"

# Count issues
ERRORS=$(grep -c "ERROR\|CRITICAL" "$LOGFILE" || echo "0")
WARNINGS=$(grep -c "WARNING" "$LOGFILE" || echo "0")

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}Errors found: $ERRORS${NC}"
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
fi

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}All systems nominal ✓${NC}"
fi

echo ""
