#!/bin/bash
set -e

# 0) Wait for any apt lock
wait_for_apt() {
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
     || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "⚙️  Waiting for apt lock to be released…"
    sleep 3
  done
}
wait_for_apt

# 1) Install ufw if missing
if ! command -v ufw &>/dev/null; then
  sudo apt-get update
  sudo apt-get install -y ufw
fi

# 2) Configure defaults and rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443

# 3) Enable non-interactively
sudo ufw --force enable
