#!/bin/bash

set -e

USERNAME=deployer

# Create user only if it does not already exist
if ! id -u "$USERNAME" > /dev/null 2>&1; then
  adduser --disabled-password --gecos "" $USERNAME
  usermod -aG sudo $USERNAME
fi

# Grant passwordless sudo
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"
if ! grep -q "^$USERNAME ALL=.*NOPASSWD:ALL" "$SUDOERS_FILE" 2>/dev/null; then
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
  chmod 0440 "$SUDOERS_FILE"
fi

# Copy SSH keys from root only if they exist and not already copied
if [ -f /root/.ssh/authorized_keys ]; then
  mkdir -p /home/$USERNAME/.ssh
  cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh/
  chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
  chmod 700 /home/$USERNAME/.ssh
  chmod 600 /home/$USERNAME/.ssh/authorized_keys
fi

# Harden SSH config
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# UFW firewall setup
apt update && apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable

# Install fail2ban if not already installed
if ! command -v fail2ban-client &> /dev/null; then
  apt install -y fail2ban
fi

# Enable and start the fail2ban service
systemctl enable --now fail2ban

# Create an SSH jail if none exists
JAIL_CONF="/etc/fail2ban/jail.d/sshd.conf"
if [ ! -f "$JAIL_CONF" ]; then
  cat << 'EOF' > "$JAIL_CONF"
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 5
EOF
  systemctl restart fail2ban
fi

# Enable auto security updates
apt install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades
