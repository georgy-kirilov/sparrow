#!/bin/bash

set -e

USERNAME=deployer

# Create user only if it doesn't already exist
if ! id -u "$USERNAME" > /dev/null 2>&1; then
  adduser --disabled-password --gecos "" $USERNAME
  usermod -aG sudo $USERNAME
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

# UFW - firewall setup
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

# Enable auto security updates
apt install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades
