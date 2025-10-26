#!/bin/bash
#
# Quick Fix for BT Panel PHP-FPM Memory Issues
# Run this immediately if your server is running out of memory
#

set -e

echo "=== Quick PHP-FPM Memory Fix for BT Panel ==="
echo ""

# Backup config
echo "[1/3] Backing up config..."
cp /www/server/php/83/etc/php-fpm.conf /www/server/php/83/etc/php-fpm.conf.backup.$(date +%Y%m%d-%H%M%S)

# Fix config
echo "[2/3] Optimizing PHP-FPM config..."
sed -i 's/pm = dynamic/pm = ondemand/' /www/server/php/83/etc/php-fpm.conf
sed -i 's/pm.max_children = .*/pm.max_children = 8/' /www/server/php/83/etc/php-fpm.conf
sed -i '/pm.start_servers/d' /www/server/php/83/etc/php-fpm.conf
sed -i '/pm.min_spare_servers/d' /www/server/php/83/etc/php-fpm.conf
sed -i '/pm.max_spare_servers/d' /www/server/php/83/etc/php-fpm.conf

if ! grep -q "pm.process_idle_timeout" /www/server/php/83/etc/php-fpm.conf; then
    echo "pm.process_idle_timeout = 10s" >> /www/server/php/83/etc/php-fpm.conf
fi

echo "✓ Config updated"
echo ""

# Verify
echo "New config:"
grep -E "^pm" /www/server/php/83/etc/php-fpm.conf
echo ""

# Restart
echo "[3/3] Restarting PHP-FPM..."
killall php-fpm 2>/dev/null || true
sleep 2
/www/server/php/83/sbin/php-fpm
sleep 3

echo "✓ PHP-FPM restarted"
echo ""

# Show results
echo "=== RESULTS ==="
echo ""
echo "PHP-FPM Processes: $(ps aux | grep php-fpm | grep -v grep | wc -l)"
echo ""
echo "Memory Usage:"
free -h
echo ""
echo "✓ Fix complete!"
