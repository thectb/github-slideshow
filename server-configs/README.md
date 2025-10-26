# Server Optimization Package

Complete server optimization package for Ubuntu 24.04 servers with 3GB RAM running NGINX + PHP-FPM + MySQL.

## Problem This Solves

**Symptoms:**
- Server crashes due to memory exhaustion
- PHP-FPM using 2.5GB+ RAM (14 processes × 160MB each)
- No swap space configured
- Site becomes unresponsive under load

**Root Causes:**
- PHP-FPM configured with `pm = dynamic` spawns too many child processes
- No swap space to handle memory spikes
- MySQL not optimized for low-memory environments
- No monitoring or auto-recovery

## Solution Overview

This package provides:

1. **PHP-FPM Optimization** - Reduces PHP-FPM from 14 processes to max 8, uses `ondemand` mode
2. **Swap Space Configuration** - Adds 4GB swap to prevent OOM crashes
3. **MySQL Optimization** - Tunes InnoDB buffer pool and limits connections
4. **Service Monitoring** - Auto-restarts crashed services every 60 seconds
5. **Health Checks** - Monitors site availability and memory usage every 5 minutes
6. **Log Rotation** - Prevents logs from filling disk

## Quick Start

### Option 1: One-Command Deploy

```bash
cd /tmp
git clone https://github.com/thectb/github-slideshow.git
cd github-slideshow/server-configs
chmod +x deploy-all.sh
./deploy-all.sh
```

### Option 2: Manual Step-by-Step

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

## Directory Structure

```
server-configs/
├── deploy-all.sh           # One-command deployment script
├── DEPLOYMENT.md           # Detailed deployment guide
├── README.md              # This file
├── php/
│   └── www.conf           # Optimized PHP-FPM pool config
├── mysql/
│   └── mysql-optimization.cnf  # MySQL memory optimization
├── scripts/
│   ├── service-monitor.sh # Auto-restart crashed services
│   └── health-check.sh    # Site and memory monitoring
├── systemd/
│   └── service-monitor.service  # Systemd unit for monitor
└── logrotate/
    └── server-logs        # Log rotation config
```

## What Each Component Does

### PHP-FPM Configuration (`php/www.conf`)

**Changes:**
- `pm = ondemand` - Only spawn processes when needed
- `pm.max_children = 8` - Limit max processes to 8 (was 14+)
- `pm.process_idle_timeout = 10s` - Kill idle processes quickly
- `memory_limit = 128M` - Limit per-process memory

**Expected Result:** PHP-FPM uses 1-3 processes idle, max 1.3GB under load (was 2.5GB)

### Swap Space

**Changes:**
- Creates 4GB swap file at `/swapfile`
- Adds to `/etc/fstab` for persistence

**Expected Result:** Server has safety buffer when RAM fills, prevents crashes

### MySQL Optimization (`mysql/mysql-optimization.cnf`)

**Changes:**
- `innodb_buffer_pool_size = 256M` - Limit InnoDB memory
- `max_connections = 50` - Prevent connection spam
- `performance_schema = OFF` - Save memory
- Various buffer size reductions

**Expected Result:** MySQL stays under 300MB RAM (was 237MB, preventing growth)

### Service Monitor (`scripts/service-monitor.sh`)

**Function:**
- Runs as systemd service every 60 seconds
- Checks if NGINX, PHP-FPM, and MySQL are running
- Auto-restarts any crashed service
- Logs all events to `/var/log/service-monitor.log`

**Expected Result:** Services auto-recover from crashes within 60 seconds

### Health Check (`scripts/health-check.sh`)

**Function:**
- Runs via cron every 5 minutes
- Tests site HTTP response
- Checks memory usage and alerts if >80%
- Logs to `/var/log/health-check.log`

**Expected Result:** Early warning of memory issues before crash

### Log Rotation (`logrotate/server-logs`)

**Function:**
- Rotates PHP-FPM, NGINX, MySQL, and monitoring logs
- Keeps 14 days for web logs, 30 days for monitoring
- Compresses old logs

**Expected Result:** Logs don't fill disk space

## Expected Performance

### Before Optimization

```
Memory: 2.9GB total, 2.5GB used, 92MB free
Swap: 0GB
PHP-FPM: 14 processes, 2.24GB
MySQL: 237MB
Status: Crashes frequently
```

### After Optimization

```
Memory: 2.9GB total, 1.2GB used, 1.0GB free
Swap: 4GB available
PHP-FPM: 2-3 processes idle, max 8 under load (1.3GB max)
MySQL: 200-300MB
Status: Stable
```

## Verification Commands

```bash
# Check memory
free -h

# Check PHP-FPM process count
ps aux | grep php-fpm | wc -l

# Check service status
systemctl status nginx php8.3-fpm mariadb service-monitor

# View monitoring logs
tail -f /var/log/service-monitor.log

# Check health check results
tail -f /var/log/health-check.log
```

## Troubleshooting

### PHP-FPM Still Using Too Much Memory

```bash
# Verify config is correct
grep -E "^pm|^pm\." /etc/php/8.3/fpm/pool.d/www.conf

# Should show:
# pm = ondemand
# pm.max_children = 8

# If wrong, redeploy:
cp php/www.conf /etc/php/8.3/fpm/pool.d/www.conf
systemctl restart php8.3-fpm
```

### Service Monitor Not Running

```bash
systemctl status service-monitor.service
journalctl -u service-monitor.service -n 50
systemctl restart service-monitor.service
```

### No Swap Space

```bash
# Check if swap is active
free -h
swapon --show

# If not active:
swapon /swapfile
```

## Rollback

To undo all changes:

```bash
# Remove swap
swapoff /swapfile
rm /swapfile
sed -i '/swapfile/d' /etc/fstab

# Restore PHP-FPM
cp /etc/php/8.3/fpm/pool.d/www.conf.backup /etc/php/8.3/fpm/pool.d/www.conf
systemctl restart php8.3-fpm

# Remove MySQL optimization
rm /etc/mysql/mariadb.conf.d/99-optimization.cnf
systemctl restart mariadb

# Stop monitoring
systemctl stop service-monitor.service
systemctl disable service-monitor.service
crontab -l | grep -v health-check.sh | crontab -
```

## Support

- **Full deployment guide:** [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Configuration files:** This directory
- **Logs:** `/var/log/service-monitor.log` and `/var/log/health-check.log`

## License

Same as parent repository.
