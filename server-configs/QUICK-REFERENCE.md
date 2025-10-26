# Quick Reference Card

## Emergency Commands

### Server Crashed - Quick Recovery

```bash
# Restart all services
systemctl restart nginx php8.3-fpm mariadb

# Check what's running
systemctl status nginx php8.3-fpm mariadb

# Free up memory immediately
sync && echo 1 > /proc/sys/vm/drop_caches
systemctl restart php8.3-fpm
```

### Check Current Status

```bash
# Memory usage
free -h

# Top memory consumers
ps aux --sort=-%mem | head -15

# PHP-FPM processes
ps aux | grep php-fpm | wc -l

# Disk usage
df -h
```

### View Logs

```bash
# Real-time monitoring
tail -f /var/log/service-monitor.log

# Health check results
tail -f /var/log/health-check.log

# PHP-FPM errors
tail -f /var/log/php8.3-fpm-errors.log

# PHP slow requests
tail -f /var/log/php8.3-fpm-slow.log

# MySQL slow queries
tail -f /var/log/mysql/slow-query.log

# NGINX errors
tail -f /var/log/nginx/error.log
```

## Deployment Commands

### One-Command Deploy

```bash
cd /tmp
git clone https://github.com/thectb/github-slideshow.git
cd github-slideshow/server-configs
chmod +x deploy-all.sh
./deploy-all.sh
```

### Manual Deploy Steps

```bash
# 1. Add swap
fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 2. PHP-FPM config
cp php/www.conf /etc/php/8.3/fpm/pool.d/www.conf
systemctl restart php8.3-fpm

# 3. MySQL config
cp mysql/mysql-optimization.cnf /etc/mysql/mariadb.conf.d/99-optimization.cnf
systemctl restart mariadb

# 4. Service monitor
cp scripts/service-monitor.sh /usr/local/bin/service-monitor.sh
chmod +x /usr/local/bin/service-monitor.sh
cp systemd/service-monitor.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable service-monitor.service
systemctl start service-monitor.service

# 5. Health check
cp scripts/health-check.sh /usr/local/bin/health-check.sh
chmod +x /usr/local/bin/health-check.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/health-check.sh") | crontab -

# 6. Log rotation
cp logrotate/server-logs /etc/logrotate.d/server-logs
```

## Configuration Verification

### Check PHP-FPM Config

```bash
# View current settings
grep -E "^pm|^pm\." /etc/php/8.3/fpm/pool.d/www.conf

# Expected output:
# pm = ondemand
# pm.max_children = 8
# pm.process_idle_timeout = 10s
# pm.max_requests = 500
```

### Check MySQL Config

```bash
# View buffer pool size
mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

# Expected: 268435456 (256MB)
```

### Check Swap

```bash
# Show swap usage
swapon --show
free -h

# Expected: 4GB swap available
```

### Check Services

```bash
# All services status
systemctl status nginx php8.3-fpm mariadb service-monitor

# Or one-liner
for s in nginx php8.3-fpm mariadb service-monitor; do systemctl is-active $s && echo "✓ $s"; done
```

## Performance Testing

### Test Site Response

```bash
# HTTP status and response time
curl -s -o /dev/null -w "HTTP: %{http_code}, Time: %{time_total}s\n" http://ribbonfoldedpeptides.com

# Full headers
curl -I http://ribbonfoldedpeptides.com

# Load test (10 requests)
for i in {1..10}; do curl -s -o /dev/null -w "Request $i: %{time_total}s\n" http://ribbonfoldedpeptides.com; done
```

### Monitor Memory During Load

```bash
# Watch memory in real-time
watch -n 2 'free -h; echo ""; ps aux --sort=-%mem | head -10'

# Or continuous log
while true; do date; free -h; ps aux | grep php-fpm | wc -l; sleep 5; done
```

## Troubleshooting

### PHP-FPM Won't Start

```bash
# Test config
php-fpm8.3 -t

# Check logs
journalctl -u php8.3-fpm -n 50

# View error log
tail -50 /var/log/php8.3-fpm.log
```

### MySQL Won't Start

```bash
# Check logs
journalctl -u mariadb -n 50
tail -50 /var/log/mysql/error.log

# Test config
mysqld --help --verbose 2>&1 | grep error
```

### Service Monitor Not Working

```bash
# Check status
systemctl status service-monitor.service

# View logs
journalctl -u service-monitor.service -n 50
tail -50 /var/log/service-monitor.log

# Restart
systemctl restart service-monitor.service
```

### High Memory Usage

```bash
# Find culprit
ps aux --sort=-%mem | head -20

# Check for memory leaks in PHP
ps aux | grep php-fpm | awk '{print $6}' | sort -n | tail -5

# Restart PHP-FPM to clear
systemctl restart php8.3-fpm
```

## Maintenance Tasks

### Daily

```bash
# Quick health check
free -h
df -h
systemctl status nginx php8.3-fpm mariadb
```

### Weekly

```bash
# Review logs for errors
grep -i error /var/log/service-monitor.log | tail -20
grep -i error /var/log/health-check.log | tail -20

# Check for slow queries
tail -50 /var/log/mysql/slow-query.log

# Check disk usage
du -sh /var/log/*
```

### Monthly

```bash
# Optimize database
mysqlcheck -u root -p --optimize --all-databases

# Review and rotate logs manually if needed
logrotate -f /etc/logrotate.d/server-logs

# Update system
apt update && apt upgrade -y
```

## File Locations

**Configs:**
- PHP-FPM: `/etc/php/8.3/fpm/pool.d/www.conf`
- MySQL: `/etc/mysql/mariadb.conf.d/99-optimization.cnf`
- Logrotate: `/etc/logrotate.d/server-logs`

**Scripts:**
- Service Monitor: `/usr/local/bin/service-monitor.sh`
- Health Check: `/usr/local/bin/health-check.sh`

**Services:**
- Service Monitor: `/etc/systemd/system/service-monitor.service`

**Logs:**
- Service Monitor: `/var/log/service-monitor.log`
- Health Check: `/var/log/health-check.log`
- PHP-FPM: `/var/log/php8.3-fpm.log`
- PHP Errors: `/var/log/php8.3-fpm-errors.log`
- PHP Slow: `/var/log/php8.3-fpm-slow.log`
- MySQL Slow: `/var/log/mysql/slow-query.log`
- NGINX: `/var/log/nginx/error.log`

## Expected Metrics

**Memory:**
- Total: 2.9GB
- Used: 1.0-1.5GB
- Free: 1.0-1.5GB
- Available: 1.5-2.0GB

**PHP-FPM:**
- Idle: 1-3 processes
- Under load: 3-8 processes
- Memory per process: 128-160MB
- Total PHP memory: 0.5-1.3GB max

**MySQL:**
- Memory: 200-300MB
- Connections: <50

**Services:**
- NGINX: Running
- PHP-FPM: Running
- MariaDB: Running
- Service Monitor: Running
