# BT Panel / aaPanel Server Optimization Guide

**For servers using BT Panel (宝塔面板) or aaPanel with custom PHP installation**

## Problem

BT Panel installs PHP-FPM at `/www/server/php/` with default settings that spawn too many processes:

- `pm = dynamic` with `pm.max_children = 80`
- Can spawn up to 80 PHP-FPM processes
- Each process uses 150-160MB RAM
- On 3GB RAM servers: 28+ processes = 2.4GB used = crashes

## Solution

Change PHP-FPM to on-demand mode with max 8 children:

- `pm = ondemand` - Only spawns processes when needed
- `pm.max_children = 8` - Maximum 8 processes
- `pm.process_idle_timeout = 10s` - Kill idle processes quickly
- **Result:** 2-4 processes idle, max 1.3GB under load

---

## Quick Fix (Emergency)

If your server is crashing NOW, run this:

```bash
cd /tmp
git clone https://github.com/thectb/github-slideshow.git
cd github-slideshow/server-configs
chmod +x quick-fix-bt-panel.sh
./quick-fix-bt-panel.sh
```

**This will:**
1. Backup your current config
2. Change pm to ondemand, max_children to 8
3. Restart PHP-FPM
4. Show memory usage

**Expected result:**
- Memory drops from 2.4GB to ~700MB
- PHP-FPM processes drop from 28+ to 2-4

---

## Full Deployment

For complete optimization including MySQL tuning and monitoring:

```bash
cd /tmp
git clone https://github.com/thectb/github-slideshow.git
cd github-slideshow/server-configs
chmod +x deploy-bt-panel.sh
./deploy-bt-panel.sh
```

**This deploys:**
1. PHP-FPM optimization (ondemand mode)
2. MySQL optimization (256MB buffer pool)
3. Service monitoring (auto-restart crashed services)
4. Health checks (memory alerts)

---

## Manual Fix

If you want to do it manually:

### Step 1: Backup Config

```bash
cp /www/server/php/83/etc/php-fpm.conf /www/server/php/83/etc/php-fpm.conf.backup
```

### Step 2: Edit Config

```bash
sed -i 's/pm = dynamic/pm = ondemand/' /www/server/php/83/etc/php-fpm.conf
sed -i 's/pm.max_children = .*/pm.max_children = 8/' /www/server/php/83/etc/php-fpm.conf
sed -i '/pm.start_servers/d' /www/server/php/83/etc/php-fpm.conf
sed -i '/pm.min_spare_servers/d' /www/server/php/83/etc/php-fpm.conf
sed -i '/pm.max_spare_servers/d' /www/server/php/83/etc/php-fpm.conf
echo "pm.process_idle_timeout = 10s" >> /www/server/php/83/etc/php-fpm.conf
```

### Step 3: Verify Config

```bash
grep -E "^pm" /www/server/php/83/etc/php-fpm.conf
```

**Should show:**
```
pm = ondemand
pm.status_path = /phpfpm_83_status
pm.max_children = 8
pm.process_idle_timeout = 10s
```

### Step 4: Restart PHP-FPM

```bash
killall php-fpm
sleep 2
/www/server/php/83/sbin/php-fpm
```

### Step 5: Verify Results

```bash
# Check process count (should be 2-4)
ps aux | grep php-fpm | wc -l

# Check memory usage (should be ~700MB used)
free -h
```

---

## Important Notes

### Container Limitations

**Swap does NOT work in LXC containers!**

If you get this error:
```
swapon: /swapfile: swapon failed: Operation not permitted
```

**This is normal.** Our optimization doesn't rely on swap - it prevents memory exhaustion by limiting PHP-FPM processes.

### BT Panel vs Standard PHP

BT Panel uses a **custom PHP installation** at `/www/server/php/83/`:

❌ **WRONG:** `/etc/php/8.3/fpm/pool.d/www.conf` (standard location)
✅ **CORRECT:** `/www/server/php/83/etc/php-fpm.conf` (BT Panel location)

**Always edit the BT Panel config file**, not the standard one!

### PHP Versions

This guide assumes PHP 8.3. If you're using a different version, change:
- `/www/server/php/83/` → `/www/server/php/XX/`
- `killall php-fpm` works for all versions

