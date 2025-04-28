#!/bin/bash
set -e

USERNAME=deployer

# 1) Create the user if missing & add to sudo
if ! id -u "$USERNAME" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$USERNAME"
  usermod -aG sudo "$USERNAME"
fi

# 2) Ensure passwordless sudo
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"
if ! grep -q "^$USERNAME ALL=.*NOPASSWD:ALL" "$SUDOERS_FILE" 2>/dev/null; then
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
  chmod 0440 "$SUDOERS_FILE"
fi

# 3) Copy root’s SSH keys
if [ -f /root/.ssh/authorized_keys ]; then
  mkdir -p /home/$USERNAME/.ssh
  cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh/
  chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
  chmod 700 /home/$USERNAME/.ssh
  chmod 600 /home/$USERNAME/.ssh/authorized_keys
fi

# 4) Lock down SSH
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# 5) Auto security updates
apt-get update
apt-get install -y unattended-upgrades
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive unattended-upgrades
