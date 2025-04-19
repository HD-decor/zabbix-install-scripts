#!/bin/bash

set -e

echo "[INFO] Disabling Zabbix packages from EPEL if present..."
EPEL_REPO="/etc/yum.repos.d/epel.repo"
if [ -f "$EPEL_REPO" ]; then
    if ! grep -q "excludepkgs=zabbix*" "$EPEL_REPO"; then
        echo "excludepkgs=zabbix*" >> "$EPEL_REPO"
        echo "[INFO] Added 'excludepkgs=zabbix*' to $EPEL_REPO"
    else
        echo "[INFO] EPEL already excludes Zabbix packages"
    fi
else
    echo "[WARN] EPEL repo not found, skipping exclusion."
fi

echo "[INFO] Installing Zabbix repo for AlmaLinux 9..."
rpm -Uvh https://repo.zabbix.com/zabbix/7.2/release/alma/9/noarch/zabbix-release-latest-7.2.el9.noarch.rpm

echo "[INFO] Cleaning DNF cache..."
dnf clean all

echo "[INFO] Installing Zabbix agent2 and plugins..."
dnf install -y zabbix-agent2 \
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
