#!/bin/bash
set -euo pipefail

if [ "$(id -u)" = 0 ]; then
  chown -R twgs:twgs /data
  exec setpriv --reuid=twgs --regid=twgs --init-groups "$0" "$@"
fi

export HOME=/home/twgs DISPLAY=:1 WINEDEBUG=-all WINEARCH=win32 WINEPREFIX=/data/wine

TWGS_VERSION=${TWGS_VERSION^^}
STATE=/data/state
TWGS_DIR="$WINEPREFIX/drive_c/Program Files/EIS/TWGS"
CONFIG_KEY='HKLM\Software\Epic Interactive Strategy\Trade Wars 2002 Game Server\Configuration'
GAME_PORT=2002
STOP_FLAG=/tmp/twgs-stopping

log() { echo "[twgs] $*" >&2; }
die() { echo "[twgs] ERROR: $*" >&2; exit 1; }

random_password() { head -c 256 /dev/urandom | tr -dc 'A-Za-z0-9' | cut -c1-8; }

set_config() { wine reg add "$CONFIG_KEY" /v "$1" /t REG_SZ /d "$2" /f >/dev/null; }

# True when version $1 sorts strictly before version $2 (219 < 220 < 220B).
is_older() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

vnc_password() {
  if [ -n "${VNC_PASSWORD:-}" ]; then
    printf '%s' "$VNC_PASSWORD"
  elif [ -s "$STATE/vnc_password" ]; then
    cat "$STATE/vnc_password"
  else
    local generated
    generated=$(random_password)
    (umask 077; printf '%s' "$generated" > "$STATE/vnc_password")
    log "Generated web UI password: $generated"
    printf '%s' "$generated"
  fi
}

start_display() {
  rm -f /tmp/.X1-lock
  Xvfb :1 -screen 0 1024x768x24 -nolisten tcp &
  PIDS+=($!)
  sleep 1
  openbox >/dev/null 2>&1 &
  PIDS+=($!)

  local password rfbauth=/tmp/vnc.auth
  password=$(vnc_password)
  [ "${#password}" -le 8 ] || log "VNC only uses the first 8 characters of VNC_PASSWORD"
  x11vnc -storepasswd "$password" "$rfbauth" >/dev/null 2>&1
  x11vnc -display :1 -localhost -forever -shared -noxdamage -rfbauth "$rfbauth" -rfbport 5900 -q >/dev/null 2>&1 &
  PIDS+=($!)
  websockify --web=/usr/share/novnc 6080 127.0.0.1:5900 >/dev/null 2>&1 &
  PIDS+=($!)
  log "Web UI listening on port 6080"
}

# The 2.20 installers are 7-Zip wrappers around setup.exe; 2.19 is the setup itself.
run_installer() {
  local exe=$1 work
  work=$(mktemp -d)
  if 7z l "$exe" 2>/dev/null | grep -q ' setup\.exe$'; then
    7z x -y -o"$work" "$exe" >/dev/null
    exe="$work/setup.exe"
  fi
  (cd "$work" && timeout 300 wine "$exe" /s /v"/qn") || die "installer failed for $TWGS_VERSION"
  wineserver -w
  rm -rf "$work"
  [ -f "$TWGS_DIR/twgs.exe" ] || die "installer finished but twgs.exe is missing"
}

install_or_upgrade() {
  local installed="" installer admin_password
  [ -s "$STATE/version" ] && installed=$(cat "$STATE/version")

  if [ "$installed" = "$TWGS_VERSION" ]; then
    log "TWGS $installed already installed"
    return
  fi
  if [ -n "$installed" ] && is_older "$TWGS_VERSION" "$installed"; then
    die "refusing to downgrade from $installed to $TWGS_VERSION; restore a backup instead (see README)"
  fi

  [ "${TWGS_ACCEPT_LICENSE:-no}" = "yes" ] || die "set TWGS_ACCEPT_LICENSE=yes to accept the TWGS license and install (see README)"
  installer=$(find /installers -maxdepth 1 -type f -iname "TWGS${TWGS_VERSION}.exe" -print -quit 2>/dev/null || true)
  [ -n "$installer" ] || die "no installer named TWGS${TWGS_VERSION}.exe found in /installers"

  if [ ! -f "$WINEPREFIX/system.reg" ]; then
    log "Initialising Wine prefix"
    wineboot -i >/dev/null 2>&1
    wineserver -w
  fi

  if [ -n "$installed" ]; then
    log "Upgrading TWGS $installed to $TWGS_VERSION"
    twgs-backup "pre-upgrade-${installed}-to-${TWGS_VERSION}"
    run_installer "$installer"
  else
    log "Installing TWGS $TWGS_VERSION"
    run_installer "$installer"
    # First install only, so later changes made in the UI are kept.
    admin_password=${TWGS_ADMIN_PASSWORD:-}
    if [ -z "$admin_password" ]; then
      admin_password=$(random_password)
      log "Generated TWGS admin password: $admin_password"
    fi
    set_config Port "$GAME_PORT"
    set_config AdminPassword "$admin_password"
    wineserver -w
  fi
  echo "$TWGS_VERSION" > "$STATE/version"
}

# After an upgrade TWGS blocks startup on this prompt. Answer with its default, Backup.
answer_backup_prompt() {
  local window
  while sleep 2; do
    window=$(xdotool search --onlyvisible --name '^Backup existing games$' 2>/dev/null | head -n1 || true)
    if [ -n "$window" ]; then
      log "Answering TWGS backup prompt"
      xdotool windowactivate --sync "$window" 2>/dev/null || true
      xdotool key --window "$window" Return 2>/dev/null || true
      sleep 15
    fi
  done
}

run_twgs() {
  cd "$TWGS_DIR"
  while [ ! -e "$STOP_FLAG" ]; do
    log "Starting TWGS"
    wine twgs.exe >/dev/null 2>&1 || true
    wineserver -w || true
    sleep 3
  done
}

shutdown() {
  trap - TERM INT
  log "Stopping TWGS"
  touch "$STOP_FLAG"
  # Help and prompt windows are modal and would stop the main window closing.
  { wmctrl -l 2>/dev/null | awk '!/TradeWars Game Server$/ {print $1}' | xargs -r -n1 wmctrl -ic; } || true
  sleep 1
  wmctrl -c 'TradeWars Game Server' 2>/dev/null || true
  for _ in $(seq 1 20); do
    pgrep -f 'twgs\.exe' >/dev/null || break
    sleep 1
  done
  # wineserver writes the registry, which holds the TWGS config, as it exits.
  wineserver -k 2>/dev/null || true
  wineserver -w 2>/dev/null || true
  kill "${PIDS[@]}" 2>/dev/null || true
  exit "${1:-0}"
}

PIDS=()
rm -f "$STOP_FLAG"
mkdir -p "$STATE" /data/backups
trap 'shutdown 0' TERM INT

start_display
install_or_upgrade

answer_backup_prompt &
PIDS+=($!)
run_twgs &
PIDS+=($!)

status=0
wait -n "${PIDS[@]}" || status=$?
log "A required process exited unexpectedly (status $status)"
shutdown 1
