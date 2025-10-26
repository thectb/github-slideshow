#!/bin/bash
# ================================================================
# FIREWALL & SECURITY VERIFICATION AUDIT
# For: ribbonfoldedpeptides.com (80.78.18.98)
# Generated for independent security verification
# ================================================================

echo "================================================================"
echo "FIREWALL & SECURITY AUDIT - ribbonfoldedpeptides.com"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Server: $(hostname)"
echo "IP: $(hostname -I | awk '{print $1}')"
echo "================================================================"
echo ""

# ================================================================
# 1. UFW FIREWALL STATUS
# ================================================================
echo "=== 1. UFW FIREWALL STATUS ==="
if command -v ufw &> /dev/null; then
    echo "✓ UFW is installed"
    echo ""
    echo "Status and rules:"
    ufw status verbose
    echo ""
    echo "Numbered rules:"
    ufw status numbered 2>/dev/null || echo "Cannot display numbered rules"
else
    echo "✗ UFW NOT INSTALLED - CRITICAL VULNERABILITY"
fi
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 2. FAIL2BAN STATUS
# ================================================================
echo "=== 2. FAIL2BAN INTRUSION PREVENTION ==="
if command -v fail2ban-client &> /dev/null; then
    echo "✓ Fail2Ban is installed"
    echo ""
    echo "Service status:"
    systemctl status fail2ban --no-pager -l 2>/dev/null || service fail2ban status 2>/dev/null || echo "Cannot check service status"
    echo ""
    echo "Active jails:"
    fail2ban-client status
    echo ""
    echo "SSH jail details (if exists):"
    fail2ban-client status sshd 2>/dev/null || echo "sshd jail not configured"
    echo ""
    echo "NGINX jails (if exist):"
    fail2ban-client status nginx-limit-req 2>/dev/null || echo "nginx-limit-req jail not configured"
    fail2ban-client status nginx-botsearch 2>/dev/null || echo "nginx-botsearch jail not configured"
else
    echo "✗ Fail2Ban NOT INSTALLED - Missing intrusion prevention"
fi
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 3. IPTABLES RULES (Actual Firewall at Kernel Level)
# ================================================================
echo "=== 3. ACTIVE IPTABLES RULES (Kernel-Level Firewall) ==="
if command -v iptables &> /dev/null; then
    echo "INPUT chain (incoming traffic - most critical):"
    iptables -L INPUT -n -v --line-numbers
    echo ""
    echo "FORWARD chain (forwarded traffic):"
    iptables -L FORWARD -n -v --line-numbers | head -15
    echo ""
    echo "OUTPUT chain (outgoing traffic):"
    iptables -L OUTPUT -n -v --line-numbers | head -15
    echo ""
    echo "NAT table (if used):"
    iptables -t nat -L -n -v 2>/dev/null | head -20
else
    echo "✗ iptables NOT AVAILABLE - CRITICAL ISSUE"
fi
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 4. ALL LISTENING PORTS (Attack Surface Analysis)
# ================================================================
echo "=== 4. LISTENING PORTS (Attack Surface) ==="
echo "All services listening on network:"
netstat -tulpn 2>/dev/null | grep LISTEN | sort -t: -k2 -n || ss -tulpn | grep LISTEN | sort
echo ""
echo "Port summary:"
echo "Total listening ports: $(netstat -tulpn 2>/dev/null | grep LISTEN | wc -l || ss -tulpn | grep LISTEN | wc -l)"
echo ""
echo "Ports exposed to internet (0.0.0.0 or ::):"
netstat -tulpn 2>/dev/null | grep LISTEN | grep -E "0.0.0.0|:::" || ss -tulpn | grep LISTEN | grep -E "0.0.0.0|:::"
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 5. MYSQL/MARIADB BINDING (Critical for Database Security)
# ================================================================
echo "=== 5. MYSQL/MARIADB BINDING ==="
echo "MySQL listening status:"
netstat -tulpn 2>/dev/null | grep 3306 || ss -tulpn | grep 3306 || echo "MySQL not listening (or using socket only)"
echo ""
echo "MySQL config - bind-address:"
grep -r "bind-address" /etc/my.cnf /etc/mysql/ 2>/dev/null | grep -v "#" || echo "No bind-address found in configs"
echo ""
if netstat -tulpn 2>/dev/null | grep "0.0.0.0:3306" || ss -tulpn 2>/dev/null | grep "0.0.0.0:3306"; then
    echo "⚠️  WARNING: MySQL is EXPOSED to internet on 0.0.0.0 - CRITICAL VULNERABILITY"
elif netstat -tulpn 2>/dev/null | grep "127.0.0.1:3306" || ss -tulpn 2>/dev/null | grep "127.0.0.1:3306"; then
    echo "✓ GOOD: MySQL bound to localhost only (127.0.0.1)"
else
    echo "ℹ️  MySQL may be using Unix socket only (secure)"
