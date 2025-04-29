#!/usr/bin/env bash
set -euo pipefail

# Disable any automatic apt jobs
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

# Wait for any apt/dpkg lock to go away
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

# Install ufw if missing
if ! command -v ufw &>/dev/null; then
  wait_for_apt
  sudo apt-get update
  wait_for_apt
  sudo apt-get install -y ufw
fi

# Configure defaults and rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443

# Enable without prompt
sudo ufw --force enable
