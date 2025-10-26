#!/bin/bash
#
# All-in-One Server Optimization Deployment Script
# Deploys all configurations and monitoring tools
#
# Usage: ./deploy-all.sh

set -e  # Exit on error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Server Optimization Deployment${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Please run as root${NC}"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Confirmation
echo -e "${YELLOW}This will:${NC}"
echo "  1. Add 4GB swap space"
echo "  2. Deploy PHP-FPM optimization"
echo "  3. Deploy MySQL optimization"
echo "  4. Deploy service monitoring"
echo "  5. Deploy health check"
echo "  6. Deploy log rotation"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo -e "${GREEN}Starting deployment...${NC}"
echo ""

# ============================================
# STEP 1: Add Swap Space
# ============================================
echo -e "${GREEN}[1/6] Configuring Swap Space...${NC}"

if [ -f /swapfile ]; then
    print_warning "Swap file already exists, skipping"
else
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    # Add to fstab if not already there
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    print_status "Swap space configured (4GB)"
fi

# ============================================
# STEP 2: Deploy PHP-FPM Configuration
# ============================================
echo -e "${GREEN}[2/6] Deploying PHP-FPM Configuration...${NC}"

# Backup existing config
if [ -f /etc/php/8.3/fpm/pool.d/www.conf ]; then
    cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.backup.$(date +%Y%m%d-%H%M%S)
fi

# Deploy new config
cp php/www.conf /etc/php/8.3/fpm/pool.d/www.conf

# Test and restart
if php-fpm8.3 -t 2>&1 | grep -q "test is successful"; then
    systemctl restart php8.3-fpm
    print_status "PHP-FPM configuration deployed and restarted"
else
    print_error "PHP-FPM configuration test failed"
    exit 1
fi

# ============================================
# STEP 3: Deploy MySQL Optimization
# ============================================
echo -e "${GREEN}[3/6] Deploying MySQL Optimization...${NC}"

# Backup existing config
if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ]; then
    cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.backup.$(date +%Y%m%d-%H%M%S)
fi

# Deploy new config
cp mysql/mysql-optimization.cnf /etc/mysql/mariadb.conf.d/99-optimization.cnf

# Create log directory if it doesn't exist
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql

# Restart MySQL
systemctl restart mariadb
print_status "MySQL optimization deployed and restarted"

# ============================================
# STEP 4: Deploy Service Monitor
# ============================================
echo -e "${GREEN}[4/6] Deploying Service Monitor...${NC}"

# Deploy script
cp scripts/service-monitor.sh /usr/local/bin/service-monitor.sh
chmod +x /usr/local/bin/service-monitor.sh

# Deploy systemd service
cp systemd/service-monitor.service /etc/systemd/system/service-monitor.service

# Enable and start
systemctl daemon-reload
systemctl enable service-monitor.service
systemctl restart service-monitor.service

print_status "Service monitor deployed and running"

# ============================================
# STEP 5: Deploy Health Check
# ============================================
echo -e "${GREEN}[5/6] Deploying Health Check...${NC}"

# Deploy script
cp scripts/health-check.sh /usr/local/bin/health-check.sh
chmod +x /usr/local/bin/health-check.sh

# Add to crontab
CRON_JOB="*/5 * * * * /usr/local/bin/health-check.sh"
(crontab -l 2>/dev/null | grep -v "health-check.sh"; echo "$CRON_JOB") | crontab -

print_status "Health check deployed (runs every 5 minutes)"

# ============================================
# STEP 6: Deploy Log Rotation
# ============================================
echo -e "${GREEN}[6/6] Deploying Log Rotation...${NC}"

cp logrotate/server-logs /etc/logrotate.d/server-logs

# Test logrotate config
if logrotate -d /etc/logrotate.d/server-logs >/dev/null 2>&1; then
    print_status "Log rotation configured"
else
    print_warning "Logrotate configuration has warnings (check manually)"
fi

# ============================================
# Deployment Complete
# ============================================
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Show current status
echo -e "${GREEN}Current System Status:${NC}"
echo ""

echo "Memory Usage:"
free -h
echo ""

echo "Swap Usage:"
swapon --show
echo ""

echo "PHP-FPM Processes:"
ps aux | grep php-fpm | grep -v grep | wc -l | xargs echo "Count:"
echo ""

echo "Service Status:"
systemctl is-active nginx && echo "  ✓ NGINX running" || echo "  ✗ NGINX stopped"
systemctl is-active php8.3-fpm && echo "  ✓ PHP-FPM running" || echo "  ✗ PHP-FPM stopped"
systemctl is-active mariadb && echo "  ✓ MySQL running" || echo "  ✗ MySQL stopped"
systemctl is-active service-monitor && echo "  ✓ Monitor running" || echo "  ✗ Monitor stopped"
echo ""

echo -e "${GREEN}Monitoring Logs:${NC}"
echo "  Service Monitor: tail -f /var/log/service-monitor.log"
echo "  Health Check:    tail -f /var/log/health-check.log"
echo ""

echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Monitor memory usage: watch -n 5 free -h"
echo "  2. Check service logs: tail -f /var/log/service-monitor.log"
echo "  3. Test site: curl -I http://ribbonfoldedpeptides.com"
echo ""

print_status "All optimizations deployed successfully!"
