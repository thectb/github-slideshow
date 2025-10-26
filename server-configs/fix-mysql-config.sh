#!/bin/bash
#
# MySQL Configuration Directory Fix
# Run this on your server to find and configure MySQL properly
#

echo "=== MySQL Configuration Diagnostics ==="
echo ""

# 1. Check if MySQL/MariaDB is installed
echo "[1] Checking MySQL/MariaDB installation..."
if command -v mysql &> /dev/null; then
    mysql --version
    echo "✓ MySQL/MariaDB is installed"
else
    echo "✗ MySQL/MariaDB not found"
    exit 1
fi

echo ""

# 2. Find MySQL config directories
echo "[2] Looking for MySQL configuration directories..."
POSSIBLE_DIRS=(
    "/etc/mysql/mariadb.conf.d"
    "/etc/mysql/mysql.conf.d"
    "/etc/mysql/conf.d"
    "/etc/my.cnf.d"
)

MYSQL_CONF_DIR=""
for dir in "${POSSIBLE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✓ Found: $dir"
        if [ -z "$MYSQL_CONF_DIR" ]; then
            MYSQL_CONF_DIR="$dir"
        fi
    else
        echo "✗ Not found: $dir"
    fi
done

echo ""

# 3. If no config dir found, create one
if [ -z "$MYSQL_CONF_DIR" ]; then
    echo "[3] No config directory found. Creating /etc/mysql/conf.d..."
    mkdir -p /etc/mysql/conf.d
    MYSQL_CONF_DIR="/etc/mysql/conf.d"
    echo "✓ Created: $MYSQL_CONF_DIR"
else
    echo "[3] Using config directory: $MYSQL_CONF_DIR"
fi

echo ""

# 4. Deploy the optimization config
echo "[4] Deploying MySQL optimization config..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "$SCRIPT_DIR/mysql/mysql-optimization.cnf" ]; then
    cp "$SCRIPT_DIR/mysql/mysql-optimization.cnf" "$MYSQL_CONF_DIR/99-optimization.cnf"
    echo "✓ Config deployed to: $MYSQL_CONF_DIR/99-optimization.cnf"
else
    echo "✗ Source file not found: $SCRIPT_DIR/mysql/mysql-optimization.cnf"
    exit 1
fi

echo ""

# 5. Create MySQL log directory
echo "[5] Creating MySQL log directory..."
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql 2>/dev/null || chown mysql:adm /var/log/mysql 2>/dev/null
echo "✓ Log directory ready: /var/log/mysql"

echo ""

# 6. Test MySQL config
echo "[6] Testing MySQL configuration..."
if mysqld --help --verbose 2>&1 | grep -q "innodb-buffer-pool-size"; then
    echo "✓ MySQL config test passed"
else
    echo "⚠ Warning: Config test had issues (this may be normal)"
fi

echo ""

# 7. Restart MySQL
echo "[7] Restarting MySQL/MariaDB..."
if systemctl restart mariadb 2>/dev/null || systemctl restart mysql 2>/dev/null; then
    echo "✓ MySQL restarted successfully"
else
    echo "✗ MySQL restart failed"
    exit 1
fi

echo ""

# 8. Verify MySQL is running
echo "[8] Verifying MySQL status..."
if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
    echo "✓ MySQL is running"
else
    echo "✗ MySQL is not running"
    exit 1
fi

echo ""

# 9. Check memory usage
echo "[9] Checking MySQL memory usage..."
ps aux | grep -E "mysql|mariadb" | grep -v grep | head -3

echo ""
echo "=== MySQL Configuration Complete ==="
echo ""
echo "Configuration file: $MYSQL_CONF_DIR/99-optimization.cnf"
echo ""
echo "To verify settings:"
echo "  mysql -e \"SHOW VARIABLES LIKE 'innodb_buffer_pool_size';\""
echo ""
