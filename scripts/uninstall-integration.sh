#!/usr/bin/env bash
# Remove only OpenModLinux desktop integration. Vortex and the Wine prefix stay intact.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
APPLICATIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_FILE="$APPLICATIONS_DIR/openmodlinux-vortex-nxm.desktop"

rm -f -- "$DESKTOP_FILE"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
fi
printf 'Removed OpenModLinux NXM desktop integration.\n'
printf 'Integration scripts remain at: %s\n' "$SCRIPT_DIR"
