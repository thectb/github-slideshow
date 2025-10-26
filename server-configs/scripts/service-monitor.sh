#!/bin/bash
#
# Service Monitor and Auto-Restart Script
# Monitors critical services and automatically restarts them if down
#
# DEPLOYMENT:
#   1. Copy to /usr/local/bin/service-monitor.sh
#   2. chmod +x /usr/local/bin/service-monitor.sh
#   3. Copy service-monitor.service to /etc/systemd/system/
#   4. systemctl daemon-reload
#   5. systemctl enable service-monitor.service
#   6. systemctl start service-monitor.service

LOGFILE="/var/log/service-monitor.log"
SERVICES=("nginx" "php8.3-fpm" "mariadb")

# Create log file if it doesn't exist
touch "$LOGFILE"

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Function to check and restart service
check_service() {
    local service=$1

    if ! systemctl is-active --quiet "$service"; then
        log_message "ALERT: $service is DOWN. Attempting restart..."

        # Try to restart the service
        if systemctl restart "$service"; then
            log_message "SUCCESS: $service restarted successfully"

            # Send email notification if mail is configured
            if command -v mail &> /dev/null; then
                echo "$service was down and has been restarted on $(hostname) at $(date)" | \
                    mail -s "Service Restart Alert: $service on $(hostname)" root
            fi
        else
            log_message "ERROR: Failed to restart $service"

            # Send critical alert
            if command -v mail &> /dev/null; then
                echo "CRITICAL: $service failed to restart on $(hostname) at $(date)" | \
                    mail -s "CRITICAL: $service restart failed on $(hostname)" root
            fi
        fi
    fi
}

# Function to check memory usage and log warning
check_memory() {
    local mem_used=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')

    if [ "$mem_used" -gt 80 ]; then
        log_message "WARNING: Memory usage is at ${mem_used}%"

        # Log top memory consumers
        log_message "Top memory consumers:"
        ps aux --sort=-%mem | head -6 | tail -5 >> "$LOGFILE"
    fi
}

# Main monitoring loop
log_message "Service monitor started"

while true; do
    # Check each service
    for service in "${SERVICES[@]}"; do
        check_service "$service"
    done

    # Check memory usage every cycle
    check_memory

    # Wait 60 seconds before next check
    sleep 60
done
