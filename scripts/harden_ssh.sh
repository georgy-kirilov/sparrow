#!/bin/bash
set -e

# 0) Helper: wait for any apt/dpkg lock to be released
wait_for_apt() {
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
     || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Waiting for apt lock to be released…"
    sleep 3
  done
}

# Invoke before any package operations
wait_for_apt

USERNAME=deployer

# 1) Create user if missing
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

# 3) Copy SSH keys
if [ -f /root/.ssh/authorized_keys ]; then
  mkdir -p /home/$USERNAME/.ssh
  cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh/
  chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
  chmod 700 /home/$USERNAME/.ssh
  chmod 600 /home/$USERNAME/.ssh/authorized_keys
fi

# 4) Harden SSH configuration
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# 5) Enable unattended security upgrades without interactive prompts
wait_for_apt
dpkg --purge --force-all unattended-upgrades || true # remove old config if corrupted
debconf-set-selections <<< 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true'
apt-get update
apt-get install -y unattended-upgrades

# Write auto-upgrades config
cat << 'EOF' > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
