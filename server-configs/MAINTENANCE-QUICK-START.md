# Maintenance & Security Quick Start

**Fast deployment of security and monitoring tools**

---

## 🚀 Quick Install (5 Minutes)

### Option 1: Full Security + Monitoring

```bash
cd /tmp/github-slideshow/server-configs

# Step 1: Install monitoring and automation
chmod +x install-monitoring.sh
./install-monitoring.sh

# Step 2: Harden security
chmod +x scripts/setup-security.sh
./scripts/setup-security.sh
```

**This installs:**
- ✅ Service monitoring (auto-restart)
- ✅ Health checks (memory, disk, SSL)
- ✅ Automated daily backups
- ✅ Daily system check
- ✅ Firewall (UFW)
- ✅ Fail2Ban (brute force protection)
- ✅ Automatic security updates
- ✅ Antivirus (ClamAV)
- ✅ Rootkit detection

**Time:** 5 minutes

---

### Option 2: Just Monitoring (2 Minutes)

```bash
cd /tmp/github-slideshow/server-configs
chmod +x install-monitoring.sh
./install-monitoring.sh
```

**This installs:**
- Service auto-restart
- Health checks
- Automated backups
- Daily checklist

**Time:** 2 minutes

---

## 📋 What Gets Automated

### Every Minute
- **Service Monitor** - Auto-restarts crashed services (NGINX, PHP-FPM, MySQL)

### Every 5 Minutes
- **Health Check** - Monitors memory, site availability, alerts if issues

### Every Day at 6 AM
- **Daily Checklist** - Full system health report

### Every Day at 2 AM
- **Automated Backup** - WordPress files + database backup

---

## 📊 Monitor Your Server

### View Real-Time Logs

```bash
# Service monitor (auto-restart log)
tail -f /var/log/service-monitor.log

# Health checks
tail -f /var/log/health-check.log

# Daily checklist
tail -f /var/log/daily-check.log

# Backup logs
tail -f /var/log/backup.log
```

### Run Manual Checks

```bash
# Quick health check
/usr/local/bin/daily-checklist.sh

# Force backup now
/usr/local/bin/automated-backup.sh

# Test health monitoring
/usr/local/bin/health-check.sh
```

---

## 🔒 Essential Security Tasks

### Fix SSL Certificates (URGENT)

Your SSL certs are broken. Fix this first:

```bash
# Install certbot if needed
apt install certbot python3-certbot-nginx -y

# Get new certificates
certbot --nginx -d ribbonfoldedpeptides.com -d www.ribbonfoldedpeptides.com

# Re-enable HTTPS configs
cd /etc/nginx/conf.d
mv 02_https_ribbonfoldedpeptides.com.conf.disabled 02_https_ribbonfoldedpeptides.com.conf
mv 03_https_www_redirect.conf.disabled 03_https_www_redirect.conf
mv 04_https_apex_site.conf.disabled 04_https_apex_site.conf

# Reload NGINX
nginx -t && systemctl reload nginx
```

---

### Install WordPress Security Plugins

```bash
# Navigate to WordPress
cd /var/www/ribbonfoldedpeptides.com/html

# Install Wordfence (firewall + malware scanner)
wp plugin install wordfence --activate

# Install WP Cerber (brute force protection)
wp plugin install wp-cerber --activate

# Install UpdraftPlus (backups)
wp plugin install updraftplus --activate
```

Then configure in WordPress admin:
- **Wordfence:** Enable firewall + scanning
- **WP Cerber:** Limit login attempts (3 tries, 30min lockout)
- **UpdraftPlus:** Schedule daily backups to Google Drive/Dropbox

---

## 💾 Backup Management

### Manual Backup

```bash
/usr/local/bin/automated-backup.sh
```

### View Backups

```bash
ls -lh /backup/
```

### Restore from Backup

```bash
# List backups
ls -lt /backup/*.gz

# Restore database
gunzip < /backup/ribbonfoldedpeptides_db_YYYYMMDD.sql.gz | mysql -u root -p ribbonfoldedpeptides_db

# Restore files
tar -xzf /backup/ribbonfoldedpeptides_files_YYYYMMDD.tar.gz -C /
```

---

## 🛡️ Security Checklist

### Do Today
- [ ] Fix SSL certificates (see above)
- [ ] Install WordPress security plugins
- [ ] Setup automated backups
- [ ] Enable firewall (UFW)

