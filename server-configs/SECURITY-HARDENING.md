# Server Security & Maintenance Guide

**For: ribbonfoldedpeptides.com on Ubuntu 24.04 + BT Panel**

---

## 🔒 IMMEDIATE SECURITY ACTIONS

### 1. Fix SSL Certificates (URGENT)

Your SSL certificates are broken. Fix this NOW:

```bash
# Check certbot is installed
certbot --version

# Renew certificates
certbot renew --force-renewal

# Or if first time setup:
certbot --nginx -d ribbonfoldedpeptides.com -d www.ribbonfoldedpeptides.com

# Re-enable HTTPS configs
cd /etc/nginx/conf.d
mv 02_https_ribbonfoldedpeptides.com.conf.disabled 02_https_ribbonfoldedpeptides.com.conf
mv 03_https_www_redirect.conf.disabled 03_https_www_redirect.conf
mv 04_https_apex_site.conf.disabled 04_https_apex_site.conf

# Test and reload
nginx -t && systemctl reload nginx
```

**Why critical:** Without HTTPS, passwords/credit cards are sent in plain text!

---

### 2. Secure SSH Access

```bash
# Change SSH port from 22 to something else
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# Disable root login with password (use keys only)
sed -i 's/#PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Disable password authentication (keys only)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH
systemctl restart sshd
```

**IMPORTANT:** Make sure you have SSH keys set up BEFORE disabling password auth!

---

### 3. Setup Firewall (UFW)

```bash
# Install UFW if not present
apt update && apt install ufw -y

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (use YOUR port if you changed it)
ufw allow 22/tcp
# Or if you changed to 2222:
# ufw allow 2222/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow MySQL only from localhost (not from internet!)
# (already default with deny incoming)

# Enable firewall
ufw enable

# Check status
ufw status verbose
```

---

### 4. Secure WordPress (Critical for WooCommerce!)

```bash
# Secure wp-config.php
chmod 600 /var/www/ribbonfoldedpeptides.com/html/wp-config.php

# Protect .htaccess
chmod 644 /var/www/ribbonfoldedpeptides.com/html/.htaccess

# Disable file editing in WordPress admin
cat >> /var/www/ribbonfoldedpeptides.com/html/wp-config.php << 'EOF'

// Disable file editor
define('DISALLOW_FILE_EDIT', true);
EOF

# Set correct ownership
chown -R www:www /var/www/ribbonfoldedpeptides.com/html/

# Secure permissions
find /var/www/ribbonfoldedpeptides.com/html/ -type d -exec chmod 755 {} \;
find /var/www/ribbonfoldedpeptides.com/html/ -type f -exec chmod 644 {} \;
```

---

### 5. Install Security Plugins (WordPress)

**Required plugins:**

1. **Wordfence Security** - Firewall + Malware scanning
   ```
   wp plugin install wordfence --activate
   ```

2. **WP Cerber Security** - Brute force protection
   ```
   wp plugin install wp-cerber --activate
   ```

3. **WooCommerce Anti-Fraud** - For WooCommerce protection
   ```
   wp plugin install woocommerce-anti-fraud --activate
   ```

4. **UpdraftPlus** - Automatic backups
   ```
   wp plugin install updraftplus --activate
   ```

**Configure in WordPress admin:**
- Enable 2FA for admin accounts
- Limit login attempts (3 tries, 30min lockout)
- Enable malware scanning
- Schedule automatic backups (daily)

---

## 🛡️ AUTOMATED SECURITY MONITORING

### Daily Security Check Script

Create `/usr/local/bin/daily-security-check.sh`:

```bash
#!/bin/bash
# Daily Security Audit

LOGFILE="/var/log/security-audit.log"
ALERT_EMAIL=""  # Set your email

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

log "=== Daily Security Audit ==="

# Check for failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
if [ "$FAILED_LOGINS" -gt 50 ]; then
    log "WARNING: $FAILED_LOGINS failed login attempts detected"
fi

# Check for suspicious WordPress logins
if [ -f /var/www/*/html/wp-content/debug.log ]; then
    FAILED_WP=$(grep -i "authentication" /var/www/*/html/wp-content/debug.log 2>/dev/null | wc -l)
    log "WordPress auth attempts: $FAILED_WP"
fi

# Check for modified system files
if [ -f /var/log/aide.log ]; then
    if grep -q "changed" /var/log/aide.log; then
        log "ALERT: System files modified!"
    fi
fi

# Check disk usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    log "WARNING: Disk usage at ${DISK_USAGE}%"
fi

# Check for outdated packages
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
log "Available updates: $UPDATES"

# Check SSL expiry
DAYS_LEFT=$(echo | openssl s_client -servername ribbonfoldedpeptides.com -connect ribbonfoldedpeptides.com:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2 | xargs -I {} date -d {} +%s)
CURRENT=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($DAYS_LEFT - $CURRENT) / 86400 ))

if [ "$DAYS_UNTIL_EXPIRY" -lt 30 ]; then
    log "WARNING: SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
fi

# Check for rootkits (if rkhunter installed)
if command -v rkhunter >/dev/null; then
    rkhunter --check --skip-keypress --report-warnings-only >> "$LOGFILE" 2>&1
fi

log "Security audit complete"
```

