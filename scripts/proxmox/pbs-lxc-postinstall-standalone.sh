#!/usr/bin/env bash


# NOTE: Standalone version of: https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pbs-install

set -euo pipefail
shopt -s nullglob

log(){ printf "[*] %s\n" "$*"; }
ok(){ printf "[+] %s\n" "$*"; }
err(){ printf "[-] %s\n" "$*" >&2; }

[[ $EUID -eq 0 ]] || { err "Run as root (use sudo)."; exit 1; }

if command -v pveversion >/dev/null 2>&1; then
  err "PVE detected. This is for PBS."
  exit 1
fi

CODENAME="$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release)"
[[ -n "${CODENAME:-}" ]] || { err "Could not detect Debian codename."; exit 1; }
[[ "$CODENAME" == "trixie" ]] || { err "This script is only for Debian 13 (trixie). Detected: $CODENAME"; exit 1; }

repo_state_list() {
  local repo="$1" f state="missing" file=""
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
    [[ -f "$f" ]] || continue
    if grep -q "$repo" "$f"; then
      file="$f"
      if grep -qE "^[^#].*${repo}" "$f"; then state="active"
      elif grep -qE "^#.*${repo}" "$f"; then state="disabled"; fi
      break
    fi
  done
  echo "$state $file"
}

component_exists_in_sources() {
  local component="$1"
  grep -h -E "^[^#]*Components:[^#]*\b${component}\b" /etc/apt/sources.list.d/*.sources 2>/dev/null | grep -q .
}

setup_trixie() {
  log "Configuring PBS 4.x (trixie)"
  rm -f /etc/apt/sources.list.d/*.list
  sed -i '/proxmox/d;/bookworm/d' /etc/apt/sources.list || true

  cat >/etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian/
Suites: trixie trixie-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
  ok "Debian deb822 sources set"

  if component_exists_in_sources "pbs-enterprise"; then
    if grep -q "^Enabled:" /etc/apt/sources.list.d/pbs-enterprise.sources 2>/dev/null; then
      sed -i 's/^Enabled:.*/Enabled: false/' /etc/apt/sources.list.d/pbs-enterprise.sources
    else
      echo "Enabled: false" >>/etc/apt/sources.list.d/pbs-enterprise.sources
    fi
    ok "Disabled pbs-enterprise"
  else
    cat >/etc/apt/sources.list.d/pbs-enterprise.sources <<'EOF'
Types: deb
URIs: https://enterprise.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF
    ok "Added disabled pbs-enterprise"
  fi

  if ! component_exists_in_sources "pbs-no-subscription"; then
    cat >/etc/apt/sources.list.d/proxmox.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    ok "Added pbs-no-subscription"
  else
    ok "pbs-no-subscription already present"
  fi

  if ! component_exists_in_sources "pbs-test"; then
    cat >/etc/apt/sources.list.d/pbs-test.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-test
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF
    ok "Added disabled pbs-test"
  else
    ok "pbs-test already present"
  fi
}

disable_nag() {
  log "Disabling subscription nag"
  cat >/etc/apt/apt.conf.d/no-nag-script <<'EOF'
DPkg::Post-Invoke { "if [ -s /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ] && ! grep -q -F 'NoMoreNagging' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; then sed -i '/data\.status/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; fi"; };
EOF
  apt --reinstall install -y proxmox-widget-toolkit >/dev/null 2>&1 || err "Widget toolkit reinstall failed"
  ok "Nag disabled"
}

safe_upgrade() {
  log "Running apt update/upgrade"
  apt update

  if systemd-detect-virt --container >/dev/null 2>&1; then
    if apt list --upgradable 2>/dev/null | grep -q '^ifupdown2/'; then
      log "LXC detected: holding ifupdown2 to avoid network break after reboot"
      apt-mark hold ifupdown2 >/dev/null || true
    fi
  fi

  DEBIAN_FRONTEND=noninteractive apt -y upgrade
  ok "System upgraded"
}

setup_trixie
disable_nag

safe_upgrade

ok "Completed PBS post-install routine"
