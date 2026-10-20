#!/usr/bin/env bash
# WireGuard install (Debian/Ubuntu): install tools, write /etc/wireguard/wg-home.conf
# from CLI base64 of a FULL .conf, emit wg-up.sh / wg-down.sh beside this script.
# No IP addresses, keys, or endpoints are hard-coded in this repository.
#
# Recommended (download then run — keeps $0 so companions land next to the script):
#   curl -fsSL https://raw.githubusercontent.com/devlink123/wg-setup/main/install-wg-home.sh \
#     -o /tmp/install-wg-home.sh \
#     && bash /tmp/install-wg-home.sh "$(base64 -w0 /path/to/wg.conf)" \
#     && /tmp/wg-up.sh
#
# Local:
#   ./install-wg-home.sh '<base64-of-full-conf>'
#   echo '<base64>' | ./install-wg-home.sh -
set -euo pipefail
NAME=wg-home

# Prefer directory of this script file so companions sit beside it (/tmp when downloaded there).
# Fall back to $WG_SETUP_DIR or $HOME/wg-setup only when run via stdin / curl|bash.
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" && -f "${BASH_SOURCE[0]}" ]]; then
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  DIR="${WG_SETUP_DIR:-$HOME/wg-setup}"
  mkdir -p "$DIR"
fi

B64="${1:-}"
if [[ "$B64" == "-h" || "$B64" == "--help" ]]; then
  echo "Usage: $0 '<base64-of-full-wg-conf>' | $0 -" >&2
  echo "  curl -fsSL …/install-wg-home.sh -o /tmp/install-wg-home.sh && bash /tmp/install-wg-home.sh \"\$(base64 -w0 conf)\" && /tmp/wg-up.sh" >&2
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
chmod +x "$DIR/wg-up.sh" "$DIR/wg-down.sh"
echo "Installed. Connect: $DIR/wg-up.sh   Disconnect: $DIR/wg-down.sh"
