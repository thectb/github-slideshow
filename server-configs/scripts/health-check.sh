#!/bin/bash
#
# Health Check and Alert Script
# Tests site availability, checks memory, and sends alerts
#
# DEPLOYMENT:
#   1. Copy to /usr/local/bin/health-check.sh
#   2. chmod +x /usr/local/bin/health-check.sh
#   3. Add to crontab: */5 * * * * /usr/local/bin/health-check.sh
#
# CONFIGURATION:
#   - Set SITE_URL to your website
#   - Set ALERT_EMAIL if you want email alerts

SITE_URL="http://ribbonfoldedpeptides.com"
ALERT_EMAIL=""  # Leave empty to disable email, or set to your email
LOGFILE="/var/log/health-check.log"
ALERT_FILE="/tmp/health-alert-sent"
MEMORY_THRESHOLD=80  # Alert if memory usage exceeds this percentage

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Function to send alert (only once per issue)
send_alert() {
    local subject="$1"
    local message="$2"

    log_message "ALERT: $subject"

    # Only send one alert until issue is resolved
    if [ ! -f "$ALERT_FILE" ]; then
        touch "$ALERT_FILE"

        if [ -n "$ALERT_EMAIL" ] && command -v mail &> /dev/null; then
            echo "$message" | mail -s "$subject - $(hostname)" "$ALERT_EMAIL"
        fi
    fi
}

# Function to clear alert status
clear_alert() {
    rm -f "$ALERT_FILE"
}

# === CHECK 1: SITE AVAILABILITY ===
log_message "Checking site availability: $SITE_URL"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$SITE_URL")

if [ "$HTTP_CODE" != "200" ]; then
    send_alert "Site Down" "Site $SITE_URL returned HTTP $HTTP_CODE at $(date)"
    log_message "ERROR: Site returned HTTP $HTTP_CODE"
else
    log_message "OK: Site is accessible (HTTP 200)"
    clear_alert
fi

# === CHECK 2: MEMORY USAGE ===
log_message "Checking memory usage..."

MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
MEM_USED=$(free -m | grep Mem | awk '{print $3}')
MEM_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($MEM_USED/$MEM_TOTAL)*100}")

log_message "Memory: ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PERCENT}%)"

if [ "$MEM_PERCENT" -gt "$MEMORY_THRESHOLD" ]; then
    # Get top memory consumers
    TOP_PROCS=$(ps aux --sort=-%mem | head -6 | tail -5 | awk '{print $11, $4"%"}' | tr '\n' '; ')

    send_alert "High Memory Usage" \
        "Memory usage is at ${MEM_PERCENT}% (${MEM_USED}MB / ${MEM_TOTAL}MB)\n\nTop processes: $TOP_PROCS\n\nServer: $(hostname)\nTime: $(date)"

    log_message "WARNING: Memory usage above threshold (${MEM_PERCENT}% > ${MEMORY_THRESHOLD}%)"
else
    log_message "OK: Memory usage within limits"
fi

# === CHECK 3: SWAP USAGE ===
SWAP_TOTAL=$(free -m | grep Swap | awk '{print $2}')
SWAP_USED=$(free -m | grep Swap | awk '{print $3}')

if [ "$SWAP_TOTAL" -eq 0 ]; then
    log_message "WARNING: No swap space configured"
elif [ "$SWAP_USED" -gt 100 ]; then
    log_message "WARNING: Swap usage is high: ${SWAP_USED}MB / ${SWAP_TOTAL}MB"
else
    log_message "OK: Swap usage normal (${SWAP_USED}MB / ${SWAP_TOTAL}MB)"
fi

# === CHECK 4: DISK USAGE ===
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

log_message "Disk usage: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -gt 90 ]; then
    log_message "WARNING: Disk usage is above 90%"
fi

# === CHECK 5: SERVICE STATUS ===
for service in nginx php8.3-fpm mariadb; do
    if systemctl is-active --quiet "$service"; then
        log_message "OK: $service is running"
    else
        log_message "ERROR: $service is NOT running"
    fi
done

# === SUMMARY ===
log_message "Health check completed"
echo "---" >> "$LOGFILE"
