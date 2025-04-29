#!/usr/bin/env bash
set -euo pipefail

# stop any automatic apt jobs that might grab the lock later
sudo systemctl stop  \
    apt-daily.service     \
    apt-daily.timer       \
    apt-daily-upgrade.service \
    apt-daily-upgrade.timer \
  || true
sudo systemctl disable \
    apt-daily.service     \
    apt-daily.timer       \
    apt-daily-upgrade.service \
    apt-daily-upgrade.timer \
  || true

# wait until no one is holding any of the apt/dpkg locks
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

# 0) initial wait (in case an apt job was already running)
wait_for_apt

# 1) install fail2ban if missing
if ! command -v fail2ban-client &>/dev/null; then
  wait_for_apt
  sudo apt-get update
  sudo apt-get install -y software-properties-common

  wait_for_apt
  sudo add-apt-repository -y universe

  wait_for_apt
  sudo apt-get update
  sudo apt-get install -y fail2ban
fi

# 2) enable & start on boot
sudo systemctl enable --now fail2ban

# 3) configure SSH jail if missing
JAIL_CONF=/etc/fail2ban/jail.d/sshd.conf
if [[ ! -f $JAIL_CONF ]]; then
  sudo tee "$JAIL_CONF" >/dev/null <<-'EOF'
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 5
EOF
  sudo systemctl restart fail2ban
fi
