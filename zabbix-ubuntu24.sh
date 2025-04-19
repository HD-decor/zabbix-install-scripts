#!/bin/bash

set -e

echo "[INFO] Switching to root if needed..."
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run as root (sudo ./zabbix-ubuntu24.sh)"
  exit 1
fi

echo "[INFO] Downloading Zabbix repo package..."
wget -q https://repo.zabbix.com/zabbix/7.2/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.2+ubuntu20.04_all.deb

echo "[INFO] Installing Zabbix repo..."
dpkg -i zabbix-release_latest_7.2+ubuntu20.04_all.deb

# 🛠 Force Zabbix repo to use 'focal' instead of 'noble'
ZABBIX_LIST="/etc/apt/sources.list.d/zabbix.list"
if grep -q "noble" "$ZABBIX_LIST"; then
  echo "[PATCH] Replacing 'noble' with 'focal' in $ZABBIX_LIST"
  sed -i 's/noble/focal/g' "$ZABBIX_LIST"
  echo "# NOTE: Using 'focal' temporarily because Zabbix hasn't released for 'noble'" >> "$ZABBIX_LIST"
fi

# 🛠 Fix Ookla Speedtest repo if present
SPEEDTEST_LIST="/etc/apt/sources.list.d/ookla_speedtest-cli.list"
if [ -f "$SPEEDTEST_LIST" ]; then
  if grep -q "noble" "$SPEEDTEST_LIST"; then
    echo "[PATCH] Replacing 'noble' with 'jammy' in $SPEEDTEST_LIST"
    sed -i 's/noble/jammy/g' "$SPEEDTEST_LIST"
    echo "# NOTE: Using 'jammy' temporarily because Ookla hasn't released for 'noble'" >> "$SPEEDTEST_LIST"
  fi
fi

echo "[INFO] Updating apt cache..."
apt update

echo "[INFO] Installing Zabbix agent2 and plugins..."
apt install -y zabbix-agent2 \
               zabbix-agent2-plugin-mongodb \
               zabbix-agent2-plugin-mssql \
               zabbix-agent2-plugin-postgresql

echo "[INFO] Configuring Zabbix agent2..."
ZABBIX_CONFIG="/etc/zabbix/zabbix_agent2.conf"
cp "$ZABBIX_CONFIG" "$ZABBIX_CONFIG.bak"

HOSTNAME=$(hostname)

sed -i "s|^Server=.*|Server=zabbix.tietokettu.net|" "$ZABBIX_CONFIG"
sed -i "s|^ServerActive=.*|ServerActive=zabbix.tietokettu.net|" "$ZABBIX_CONFIG"
sed -i "s|^Hostname=.*|Hostname=${HOSTNAME}|" "$ZABBIX_CONFIG"

echo "[INFO] Enabling and starting Zabbix agent2..."
systemctl enable --now zabbix-agent2

echo "[SUCCESS] Zabbix Agent 2 installed and configured for host: $HOSTNAME"
