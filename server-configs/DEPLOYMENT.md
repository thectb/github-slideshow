# Server Optimization Deployment Guide

**Server:** is-web-01 (80.78.18.98)
**OS:** Ubuntu 24.04 LTS
**RAM:** 3GB
**Stack:** NGINX + PHP 8.3-FPM + MariaDB
**Site:** ribbonfoldedpeptides.com

---

## Quick Deploy (All-in-One)

SSH to your server and run:

```bash
cd /tmp
git clone https://github.com/thectb/github-slideshow.git
cd github-slideshow/server-configs
chmod +x deploy-all.sh
./deploy-all.sh
```

---

## Manual Deployment

### STEP 1: Add Swap Space (CRITICAL - Do This First!)

```bash
# Create 4GB swap file
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Verify swap is active
free -h
swapon --show
```

**Expected Output:**
```
Swap:          4.0Gi          0B       4.0Gi
```

---

### STEP 2: Deploy PHP-FPM Configuration

```bash
# Backup existing config
cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.backup

# Deploy optimized config
cp php/www.conf /etc/php/8.3/fpm/pool.d/www.conf

# Verify configuration
php-fpm8.3 -t

# Restart PHP-FPM
systemctl restart php8.3-fpm

# Check status
systemctl status php8.3-fpm

# Verify process count (should be low, spawns on demand)
ps aux | grep php-fpm | wc -l
```

**Expected:** 1-3 PHP-FPM processes when idle

---

### STEP 3: Deploy MySQL Optimization

```bash
# Backup existing config
cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.backup

# Deploy optimized config
cp mysql/mysql-optimization.cnf /etc/mysql/mariadb.conf.d/99-optimization.cnf

# Test configuration
mysqld --help --verbose 2>&1 | grep -A 1 'innodb-buffer-pool-size'

# Restart MySQL
systemctl restart mariadb

# Check status and memory usage
systemctl status mariadb
ps aux --sort=-%mem | grep mysql
```

**Expected:** MySQL using ~200-300MB RAM

---

### STEP 4: Deploy Service Monitor

```bash
# Deploy monitoring script
cp scripts/service-monitor.sh /usr/local/bin/service-monitor.sh
chmod +x /usr/local/bin/service-monitor.sh

# Deploy systemd service
cp systemd/service-monitor.service /etc/systemd/system/service-monitor.service

# Enable and start service
systemctl daemon-reload
systemctl enable service-monitor.service
systemctl start service-monitor.service

# Check status
systemctl status service-monitor.service

# View monitoring logs
tail -f /var/log/service-monitor.log
```

**Monitoring runs every 60 seconds and auto-restarts failed services**

---

### STEP 5: Deploy Health Check

```bash
# Deploy health check script
cp scripts/health-check.sh /usr/local/bin/health-check.sh
chmod +x /usr/local/bin/health-check.sh

# Add to crontab (runs every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/health-check.sh") | crontab -

# Test run
/usr/local/bin/health-check.sh

# View logs
tail -f /var/log/health-check.log
```

---

### STEP 6: Deploy Log Rotation

```bash
# Deploy logrotate config
cp logrotate/server-logs /etc/logrotate.d/server-logs

# Test configuration
logrotate -d /etc/logrotate.d/server-logs

# Force a rotation test
logrotate -f /etc/logrotate.d/server-logs

# Verify
ls -lh /var/log/ | grep -E "php|nginx|mysql"
```

---

## Verification Commands

### Check Memory Usage

```bash
# Current memory state
free -h

# Top memory consumers
ps aux --sort=-%mem | head -15

# PHP-FPM process count and memory
ps aux | grep php-fpm | wc -l
ps aux | grep php-fpm --no-heading | awk '{sum+=$6} END {print sum/1024 " MB"}'
```

### Check Service Status

```bash
systemctl status nginx php8.3-fpm mariadb service-monitor
```

### Check Logs