Install it:

```bash
chmod +x /usr/local/bin/daily-security-check.sh
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/daily-security-check.sh") | crontab -
```

---

## 📊 PERFORMANCE MONITORING

### Install Monitoring Tools

```bash
# Install htop for interactive monitoring
apt install htop -y

# Install iotop for disk I/O monitoring
apt install iotop -y

# Install nethogs for network monitoring
apt install nethogs -y
```

### Monitor WordPress Performance

```bash
# Install Query Monitor plugin
wp plugin install query-monitor --activate

# Enable WordPress debug logging (for errors only)
cat >> /var/www/ribbonfoldedpeptides.com/html/wp-config.php << 'EOF'

// Debug logging
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
@ini_set('display_errors', 0);
EOF
```

### Check Slow Queries

```bash
# Monitor MySQL slow queries
tail -f /var/log/mysql/slow-query.log

# Check PHP-FPM slow requests
tail -f /www/server/php/83/var/log/slow.log
```

---

## 🔄 AUTOMATED MAINTENANCE

### Weekly Maintenance Script

Create `/usr/local/bin/weekly-maintenance.sh`:

```bash
#!/bin/bash
# Weekly Server Maintenance

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/weekly-maintenance.log
}

log "=== Weekly Maintenance Starting ==="

# Update system packages
log "Updating system packages..."
apt update && apt upgrade -y

# Clean old kernels
log "Cleaning old kernels..."
apt autoremove -y

# Clean package cache
log "Cleaning package cache..."
apt clean

# Optimize MySQL database
log "Optimizing MySQL databases..."
mysqlcheck -u root -p --optimize --all-databases

# Clean WordPress transients
log "Cleaning WordPress transients..."
wp transient delete --all --path=/var/www/ribbonfoldedpeptides.com/html/

# Regenerate WordPress thumbnails if needed
log "Checking WordPress media..."
wp media regenerate --yes --path=/var/www/ribbonfoldedpeptides.com/html/

# Clear WooCommerce sessions
log "Clearing old WooCommerce sessions..."
wp wc tool run clear_expired_transients --path=/var/www/ribbonfoldedpeptides.com/html/

# Clean log files older than 30 days
log "Cleaning old log files..."
find /var/log -name "*.log" -type f -mtime +30 -delete
find /var/log -name "*.gz" -type f -mtime +60 -delete

# Restart PHP-FPM to clear memory
log "Restarting PHP-FPM..."
killall php-fpm
sleep 2
/www/server/php/83/sbin/php-fpm

log "=== Maintenance Complete ==="
log "Memory usage: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
log "Disk usage: $(df -h / | tail -1 | awk '{print $5}')"
```

Install it:

```bash
chmod +x /usr/local/bin/weekly-maintenance.sh
(crontab -l 2>/dev/null; echo "0 3 * * 0 /usr/local/bin/weekly-maintenance.sh") | crontab -
```

Runs every Sunday at 3 AM.

---

## 💾 BACKUP STRATEGY

### Automated Backups

```bash
#!/bin/bash
# Daily Backup Script
# Location: /usr/local/bin/daily-backup.sh

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d)
SITE_PATH="/var/www/ribbonfoldedpeptides.com/html"
DB_NAME="ribbonfoldedpeptides_db"  # Change to your DB name
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR"

# Backup database
mysqldump -u root -p"$DB_PASSWORD" "$DB_NAME" | gzip > "$BACKUP_DIR/db-$DATE.sql.gz"

# Backup WordPress files
tar -czf "$BACKUP_DIR/files-$DATE.tar.gz" "$SITE_PATH"

# Delete old backups
find "$BACKUP_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete

# Sync to remote location (optional - setup rsync or rclone)
# rclone copy "$BACKUP_DIR" remote:backups/

echo "[$(date)] Backup completed" >> /var/log/backup.log
```

**Better option:** Use UpdraftPlus WordPress plugin to backup to:
- Google Drive
- Dropbox
- Amazon S3
- Backblaze B2

Configure in WordPress admin: **Settings → UpdraftPlus Backups**

---

## 🔐 HARDENING CHECKLIST

### MySQL Security

```bash
# Run MySQL secure installation
mysql_secure_installation

# Create separate database user (don't use root!)
mysql -u root -p << EOF
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'strong_password_here';
GRANT ALL PRIVILEGES ON ribbonfoldedpeptides_db.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# Update wp-config.php with new user
nano /var/www/ribbonfoldedpeptides.com/html/wp-config.php
```

### PHP Security

Add to `/www/server/php/83/etc/php.ini`:

```ini
; Disable dangerous functions
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source

; Hide PHP version
expose_php = Off

; Session security
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1
```

Restart PHP-FPM after changes.

### NGINX Security Headers

Add to your NGINX config `/etc/nginx/conf.d/security-headers.conf`:

```nginx
# Security Headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

# Hide NGINX version
server_tokens off;
```

