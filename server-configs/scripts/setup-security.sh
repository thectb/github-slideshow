#!/bin/bash
#
# Automated Security Hardening Script
# Sets up firewall, secures SSH, and configures basic security
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Security Hardening Setup${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check root
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

# ============================================
# 1. Setup UFW Firewall
# ============================================
echo -e "${GREEN}[1/5] Setting up Firewall (UFW)...${NC}"

if ! command -v ufw &> /dev/null; then
    apt update && apt install ufw -y
fi

# Configure firewall
ufw --force default deny incoming
ufw --force default allow outgoing

# Allow SSH (current port)
SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
ufw allow ${SSH_PORT}/tcp

# Allow web traffic
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw --force enable

print_status "Firewall configured and enabled"

# ============================================
# 2. Secure SSH Configuration
# ============================================
echo ""
echo -e "${GREEN}[2/5] Securing SSH...${NC}"

# Backup SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Disable root password login (keep key-based auth)
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Disable empty passwords
sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# Set login grace time
sed -i 's/^#*LoginGraceTime.*/LoginGraceTime 30/' /etc/ssh/sshd_config

# Max auth tries
sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config

print_warning "SSH hardened - ensure you have SSH keys configured before rebooting!"

# ============================================
# 3. Install Fail2Ban
# ============================================
echo ""
echo -e "${GREEN}[3/5] Installing Fail2Ban...${NC}"

if ! command -v fail2ban-client &> /dev/null; then
    apt install fail2ban -y
fi

# Configure fail2ban for SSH
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
EOF

systemctl enable fail2ban
systemctl restart fail2ban

print_status "Fail2Ban installed and configured"

# ============================================
# 4. Install Security Tools
# ============================================
echo ""
echo -e "${GREEN}[4/5] Installing Security Tools...${NC}"

apt install -y \
    unattended-upgrades \
    apt-listchanges \
    rkhunter \
    clamav \
    clamav-daemon

# Configure automatic security updates
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# Enable automatic updates
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

print_status "Security tools installed"

# ============================================
# 5. Secure File Permissions
# ============================================
echo ""
echo -e "${GREEN}[5/5] Securing File Permissions...${NC}"

# Find WordPress installations and secure them
for wp_dir in /var/www/*/html; do
    if [ -f "$wp_dir/wp-config.php" ]; then
        echo "Securing $wp_dir"

        # Set ownership
        chown -R www:www "$wp_dir"

        # Set directory permissions
        find "$wp_dir" -type d -exec chmod 755 {} \;

        # Set file permissions
        find "$wp_dir" -type f -exec chmod 644 {} \;

        # Secure wp-config.php
        chmod 600 "$wp_dir/wp-config.php"

        print_status "Secured WordPress at $wp_dir"
    fi
done

# ============================================
# Summary
# ============================================
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Security Hardening Complete${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

echo "What was configured:"
echo "  ✓ UFW Firewall (ports 22, 80, 443)"
echo "  ✓ SSH hardening (no root password, 3 max tries)"
echo "  ✓ Fail2Ban (auto-ban brute force)"
echo "  ✓ Automatic security updates"
echo "  ✓ Rootkit detection (rkhunter)"
echo "  ✓ Antivirus (ClamAV)"
echo "  ✓ WordPress file permissions"
echo ""

echo -e "${YELLOW}IMPORTANT:${NC}"
echo "  1. Ensure you have SSH keys configured before rebooting"
echo "  2. SSH configuration will take effect after: systemctl restart sshd"
echo "  3. Check firewall rules: ufw status"
echo "  4. Check fail2ban: fail2ban-client status"
echo ""

echo -e "${GREEN}Next steps:${NC}"
echo "  1. Setup SSL certificates: certbot --nginx"
echo "  2. Install WordPress security plugins (Wordfence)"
echo "  3. Configure backups (see SECURITY-HARDENING.md)"
echo "  4. Review the full security guide"
echo ""

print_status "Security hardening complete!"