Find your PHP version:
```bash
ls /www/server/php/
```

---

## Verification Commands

### Check Current Config

```bash
grep -E "^pm" /www/server/php/83/etc/php-fpm.conf
```

### Check Memory Usage

```bash
free -h
```

### Check PHP-FPM Processes

```bash
# Count
ps aux | grep php-fpm | wc -l

# Detailed view
ps aux | grep php-fpm | head -10
```

### Check Services Running

```bash
ps aux | grep nginx | grep -v grep
ps aux | grep php-fpm | grep -v grep
ps aux | grep mysql | grep -v grep
```

---

## Troubleshooting

### PHP-FPM Won't Start

```bash
# Check for errors
/www/server/php/83/sbin/php-fpm -t

# Check if already running
ps aux | grep php-fpm

# Kill all and restart
killall php-fpm
/www/server/php/83/sbin/php-fpm
```

### Still High Memory Usage

```bash
# Verify config is correct
grep "pm.max_children" /www/server/php/83/etc/php-fpm.conf

# Should show: pm.max_children = 8

# Count processes
ps aux | grep php-fpm | wc -l

# If >10, restart PHP-FPM again
killall php-fpm
/www/server/php/83/sbin/php-fpm
```

### Site Not Loading

```bash
# Check NGINX
ps aux | grep nginx

# Check PHP-FPM socket
ls -la /tmp/php-cgi-83.sock

# Test site
curl -I http://your-domain.com
```

---

## Expected Results

### Before Optimization

```
Memory:
               total        used        free      shared  buff/cache   available
Mem:           2.9Gi       2.4Gi        28Mi       3.9Mi       439Mi       464Mi

PHP-FPM: 28 processes
Status: Crashes frequently
```

### After Optimization

```
Memory:
               total        used        free      shared  buff/cache   available
Mem:           2.9Gi       740Mi       1.8Gi       3.9Mi       342Mi       2.1Gi

PHP-FPM: 2-4 processes
Status: Stable
```

**Memory saved: ~1.66GB**

---

## Rollback

To undo changes:

```bash
# Restore backup
cp /www/server/php/83/etc/php-fpm.conf.backup /www/server/php/83/etc/php-fpm.conf

# Restart
killall php-fpm
/www/server/php/83/sbin/php-fpm
```

---

## Additional Optimizations

### MySQL Tuning

```bash
cp mysql/mysql-optimization.cnf /etc/mysql/conf.d/99-optimization.cnf
systemctl restart mariadb
```

### Service Monitoring

Monitor and auto-restart crashed services:

```bash
cp scripts/service-monitor.sh /usr/local/bin/service-monitor.sh
chmod +x /usr/local/bin/service-monitor.sh

# Add to cron (runs every minute)
(crontab -l 2>/dev/null; echo "*/1 * * * * /usr/local/bin/service-monitor.sh >> /var/log/service-monitor.log 2>&1") | crontab -
```

### Health Checks

Monitor memory and site availability:

```bash
cp scripts/health-check.sh /usr/local/bin/health-check.sh
chmod +x /usr/local/bin/health-check.sh

# Add to cron (runs every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/health-check.sh") | crontab -
```

---

## Support

**Issue:** Site crashing due to memory
**Solution:** Run `quick-fix-bt-panel.sh`

**Issue:** Config changes not applying
**Solution:** Make sure you're editing `/www/server/php/83/etc/php-fpm.conf`, not `/etc/php/8.3/`

**Issue:** Swap won't enable
**Solution:** Normal in containers - optimization works without swap

---

## Files in This Package

- `quick-fix-bt-panel.sh` - Emergency memory fix
- `deploy-bt-panel.sh` - Full deployment script
- `BT-PANEL-README.md` - This file
- `mysql/mysql-optimization.cnf` - MySQL tuning
- `scripts/service-monitor.sh` - Auto-restart daemon
- `scripts/health-check.sh` - Health monitoring

---

**Last updated:** 2025-10-26
**Tested on:** Ubuntu 24.04 LTS with BT Panel
**PHP Version:** 8.3
