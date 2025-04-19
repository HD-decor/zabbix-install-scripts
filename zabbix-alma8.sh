#!/bin/bash

# Exit on error
set -e

# Get system hostname
HOSTNAME=$(hostname)

echo "[INFO] Installing Zabbix repository..."
rpm -Uvh https://repo.zabbix.com/zabbix/7.2/release/alma/8/noarch/zabbix-release-latest-7.2.el8.noarch.rpm

echo "[INFO] Cleaning dnf cache..."
dnf clean all

echo "[INFO] Installing Zabbix agent2 and plugins..."
dnf install -y zabbix-agent2 \
               zabbix-agent2-plugin-mongodb \
               zabbix-agent2-plugin-mssql \
               zabbix-agent2-plugin-postgresql

echo "[INFO] Configuring Zabbix agent..."
ZABBIX_CONFIG="/etc/zabbix/zabbix_agent2.conf"

# Backup original config
cp $ZABBIX_CONFIG ${ZABBIX_CONFIG}.bak

# Replace Server and Hostname entries
sed -i "s|^Server=.*|Server=zabbix.tietokettu.net|" $ZABBIX_CONFIG
sed -i "s|^ServerActive=.*|ServerActive=zabbix.tietokettu.net|" $ZABBIX_CONFIG
sed -i "s|^Hostname=.*|Hostname=${HOSTNAME}|" $ZABBIX_CONFIG

echo "[INFO] Enabling and starting Zabbix agent2..."
systemctl enable --now zabbix-agent2

echo "[SUCCESS] Zabbix Agent 2 installed and configured for $HOSTNAME."
