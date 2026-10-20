#!/usr/bin/env bash
# Disconnect the wg-home WireGuard tunnel
set -e
if ip link show wg-home >/dev/null 2>&1; then
  sudo wg-quick down wg-home
  echo "wg-home disconnected"
else
  echo "wg-home is not up"
fi