```bash
# Service monitor
tail -50 /var/log/service-monitor.log

# Health check
tail -50 /var/log/health-check.log

# PHP-FPM
tail -50 /var/log/php8.3-fpm.log
tail -50 /var/log/php8.3-fpm-slow.log

# MySQL slow queries
tail -50 /var/log/mysql/slow-query.log
```

### Test Site Availability

```bash
curl -I http://ribbonfoldedpeptides.com
curl -s -o /dev/null -w "HTTP: %{http_code}, Time: %{time_total}s\n" http://ribbonfoldedpeptides.com
```

---

## Expected Results

### Memory Usage (After Optimization)

```
               total        used        free      shared  buff/cache   available
Mem:           2.9Gi       1.2Gi       1.0Gi       3.9Mi       700Mi       1.7Gi
Swap:          4.0Gi          0B       4.0Gi
```

### Process Counts

- **PHP-FPM:** 1-3 idle, max 8 under load
- **MySQL:** 1 process, ~200-300MB RAM
- **NGINX:** 2-4 workers

### Services Running

```
✓ nginx.service
✓ php8.3-fpm.service
✓ mariadb.service
✓ service-monitor.service
```

---

## Troubleshooting

### PHP-FPM Still Using Too Much Memory?

```bash
# Check current config
grep -E "^pm|^pm\." /etc/php/8.3/fpm/pool.d/www.conf

# Should show:
# pm = ondemand
# pm.max_children = 8
```

### Services Keep Crashing?

```bash
# Check service-monitor is running
systemctl status service-monitor.service

# Check logs for errors
journalctl -u service-monitor.service -n 50
```

### No Swap Space?

```bash
# Verify swap is active
swapon --show
free -h

# If not showing, re-run Step 1
```

### Site Still Slow?

```bash
# Check for slow queries
tail -100 /var/log/mysql/slow-query.log

# Check PHP-FPM slow requests
tail -100 /var/log/php8.3-fpm-slow.log

# Check NGINX access times
tail -100 /var/log/nginx/access.log
```

---

## Rollback Instructions

### Rollback PHP-FPM Config

```bash
cp /etc/php/8.3/fpm/pool.d/www.conf.backup /etc/php/8.3/fpm/pool.d/www.conf
systemctl restart php8.3-fpm
```

### Rollback MySQL Config

```bash
rm /etc/mysql/mariadb.conf.d/99-optimization.cnf
systemctl restart mariadb
```

### Remove Monitoring

```bash
systemctl stop service-monitor.service
systemctl disable service-monitor.service
rm /etc/systemd/system/service-monitor.service
systemctl daemon-reload
```

---

## Maintenance

### Weekly Tasks

```bash
# Check disk usage
df -h

# Review logs for errors
grep -i error /var/log/service-monitor.log | tail -20
grep -i error /var/log/health-check.log | tail -20

# Check for slow queries
tail -50 /var/log/mysql/slow-query.log
```

### Monthly Tasks

```bash
# Review and optimize database
mysqlcheck -u root -p --optimize --all-databases

# Review swap usage history
sar -S 1 10

# Update system packages
apt update && apt upgrade -y
```

---

## Emergency Commands

### Site Down - Quick Restart All

```bash
systemctl restart nginx php8.3-fpm mariadb
```

### Memory Full - Emergency Cleanup

```bash
# Clear page cache (safe)
sync && echo 1 > /proc/sys/vm/drop_caches

# Restart PHP-FPM (frees memory)
systemctl restart php8.3-fpm
```

### Check What's Using Memory Right Now

```bash
ps aux --sort=-%mem | head -20
```

---

## Support

**Configuration Files:** `/tmp/github-slideshow/server-configs/`
**Logs:** `/var/log/`
**Monitoring:** `/var/log/service-monitor.log`
**Health Checks:** `/var/log/health-check.log`

For issues, check logs first and verify all services are running with `systemctl status`.