Reload NGINX:
```bash
nginx -t && nginx -s reload
```

---

## 📈 MONITORING DASHBOARD

### Install Netdata (Real-time Monitoring)

```bash
# Install Netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --stable-channel --disable-telemetry

# Access at: http://your-ip:19999
# Secure it with firewall or reverse proxy
```

### WordPress Monitoring

Install **Health Check & Troubleshooting** plugin:

```bash
wp plugin install health-check --activate
```

Check site health: **Tools → Site Health**

---

## 🚨 INCIDENT RESPONSE

### If Site Gets Hacked

1. **Take site offline immediately:**
   ```bash
   systemctl stop nginx
   ```

2. **Backup current state (for forensics):**
   ```bash
   tar -czf /backup/compromised-$(date +%Y%m%d).tar.gz /var/www/ribbonfoldedpeptides.com/
   ```

3. **Scan for malware:**
   ```bash
   # Install ClamAV
   apt install clamav clamav-daemon -y
   freshclam

   # Scan website
   clamscan -r /var/www/ribbonfoldedpeptides.com/html/ --infected --remove
   ```

4. **Restore from clean backup:**
   ```bash
   # Restore files
   tar -xzf /backup/files-CLEANDATE.tar.gz -C /

   # Restore database
   mysql -u root -p ribbonfoldedpeptides_db < /backup/db-CLEANDATE.sql
   ```

5. **Reset all passwords:**
   - WordPress admin passwords
   - Database passwords
   - FTP/SSH passwords
   - SSL certificates

6. **Review logs:**
   ```bash
   grep "POST" /var/log/nginx/access.log | tail -1000
   tail -500 /var/www/ribbonfoldedpeptides.com/html/wp-content/debug.log
   ```

---

## 📋 DAILY CHECKLIST

Copy this to `/usr/local/bin/daily-checklist.sh`:

```bash
#!/bin/bash
echo "=== Daily Server Health Check ==="
echo ""
echo "Memory Usage:"
free -h | grep Mem
echo ""
echo "Disk Usage:"
df -h / | tail -1
echo ""
echo "PHP-FPM Processes:"
ps aux | grep php-fpm | wc -l
echo ""
echo "Services Status:"
systemctl is-active nginx && echo "✓ NGINX" || echo "✗ NGINX FAILED"
systemctl is-active mariadb && echo "✓ MySQL" || echo "✗ MySQL FAILED"
ps aux | grep php-fpm | grep -v grep >/dev/null && echo "✓ PHP-FPM" || echo "✗ PHP-FPM FAILED"
echo ""
echo "SSL Certificate Expiry:"
echo | openssl s_client -servername ribbonfoldedpeptides.com -connect ribbonfoldedpeptides.com:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter
echo ""
echo "Failed Login Attempts (last 24h):"
grep "Failed password" /var/log/auth.log | grep "$(date +%b\ %d)" | wc -l
echo ""
echo "Site Response:"
curl -sI http://ribbonfoldedpeptides.com | head -1
```

Run daily:
```bash
chmod +x /usr/local/bin/daily-checklist.sh
/usr/local/bin/daily-checklist.sh
```

---

## 🎯 PRIORITIES

**Do TODAY:**
1. ✅ Fix SSL certificates (you're sending data unencrypted!)
2. ✅ Setup firewall (UFW)
3. ✅ Install Wordfence plugin
4. ✅ Enable automatic WordPress backups

**Do THIS WEEK:**
1. Secure SSH (change port, disable passwords)
2. Setup automated backups
3. Install security monitoring
4. Review WordPress user accounts (delete unused)

**Do THIS MONTH:**
1. Full security audit
2. Review all installed plugins (delete unused)
3. Test disaster recovery (restore from backup)
4. Document your infrastructure

---

## 📚 USEFUL COMMANDS

```bash
# Check all listening ports
netstat -tulpn

# See what's using disk space
du -sh /var/www/* | sort -h

# Check for large files
find / -type f -size +100M 2>/dev/null

# Monitor in real-time
htop
iotop
nethogs

# Check recent logins
last -n 20

# Check cron jobs
crontab -l

# See systemd logs
journalctl -xe

# Monitor web traffic
tail -f /var/log/nginx/access.log
```

---

## 🆘 EMERGENCY CONTACTS

**When things go wrong:**

1. **BT Panel Support:** https://forum.aapanel.com/
2. **WordPress Support:** https://wordpress.org/support/
3. **WooCommerce Support:** https://woocommerce.com/support/

**Server provider support:** Contact your hosting company

---

## ✅ MONTHLY REVIEW

Run this checklist every month:

- [ ] Review security audit logs
- [ ] Test backup restoration
- [ ] Update all software (OS, WordPress, plugins)
- [ ] Review user access (remove old accounts)
- [ ] Check SSL certificate expiry (>30 days left?)
- [ ] Review disk usage (any large files?)
- [ ] Check for suspicious files in uploads/
- [ ] Review payment gateway logs (WooCommerce)
- [ ] Test site speed (should load <3 seconds)
- [ ] Review error logs for issues

---

**Keep your server secure, monitored, and backed up!**