### Do This Week
- [ ] Change SSH port
- [ ] Setup SSH keys (disable password auth)
- [ ] Review WordPress user accounts
- [ ] Delete unused plugins

### Do Monthly
- [ ] Test backup restoration
- [ ] Review security logs
- [ ] Update all software
- [ ] Check for suspicious files

---

## 📈 Performance Monitoring

### Check Current Status

```bash
# Memory usage
free -h

# Disk usage
df -h

# PHP-FPM processes
ps aux | grep php-fpm | wc -l

# Top memory users
ps aux --sort=-%mem | head -10
```

### Optimize WordPress

```bash
cd /var/www/ribbonfoldedpeptides.com/html

# Clear all transients
wp transient delete --all

# Clear WooCommerce cache
wp wc tool run clear_expired_transients

# Optimize database
wp db optimize

# Regenerate thumbnails
wp media regenerate --yes
```

---

## 🚨 Emergency Commands

### Site Down - Quick Recovery

```bash
# Restart all services
systemctl restart nginx
killall php-fpm && /www/server/php/83/sbin/php-fpm
systemctl restart mariadb

# Check what failed
systemctl status nginx
ps aux | grep php-fpm | wc -l
systemctl status mariadb
```

### Memory Full

```bash
# Check what's using memory
ps aux --sort=-%mem | head -15

# Free up memory
sync && echo 1 > /proc/sys/vm/drop_caches
killall php-fpm && /www/server/php/83/sbin/php-fpm
```

### Disk Full

```bash
# Find large files
du -sh /var/www/* | sort -h
du -sh /var/log/* | sort -h

# Clean logs
find /var/log -name "*.log" -mtime +30 -delete
find /var/log -name "*.gz" -mtime +60 -delete

# Clean WordPress
wp transient delete --all --path=/var/www/ribbonfoldedpeptides.com/html/
```

---

## 📖 Documentation

**Full guides:**
- `SECURITY-HARDENING.md` - Complete security guide
- `BT-PANEL-README.md` - BT Panel specific optimizations
- `DEPLOYMENT.md` - Original deployment guide
- `QUICK-REFERENCE.md` - Common operations

**View documentation:**
```bash
cd /tmp/github-slideshow/server-configs
cat SECURITY-HARDENING.md | less
```

---

## ✅ Verify Installation

After running the install scripts, verify everything:

```bash
# Check cron jobs
crontab -l

# Check scripts installed
ls -la /usr/local/bin/*.sh

# Check logs exist
ls -lh /var/log/*.log

# Check backup directory
ls -lh /backup/

# Test daily checklist
/usr/local/bin/daily-checklist.sh
```

**Expected output:**
- Cron jobs showing all 4 scheduled tasks
- Scripts at /usr/local/bin/
- Log files at /var/log/
- Daily checklist shows all green checkmarks

---

## 🔄 Update Scripts

If scripts are updated in the repository:

```bash
cd /tmp/github-slideshow
git pull
cd server-configs
./install-monitoring.sh  # Re-install updates
```

---

## 🆘 Get Help

**Logs to check when things go wrong:**

```bash
# Service crashes
tail -100 /var/log/service-monitor.log

# Site issues
tail -100 /var/log/nginx/error.log
tail -100 /www/server/php/83/var/log/php-fpm.log

# Database issues
tail -100 /var/log/mysql/error.log

# WordPress errors
tail -100 /var/www/ribbonfoldedpeptides.com/html/wp-content/debug.log
```

**Check service status:**
```bash
systemctl status nginx
systemctl status mariadb
ps aux | grep php-fpm
```

---

## 🎯 Priority Actions

**If you only have 10 minutes:**

1. **Install monitoring** (2 min)
   ```bash
   ./install-monitoring.sh
   ```

2. **Fix SSL certificates** (5 min)
   ```bash
   certbot --nginx -d ribbonfoldedpeptides.com -d www.ribbonfoldedpeptides.com
   ```

3. **Install Wordfence plugin** (3 min)
   ```bash
   wp plugin install wordfence --activate
   ```

**Done!** Your server now has:
- Auto-restart for crashed services
- Daily health checks
- Automated backups
- SSL encryption
- Malware protection

---

**Everything is ready to go. Run the install scripts and your server will be monitored and secured!**
