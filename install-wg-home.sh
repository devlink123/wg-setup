#!/usr/bin/env bash
# WireGuard install (Debian/Ubuntu): install tools, write /etc/wireguard/wg-home.conf
# from CLI base64 of a FULL .conf, sync install + wg-up/down into a fixed dir.
# No IP addresses, keys, or endpoints are hard-coded in this repository.
#
# Install dir is fixed in this script: $HOME/.local/share/wg-setup
#
# From GitHub:
#   curl -fsSL https://raw.githubusercontent.com/devlink123/wg-setup/main/install-wg-home.sh \
#     -o /tmp/install-wg-home.sh \
#     && bash /tmp/install-wg-home.sh 'PASTE_BASE64_HERE' \
#     && ~/.local/share/wg-setup/wg-up.sh
set -euo pipefail
NAME=wg-home
DIR="$HOME/.local/share/wg-setup"
mkdir -p "$DIR"

B64="${1:-}"
if [[ "$B64" == "-h" || "$B64" == "--help" ]]; then
  echo "Usage: $0 '<base64-of-full-wg-conf>' | $0 -" >&2
  echo "Scripts sync to: $DIR" >&2
  exit 1
fi
if [[ "$B64" == "-" || -z "$B64" ]]; then
  B64="$(cat)"
fi
[[ -n "$B64" ]] || { echo "error: missing base64 argument" >&2; exit 1; }
B64="$(printf '%s' "$B64" | tr -d '[:space:]')"

DECODED="$(mktemp)"
trap 'rm -f "$DECODED"' EXIT
if ! printf '%s' "$B64" | base64 -d >"$DECODED" 2>/dev/null; then
  echo "error: base64 decode failed" >&2
  exit 2
fi
if ! grep -qE '^\[Interface\]' "$DECODED"; then
  echo "error: decoded content must be a full WireGuard conf (needs [Interface])" >&2
  exit 3
fi
if ! grep -qE '^\[Peer\]' "$DECODED"; then
  echo "error: conf missing [Peer] section" >&2
  exit 3
fi

need_pkgs=0
command -v wg-quick >/dev/null 2>&1 || need_pkgs=1
command -v ip >/dev/null 2>&1 || need_pkgs=1
command -v ping >/dev/null 2>&1 || need_pkgs=1
if [[ "$need_pkgs" -eq 1 ]]; then
  echo "Installing wireguard-tools / iproute2 / ping…"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard-tools iproute2 iputils-ping
else
  echo "wireguard-tools already present — skip apt"
fi

sudo mkdir -p /etc/wireguard && sudo chmod 700 /etc/wireguard
sudo cp "$DECODED" "/etc/wireguard/$NAME.conf"
sudo chmod 600 "/etc/wireguard/$NAME.conf"
echo "Wrote /etc/wireguard/${NAME}.conf (mode 600)"

if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  cp "$SRC" "$DIR/install-wg-home.sh"
else
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/devlink123/wg-setup/main/install-wg-home.sh \
      -o "$DIR/install-wg-home.sh" || true
  fi
fi

cat > "$DIR/wg-up.sh" <<'UP'
#!/usr/bin/env bash
# Connect the wg-home WireGuard tunnel
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
UP
cat > "$DIR/wg-down.sh" <<'DOWN'
#!/usr/bin/env bash
# Disconnect the wg-home WireGuard tunnel
set -e
if ip link show wg-home >/dev/null 2>&1; then
  sudo wg-quick down wg-home
  echo "wg-home disconnected"
else
  echo "wg-home is not up"
fi
DOWN
chmod +x "$DIR/install-wg-home.sh" "$DIR/wg-up.sh" "$DIR/wg-down.sh"
echo "Synced under $DIR"
echo "  install: $DIR/install-wg-home.sh"
echo "  connect: $DIR/wg-up.sh"
echo "  disconnect: $DIR/wg-down.sh"