fi
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 6. SSL CERTIFICATE STATUS
# ================================================================
echo "=== 6. SSL CERTIFICATE STATUS ==="
echo "Certificate details:"
echo | openssl s_client -servername ribbonfoldedpeptides.com -connect ribbonfoldedpeptides.com:443 2>/dev/null | openssl x509 -noout -dates -issuer -subject 2>/dev/null || echo "Cannot check SSL (server may not be accessible or SSL not configured)"
echo ""
echo "Days until expiration:"
CERT_END=$(echo | openssl s_client -servername ribbonfoldedpeptides.com -connect ribbonfoldedpeptides.com:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [ -n "$CERT_END" ]; then
    CERT_END_EPOCH=$(date -d "$CERT_END" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($CERT_END_EPOCH - $NOW_EPOCH) / 86400 ))
    echo "Days remaining: $DAYS_LEFT"
    if [ "$DAYS_LEFT" -lt 30 ] && [ "$DAYS_LEFT" -gt 0 ]; then
        echo "⚠️  WARNING: Certificate expires in less than 30 days"
    elif [ "$DAYS_LEFT" -le 0 ]; then
        echo "❌ CRITICAL: Certificate is EXPIRED"
    else
        echo "✓ Certificate valid for $DAYS_LEFT more days"
    fi
fi
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 7. HTTP→HTTPS REDIRECT TEST
# ================================================================
echo "=== 7. HTTP→HTTPS REDIRECT TEST ==="
echo "Testing HTTP request to ribbonfoldedpeptides.com:"
curl -I -L http://ribbonfoldedpeptides.com 2>/dev/null | head -10 || echo "Cannot test redirect"
echo ""
REDIRECT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://ribbonfoldedpeptides.com 2>/dev/null)
if [ "$REDIRECT_STATUS" = "301" ] || [ "$REDIRECT_STATUS" = "302" ]; then
    echo "✓ GOOD: HTTP redirects with status $REDIRECT_STATUS"
elif [ "$REDIRECT_STATUS" = "200" ]; then
    echo "⚠️  WARNING: HTTP returns 200 (not redirecting to HTTPS) - Security issue"
else
    echo "Status code: $REDIRECT_STATUS"
fi
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 8. AAPANEL FIREWALL STATUS
# ================================================================
echo "=== 8. AAPANEL FIREWALL STATUS ==="
if [ -d /www/server/panel ]; then
    echo "✓ aaPanel is installed"
    echo ""
    echo "aaPanel firewall service:"
    systemctl status bt-firewall --no-pager 2>/dev/null || echo "bt-firewall service not found or not active"
    echo ""
    echo "aaPanel firewall config (if exists):"
    if [ -f /www/server/panel/data/firewall.json ]; then
        cat /www/server/panel/data/firewall.json 2>/dev/null || echo "Cannot read firewall.json"
    else
        echo "No firewall.json found"
    fi
    echo ""
    if [ -f /www/server/panel/class/firewall.py ]; then
        echo "aaPanel firewall module exists at: /www/server/panel/class/firewall.py"
    fi
else
    echo "aaPanel directory not found at /www/server/panel"
