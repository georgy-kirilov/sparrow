#!/bin/bash
set -e

# 1) Install ufw if missing
if ! command -v ufw &>/dev/null; then
  sudo apt-get update
  sudo apt-get install -y ufw
fi

# 2) Configure rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443

# 3) Enable
sudo ufw --force enable
