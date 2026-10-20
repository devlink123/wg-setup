#!/usr/bin/env bash
# Connect the wg-home WireGuard tunnel (expects /etc/wireguard/wg-home.conf)
set -euo pipefail
if ip link show wg0 >/dev/null 2>&1; then
  echo "Note: bringing down conflicting wg0 before wg-home"
  sudo wg-quick down wg0 2>/dev/null || sudo ip link delete wg0 || true
fi
if ip link show wg-home >/dev/null 2>&1; then
  echo "wg-home is already up"
else
  sudo wg-quick up wg-home
fi
sudo wg show wg-home | sed -E 's/(private key|preshared key):.*/\1: (hidden)/i'
