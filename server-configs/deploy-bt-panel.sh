#!/bin/bash
#
# BT Panel / aaPanel Server Optimization Script
# For Ubuntu servers with custom PHP installation at /www/server/
#
# This script optimizes PHP-FPM for 3GB RAM servers
# Does NOT configure swap (containers don't support it)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}BT Panel Server Optimization${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Please run as root${NC}"
    exit 1
fi

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Detect PHP-FPM installation
PHP_FPM_CONF=""
if [ -f /www/server/php/83/etc/php-fpm.conf ]; then
    PHP_FPM_CONF="/www/server/php/83/etc/php-fpm.conf"
    PHP_FPM_BIN="/www/server/php/83/sbin/php-fpm"
elif [ -f /etc/php/8.3/fpm/php-fpm.conf ]; then
    PHP_FPM_CONF="/etc/php/8.3/fpm/pool.d/www.conf"
    PHP_FPM_BIN="php-fpm8.3"
else
    print_error "PHP-FPM not found"
    exit 1
fi

echo -e "${GREEN}[1/4] Optimizing PHP-FPM Configuration...${NC}"
echo "Config file: $PHP_FPM_CONF"

# Backup existing config
cp "$PHP_FPM_CONF" "$PHP_FPM_CONF.backup.$(date +%Y%m%d-%H%M%S)"

# Apply optimizations
sed -i 's/pm = dynamic/pm = ondemand/' "$PHP_FPM_CONF"
sed -i 's/pm.max_children = .*/pm.max_children = 8/' "$PHP_FPM_CONF"
sed -i '/pm.start_servers/d' "$PHP_FPM_CONF"
sed -i '/pm.min_spare_servers/d' "$PHP_FPM_CONF"
sed -i '/pm.max_spare_servers/d' "$PHP_FPM_CONF"

# Add idle timeout if not present
if ! grep -q "pm.process_idle_timeout" "$PHP_FPM_CONF"; then
    echo "pm.process_idle_timeout = 10s" >> "$PHP_FPM_CONF"
fi

print_status "PHP-FPM config optimized"

echo ""
echo -e "${GREEN}[2/4] Restarting PHP-FPM...${NC}"

# Kill all PHP-FPM processes
killall php-fpm 2>/dev/null || true
sleep 2

# Start PHP-FPM
if [ -f "$PHP_FPM_BIN" ]; then
    $PHP_FPM_BIN
else
    systemctl restart php8.3-fpm
fi

sleep 3

print_status "PHP-FPM restarted"

echo ""
echo -e "${GREEN}[3/4] Deploying MySQL Optimization...${NC}"

# Find MySQL config directory
MYSQL_CONF_DIR=""
for dir in /etc/mysql/mariadb.conf.d /etc/mysql/mysql.conf.d /etc/mysql/conf.d /etc/my.cnf.d; do
    if [ -d "$dir" ]; then
        MYSQL_CONF_DIR="$dir"
        break
    fi
done

if [ -z "$MYSQL_CONF_DIR" ]; then
    mkdir -p /etc/mysql/conf.d
    MYSQL_CONF_DIR="/etc/mysql/conf.d"
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "$SCRIPT_DIR/mysql/mysql-optimization.cnf" ]; then
    cp "$SCRIPT_DIR/mysql/mysql-optimization.cnf" "$MYSQL_CONF_DIR/99-optimization.cnf"

    # Restart MySQL
    if systemctl restart mariadb 2>/dev/null || systemctl restart mysql 2>/dev/null; then
        print_status "MySQL optimized and restarted"
    else
        print_warning "MySQL restart failed (may not be needed)"
    fi
else
    print_warning "MySQL config not found, skipping"
fi

echo ""
echo -e "${GREEN}[4/4] Deploying Monitoring...${NC}"

# Deploy service monitor
if [ -f "$SCRIPT_DIR/scripts/service-monitor.sh" ]; then
    cp "$SCRIPT_DIR/scripts/service-monitor.sh" /usr/local/bin/service-monitor-bt.sh
    chmod +x /usr/local/bin/service-monitor-bt.sh

    # Create cron job instead of systemd (more compatible)
    CRON_MONITOR="*/1 * * * * /usr/local/bin/service-monitor-bt.sh >> /var/log/service-monitor.log 2>&1"
    (crontab -l 2>/dev/null | grep -v "service-monitor-bt.sh"; echo "$CRON_MONITOR") | crontab -

    print_status "Service monitor deployed (runs every minute via cron)"
fi

# Deploy health check
if [ -f "$SCRIPT_DIR/scripts/health-check.sh" ]; then
    cp "$SCRIPT_DIR/scripts/health-check.sh" /usr/local/bin/health-check.sh
    chmod +x /usr/local/bin/health-check.sh

    CRON_HEALTH="*/5 * * * * /usr/local/bin/health-check.sh"
    (crontab -l 2>/dev/null | grep -v "health-check.sh"; echo "$CRON_HEALTH") | crontab -

    print_status "Health check deployed (runs every 5 minutes)"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Optimization Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

echo "Memory Usage:"
free -h
echo ""

echo "PHP-FPM Processes:"
ps aux | grep php-fpm | grep -v grep | wc -l | xargs echo "Count:"
echo ""

echo "Services:"
ps aux | grep nginx | grep -v grep >/dev/null && echo "  ✓ NGINX running" || echo "  ✗ NGINX stopped"
ps aux | grep php-fpm | grep -v grep >/dev/null && echo "  ✓ PHP-FPM running" || echo "  ✗ PHP-FPM stopped"
ps aux | grep mysql | grep -v grep >/dev/null && echo "  ✓ MySQL running" || echo "  ✗ MySQL stopped"
echo ""

print_status "Server optimized successfully!"
echo ""
echo "Monitor logs:"
echo "  tail -f /var/log/service-monitor.log"
echo "  tail -f /var/log/health-check.log"
