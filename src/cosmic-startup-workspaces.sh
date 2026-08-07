#!/usr/bin/env bash
#
# cosmic-startup-workspaces.sh — launch programs at login, each on its own
# workspace, under COSMIC (Pop!_OS 24.04, Wayland).
#
# Requires: cos-cli   https://github.com/estin/cos-cli
#             cargo install --git https://github.com/estin/cos-cli
#           jq        (optional, only for the pre-flight workspace check)
#
# Installed and autostarted by run/install — see README.md. To run it
# standalone:
#
#   ./cosmic-startup-workspaces.sh            # launch everything
#   ./cosmic-startup-workspaces.sh --dry-run  # print what would happen
#
set -uo pipefail

# ─────────────────────────────────────────────────────────────
# CONFIG
#
# The app list is not hardcoded here — it's version-controlled at
# src/environment.d/cosmic-startup-workspaces.conf and installed by
# run/install to ~/.config/environment.d/cosmic-startup-workspaces.conf.
# systemd --user reads that at the start of a login session, which is what
# makes $COSMIC_STARTUP_APPS available to autostart apps (shell rc files
# like ~/.bashrc are NOT sourced by autostart, so don't set it there).
#
# Format: one entry per app, entries separated by ";", fields within an
# entry separated by "|":
#
#   <workspace>|<command to run>|<app-id>[;<workspace>|<command>|<app-id>...]
#
#   workspace  1-based workspace number (converted to cos-cli's
#              0-based index internally)
#   command    exactly what you'd type in a terminal
#   app-id     Wayland app_id, matched partially & case-insensitively.
#              Find yours by opening the app and running: cos-cli info
# ─────────────────────────────────────────────────────────────

# Seconds cos-cli will wait for each window to appear before giving up.
WINDOW_TIMEOUT=25

# Seconds to pause between launching each app.
LAUNCH_DELAY=1

# Workspace to land on when everything's up (1-based). Set to 0 to skip.
FINAL_WORKSPACE=1

# Seconds to sleep before doing anything. Some COSMIC sessions run autostart
# entries before the compositor/session is fully ready; if launches fail
# intermittently on login but work fine when run by hand, raise this.
STARTUP_DELAY=0

# ─────────────────────────────────────────────────────────────
# Implementation — you shouldn't need to touch anything below.
# ─────────────────────────────────────────────────────────────
# Autostart entries inherit the `systemd --user` session PATH, which is
# hard-set as a plain literal by /etc/environment (symlinked to
# /usr/lib/environment.d/99-environment.conf) and so contains no user-local
# bin dirs. Without this, cos-cli (installed by cargo to ~/.cargo/bin) is
# invisible here and the sanity check below kills the whole run. Prepending
# both dirs also lets the app list use bare command names for anything in
# ~/.local/bin, rather than absolute paths.
PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
die() { log "ERROR: $*"; exit 1; }

# --- No-op if no app list is configured -----------------------------------
#
# Nothing to do without $COSMIC_STARTUP_APPS — treat this as a normal no-op
# (exit 0, one informational log line) rather than an error, since an
# empty/missing config is an expected state (e.g. before run/install has
# been run, or on a machine that intentionally has no startup apps), and
# this script runs unattended from autostart.
if [[ -z "${COSMIC_STARTUP_APPS:-}" ]]; then
  log "\$COSMIC_STARTUP_APPS not set; nothing to do. (Run run/install to" \
      "install ~/.config/environment.d/cosmic-startup-workspaces.conf.)"
  exit 0
fi

IFS=';' read -r -a APPS <<< "${COSMIC_STARTUP_APPS}"

# --- Sanity checks -------------------------------------------------------
command -v cos-cli >/dev/null || die \
  "cos-cli not found. Install: cargo install --git https://github.com/estin/cos-cli"

[[ -n "${WAYLAND_DISPLAY:-}" ]] || die \
  "No WAYLAND_DISPLAY. This must run inside your COSMIC session, not a bare TTY."

# --- Pre-flight: do the target workspaces actually exist? ----------------
#
# COSMIC creates workspaces dynamically, so workspace 4 may not exist yet at
# login. cos-cli can't move a window to a workspace that isn't there. The fix
# is Settings -> Desktop -> Workspaces -> fixed workspace count (or pin your
# workspaces so they survive being empty).
check_workspaces() {
  command -v jq >/dev/null || { log "jq not found; skipping workspace check"; return 0; }

  local have want
  have=$(cos-cli info --json 2>/dev/null \
         | jq '[.workspace_groups[0].workspaces[]] | length' 2>/dev/null) || return 0
  want=0
  for entry in "${APPS[@]}"; do
    IFS='|' read -r ws _ _ <<< "$entry"
    (( ws > want )) && want=$ws
  done

  log "Workspaces available: ${have:-unknown}; highest requested: $want"
  if [[ -n "$have" ]] && (( have < want )); then
    log "WARNING: only $have workspace(s) exist but you asked for $want."
    log "         Set a fixed workspace count in Settings > Desktop > Workspaces,"
    log "         or pin your workspaces so they persist while empty."
  fi
}

# --- Launch one app and park it -------------------------------------------
launch() {
  local ws="$1" cmd="$2" app_id="$3"
  local target=$((ws - 1))   # cos-cli workspace indices are 0-based

  if (( DRY_RUN )); then
    log "DRY RUN: '$cmd' -> workspace $ws (app-id match: '$app_id')"
    return 0
  fi

  log "Launching '$cmd' -> workspace $ws"
  setsid $cmd >/dev/null 2>&1 &

  # --wait polls the compositor for a matching app_id, so we don't need our
  # own sleep-and-poll loop. It only works alongside --app-id, not --index.
  if cos-cli move --app-id "$app_id" --workspace "$target" --wait "$WINDOW_TIMEOUT"; then
    log "  moved '$app_id' to workspace $ws"
  else
    log "  WARNING: could not place '$app_id' (no window within ${WINDOW_TIMEOUT}s?)"
  fi
}

# --- Main -----------------------------------------------------------------
main() {
  (( STARTUP_DELAY > 0 )) && { log "Sleeping ${STARTUP_DELAY}s before startup..."; sleep "$STARTUP_DELAY"; }

  log "Using APPS from \$COSMIC_STARTUP_APPS (${#APPS[@]} entries)"

  check_workspaces

  for entry in "${APPS[@]}"; do
    IFS='|' read -r ws cmd app_id <<< "$entry"
    [[ -z "${ws:-}" || -z "${cmd:-}" || -z "${app_id:-}" ]] && {
      log "Skipping malformed entry: $entry"; continue
    }
    launch "$ws" "$cmd" "$app_id"
    sleep "$LAUNCH_DELAY"
  done

  if (( ! DRY_RUN )) && (( FINAL_WORKSPACE > 0 )); then
    cos-cli ws-activate --workspace $((FINAL_WORKSPACE - 1)) >/dev/null 2>&1
  fi

  log "Done."
}

main "$@"