fi
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 9. RUNNING FIREWALL PROCESSES
# ================================================================
echo "=== 9. RUNNING FIREWALL PROCESSES ==="
echo "Firewall-related processes:"
ps aux | grep -E "ufw|fail2ban|iptables|firewall" | grep -v grep || echo "No firewall processes found"
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 10. RECENT SECURITY EVENTS
# ================================================================
echo "=== 10. RECENT SECURITY EVENTS ==="
echo "Failed SSH login attempts (last 50):"
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -50 || echo "No auth.log or no failed attempts logged"
echo ""
echo "Fail2Ban recent bans (last 50 lines):"
tail -50 /var/log/fail2ban.log 2>/dev/null || echo "No fail2ban.log found"
echo ""
echo "UFW blocks (last 30):"
grep "UFW BLOCK" /var/log/syslog 2>/dev/null | tail -30 || grep "UFW BLOCK" /var/log/kern.log 2>/dev/null | tail -30 || echo "No UFW blocks in logs"
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 11. SERVICE STATUS
# ================================================================
echo "=== 11. SECURITY SERVICE STATUS ==="
echo "Checking critical services:"
echo ""
echo "UFW:"
systemctl is-active ufw 2>/dev/null && echo "  ✓ UFW service: ACTIVE" || echo "  ✗ UFW service: INACTIVE or not managed by systemd"
echo ""
echo "Fail2Ban:"
systemctl is-active fail2ban 2>/dev/null && echo "  ✓ Fail2Ban service: ACTIVE" || echo "  ✗ Fail2Ban service: INACTIVE or not managed by systemd"
echo ""
echo "NGINX:"
systemctl is-active nginx 2>/dev/null && echo "  ✓ NGINX: ACTIVE" || ps aux | grep nginx | grep -v grep >/dev/null && echo "  ✓ NGINX: ACTIVE (not systemd)" || echo "  ✗ NGINX: INACTIVE"
echo ""
echo "MariaDB/MySQL:"
systemctl is-active mariadb 2>/dev/null && echo "  ✓ MariaDB: ACTIVE" || systemctl is-active mysql 2>/dev/null && echo "  ✓ MySQL: ACTIVE" || ps aux | grep mysql | grep -v grep >/dev/null && echo "  ✓ MySQL: ACTIVE (not systemd)" || echo "  ✗ MySQL: INACTIVE"
echo ""
echo "PHP-FPM:"
ps aux | grep php-fpm | grep -v grep >/dev/null && echo "  ✓ PHP-FPM: ACTIVE ($(ps aux | grep php-fpm | grep -v grep | wc -l) processes)" || echo "  ✗ PHP-FPM: INACTIVE"
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 12. MEMORY USAGE
# ================================================================
echo "=== 12. MEMORY USAGE ==="
free -h
echo ""
echo "Top memory consumers:"
ps aux --sort=-%mem | head -10
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 13. EXPOSED INSECURE SERVICES CHECK
# ================================================================
echo "=== 13. INSECURE SERVICES CHECK ==="
echo "Checking for commonly exploited services exposed to internet:"
echo ""
echo "FTP (port 21):"
netstat -tulpn 2>/dev/null | grep ":21 " || ss -tulpn 2>/dev/null | grep ":21 " || echo "  ✓ Not exposed"
echo ""
echo "Telnet (port 23):"
netstat -tulpn 2>/dev/null | grep ":23 " || ss -tulpn 2>/dev/null | grep ":23 " || echo "  ✓ Not exposed"
echo ""
echo "SMTP (port 25):"
netstat -tulpn 2>/dev/null | grep ":25 " || ss -tulpn 2>/dev/null | grep ":25 " || echo "  ✓ Not exposed"
echo ""
echo "MySQL (port 3306 on 0.0.0.0):"
netstat -tulpn 2>/dev/null | grep "0.0.0.0:3306" || ss -tulpn 2>/dev/null | grep "0.0.0.0:3306" || echo "  ✓ Not exposed to internet"
echo ""
echo "PostgreSQL (port 5432):"
netstat -tulpn 2>/dev/null | grep ":5432 " || ss -tulpn 2>/dev/null | grep ":5432 " || echo "  ✓ Not exposed"
echo ""
echo "Redis (port 6379):"
netstat -tulpn 2>/dev/null | grep ":6379 " || ss -tulpn 2>/dev/null | grep ":6379 " || echo "  ✓ Not exposed"
echo ""
echo "MongoDB (port 27017):"
netstat -tulpn 2>/dev/null | grep ":27017 " || ss -tulpn 2>/dev/null | grep ":27017 " || echo "  ✓ Not exposed"
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# 14. WORDPRESS SECURITY
# ================================================================
echo "=== 14. WORDPRESS SECURITY ==="
if [ -f /var/www/ribbonfoldedpeptides.com/html/wp-config.php ] || [ -f /www/wwwroot/ribbonfoldedpeptides.com/wp-config.php ]; then
    echo "✓ WordPress installation found"
    echo ""
    WP_PATH="/var/www/ribbonfoldedpeptides.com/html"
    [ ! -d "$WP_PATH" ] && WP_PATH="/www/wwwroot/ribbonfoldedpeptides.com"

    echo "wp-config.php permissions:"
    ls -la "$WP_PATH/wp-config.php" 2>/dev/null || echo "Cannot check permissions"
    echo ""
    echo "Active WordPress plugins:"
    if command -v wp &> /dev/null; then
        wp plugin list --path="$WP_PATH" --allow-root 2>/dev/null || echo "WP-CLI not available or cannot list plugins"
    else
        ls -1 "$WP_PATH/wp-content/plugins/" 2>/dev/null || echo "Cannot list plugins directory"
    fi
else
    echo "WordPress not found at standard locations"
fi
echo ""
echo "----------------------------------------------------------------"
echo ""

# ================================================================
# SUMMARY
# ================================================================
echo "================================================================"
echo "AUDIT COMPLETE - $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================================"
echo ""
echo "NEXT STEPS:"
echo "1. Copy ALL output above"
echo "2. Provide to AI security analyst for interpretation"
echo ""
echo "Key items to verify in analysis:"
echo "  • Is UFW active and enforcing rules?"
echo "  • Is Fail2Ban running and blocking attacks?"
echo "  • Is MySQL bound to localhost only?"
echo "  • Is HTTPS working with valid SSL?"
echo "  • Does HTTP redirect to HTTPS (301)?"
echo "  • Are insecure services disabled?"
echo "  • Is attack surface minimized?"
echo ""
echo "Expected secure configuration:"
echo "  ✓ UFW: active"
echo "  ✓ Fail2Ban: running with active jails"
echo "  ✓ MySQL: 127.0.0.1 (NOT 0.0.0.0)"
echo "  ✓ SSL: valid, >30 days until expiry"
echo "  ✓ HTTP→HTTPS: 301/302 redirect"
echo "  ✓ Listening ports: 8-10 (minimal)"
echo "  ✓ FTP/Telnet/etc: not exposed"
echo "================================================================"
