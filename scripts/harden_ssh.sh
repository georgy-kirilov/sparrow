#!/usr/bin/env bash
set -euo pipefail

USERNAME=deployer

# 0) Disable any automatic apt jobs
sudo systemctl stop      \
    apt-daily.service     \
    apt-daily.timer       \
    apt-daily-upgrade.service \
    apt-daily-upgrade.timer \
  || true
sudo systemctl disable   \
    apt-daily.service     \
    apt-daily.timer       \
    apt-daily-upgrade.service \
    apt-daily-upgrade.timer \
  || true

# 1) Wait for any apt/dpkg lock
wait_for_apt() {
  local locks=(
    /var/lib/dpkg/lock
    /var/lib/dpkg/lock-frontend
    /var/lib/apt/lists/lock
    /var/cache/apt/archives/lock
  )
  while sudo fuser "${locks[@]}" &>/dev/null; do
    echo "⚙️  Waiting for apt lock to be released…"
    sleep 3
  done
}
wait_for_apt

# 2) Create deployer user if missing, add to sudo
if ! id -u "$USERNAME" &>/dev/null; then
  sudo adduser --disabled-password --gecos "" "$USERNAME"
  sudo usermod -aG sudo "$USERNAME"
fi

# 3) Grant passwordless sudo
SUDOERS="/etc/sudoers.d/$USERNAME"
if ! sudo grep -q "^$USERNAME ALL=.*NOPASSWD:ALL" "$SUDOERS" 2>/dev/null; then
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS"
  sudo chmod 0440 "$SUDOERS"
fi

# 4) Copy root’s SSH keys if present
if [ -f /root/.ssh/authorized_keys ]; then
  sudo install -o "$USERNAME" -g "$USERNAME" -m 0700 -d /home/"$USERNAME"/.ssh
  sudo cp /root/.ssh/authorized_keys /home/"$USERNAME"/.ssh/
  sudo chmod 600 /home/"$USERNAME"/.ssh/authorized_keys
fi

# 5) Harden SSH config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 6) Enable auto security updates
wait_for_apt
sudo apt-get update
wait_for_apt
sudo apt-get install -y unattended-upgrades
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive unattended-upgrades
