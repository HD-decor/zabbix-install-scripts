#!/bin/bash

set -e

echo "[INFO] Switching to root if needed..."
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run as root (sudo ./zabbix-ubuntu24.sh)"
  exit 1
fi

# 1. Add Zabbix repo
echo "[INFO] Downloading Zabbix repo package..."
wget -q https://repo.zabbix.com/zabbix/7.2/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.2+ubuntu20.04_all.deb
dpkg -i zabbix-release_latest_7.2+ubuntu20.04_all.deb

# 2. Patch Zabbix sources to use 'focal' instead of 'noble'
ZABBIX_LIST="/etc/apt/sources.list.d/zabbix.list"
if grep -q "noble" "$ZABBIX_LIST"; then
  echo "[PATCH] Replacing 'noble' with 'focal' in $ZABBIX_LIST"
  sed -i 's/noble/focal/g' "$ZABBIX_LIST"
fi

# 3. Add focal-security repo with universe to pull libssl1.1 during the install
echo "[INFO] Adding temporary focal-security repo to satisfy libssl1.1 dependency..."
echo "deb http://security.ubuntu.com/ubuntu focal-security main universe" > /etc/apt/sources.list.d/focal-security.list

# 4. Clean up broken repos (like Ookla)
SPEEDTEST_LIST="/etc/apt/sources.list.d/ookla_speedtest-cli.list"
if [ -f "$SPEEDTEST_LIST" ]; then
  echo "[INFO] Removing unsupported Ookla speedtest repo"
  rm -f "$SPEEDTEST_LIST"
fi

# 5. Update everything now that all repos are correctly in place
echo "[INFO] Updating apt cache..."
apt update

# 6. Install Zabbix agent2 and plugins
echo "[INFO] Installing Zabbix agent2 and required plugins..."
apt install -y zabbix-agent2 \
               zabbix-agent2-plugin-mongodb \
               zabbix-agent2-plugin-mssql \
               zabbix-agent2-plugin-postgresql

# 7. Remove the temporary focal repo after installation
rm /etc/apt/sources.list.d/focal-security.list
echo "[INFO] Removed temporary focal-security repo."

# 8. Configure agent2 with custom server and hostname
ZABBIX_CONFIG="/etc/zabbix/zabbix_agent2.conf"
cp "$ZABBIX_CONFIG" "$ZABBIX_CONFIG.bak"

HOSTNAME=$(hostname)

sed -i "s|^Server=.*|Server=zabbix.tietokettu.net|" "$ZABBIX_CONFIG"
sed -i "s|^ServerActive=.*|ServerActive=zabbix.tietokettu.net|" "$ZABBIX_CONFIG"
sed -i "s|^Hostname=.*|Hostname=${HOSTNAME}|" "$ZABBIX_CONFIG"

# 9. Enable port 10050 in UFW if it's installed and active

if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -q "Status: active"; then
    echo "[INFO] UFW is active — allowing port 10050..."
    ufw allow 10050/tcp
  else
    echo "[INFO] UFW is installed but inactive — using iptables instead..."
    iptables -I INPUT -p tcp --dport 10050 -j ACCEPT
    echo "[INFO] Making iptables rule persistent..."
    apt install -y iptables-persistent
    netfilter-persistent save
  fi
else
  echo "[INFO] UFW not installed — using iptables..."
  iptables -I INPUT -p tcp --dport 10050 -j ACCEPT
  echo "[INFO] Making iptables rule persistent..."
  apt install -y iptables-persistent
  netfilter-persistent save
fi

# 9. Start and enable the agent
echo "[INFO] Enabling and starting Zabbix agent2..."



systemctl enable --now zabbix-agent2
systemctl restart zabbix-agent2


echo "[✅ SUCCESS] Zabbix Agent 2 installed and configured for host: $HOSTNAME"
