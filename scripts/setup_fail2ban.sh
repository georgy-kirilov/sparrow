#!/bin/bash
set -e

# 1) Install fail2ban
if ! command -v fail2ban-client &>/dev/null; then
  sudo apt-get update
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository -y universe
  sudo apt-get update
  sudo apt-get install -y fail2ban
fi

# 2) Enable & start on boot
sudo systemctl enable --now fail2ban

# 3) SSH jail
JAIL_CONF="/etc/fail2ban/jail.d/sshd.conf"
if [ ! -f "$JAIL_CONF" ]; then
  sudo tee "$JAIL_CONF" > /dev/null << 'EOF'
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 5
EOF
  sudo systemctl restart fail2ban
fi
