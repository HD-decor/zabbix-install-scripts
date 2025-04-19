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

sed -i 's/noble/focal/g' /etc/apt/sources.list.d/zabbix.list

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
