#!/bin/bash
#
# Install All Monitoring and Maintenance Scripts
# One-command setup for automated monitoring, backups, and security checks
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Install Monitoring & Automation${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Please run as root${NC}"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# ============================================
# 1. Install Scripts
# ============================================
echo -e "${GREEN}[1/4] Installing Scripts...${NC}"

# Service monitor (already installed from previous deployment)
if [ -f "$SCRIPT_DIR/scripts/service-monitor.sh" ]; then
    cp "$SCRIPT_DIR/scripts/service-monitor.sh" /usr/local/bin/service-monitor.sh
    chmod +x /usr/local/bin/service-monitor.sh
    print_status "Service monitor installed"
fi

# Health check (already installed)
if [ -f "$SCRIPT_DIR/scripts/health-check.sh" ]; then
    cp "$SCRIPT_DIR/scripts/health-check.sh" /usr/local/bin/health-check.sh
    chmod +x /usr/local/bin/health-check.sh
    print_status "Health check installed"
fi

# Daily checklist (new)
if [ -f "$SCRIPT_DIR/scripts/daily-checklist.sh" ]; then
    cp "$SCRIPT_DIR/scripts/daily-checklist.sh" /usr/local/bin/daily-checklist.sh
    chmod +x /usr/local/bin/daily-checklist.sh
    print_status "Daily checklist installed"
fi

# Automated backup (new)
if [ -f "$SCRIPT_DIR/scripts/automated-backup.sh" ]; then
    cp "$SCRIPT_DIR/scripts/automated-backup.sh" /usr/local/bin/automated-backup.sh
    chmod +x /usr/local/bin/automated-backup.sh
    print_status "Automated backup installed"
fi

# ============================================
# 2. Setup Cron Jobs
# ============================================
echo ""
echo -e "${GREEN}[2/4] Configuring Cron Jobs...${NC}"

# Remove old entries
crontab -l 2>/dev/null | grep -v "service-monitor.sh" | \
    grep -v "health-check.sh" | \
    grep -v "daily-checklist.sh" | \
    grep -v "automated-backup.sh" | crontab -

# Add new cron jobs
(crontab -l 2>/dev/null; cat << 'EOF'
# Service Monitor - Every minute
*/1 * * * * /usr/local/bin/service-monitor.sh >> /var/log/service-monitor.log 2>&1

# Health Check - Every 5 minutes
*/5 * * * * /usr/local/bin/health-check.sh

# Daily Checklist - Every day at 6 AM
0 6 * * * /usr/local/bin/daily-checklist.sh

# Automated Backup - Every day at 2 AM
0 2 * * * /usr/local/bin/automated-backup.sh
EOF
) | crontab -

print_status "Cron jobs configured"
echo ""
echo "  Scheduled tasks:"
echo "    • Service monitor: Every minute"
echo "    • Health check: Every 5 minutes"
echo "    • Daily checklist: 6:00 AM daily"
echo "    • Automated backup: 2:00 AM daily"

# ============================================
# 3. Create Log Directory
# ============================================
echo ""
echo -e "${GREEN}[3/4] Setting up Logging...${NC}"

# Create log directory if needed
mkdir -p /var/log

# Create log files
touch /var/log/service-monitor.log
touch /var/log/health-check.log
touch /var/log/daily-check.log
touch /var/log/backup.log

# Set permissions
chmod 644 /var/log/service-monitor.log
chmod 644 /var/log/health-check.log
chmod 644 /var/log/daily-check.log
chmod 644 /var/log/backup.log

print_status "Logging configured"

# ============================================
# 4. Create Backup Directory
# ============================================
echo ""
echo -e "${GREEN}[4/4] Setting up Backup Directory...${NC}"

mkdir -p /backup
chmod 700 /backup

BACKUP_SIZE=$(du -sh /backup 2>/dev/null | cut -f1 || echo "0")
print_status "Backup directory ready (/backup - $BACKUP_SIZE)"

# ============================================
# Test Scripts
# ============================================
echo ""
echo -e "${GREEN}Testing Scripts...${NC}"
echo ""

# Run daily checklist once
if [ -f /usr/local/bin/daily-checklist.sh ]; then
    echo "Running daily checklist..."
    /usr/local/bin/daily-checklist.sh
fi

# ============================================
# Summary
# ============================================
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

echo "Installed scripts:"
echo "  /usr/local/bin/service-monitor.sh"
echo "  /usr/local/bin/health-check.sh"
echo "  /usr/local/bin/daily-checklist.sh"
echo "  /usr/local/bin/automated-backup.sh"
echo ""

echo "Log files:"
echo "  /var/log/service-monitor.log"
echo "  /var/log/health-check.log"
echo "  /var/log/daily-check.log"
echo "  /var/log/backup.log"
echo ""

echo "Useful commands:"
echo "  # View service monitor log"
echo "  tail -f /var/log/service-monitor.log"
echo ""
echo "  # Run daily checklist manually"
echo "  /usr/local/bin/daily-checklist.sh"
echo ""
echo "  # Run backup manually"
echo "  /usr/local/bin/automated-backup.sh"
echo ""
echo "  # View cron jobs"
echo "  crontab -l"
echo ""

print_status "Monitoring and automation installed!"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review SECURITY-HARDENING.md for additional security measures"
echo "  2. Setup SSL certificates if not already done"
echo "  3. Configure off-site backups (optional)"
echo "  4. Install WordPress security plugins"
echo ""
