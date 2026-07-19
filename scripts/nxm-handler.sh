#!/usr/bin/env bash
# Runtime handler for nxm:// links.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
STATE_FILE="$SCRIPT_DIR/state.env"

[[ -r "$STATE_FILE" ]] || {
    printf 'OpenModLinux state file is missing: %s\n' "$STATE_FILE" >&2
    exit 1
}

# state.env is created by this project using shell-escaped values only.
# shellcheck disable=SC1090
source "$STATE_FILE"

URL="${1:-}"
case "$URL" in
    nxm://*|nxm-protocol://*) ;;
    *)
        printf 'Refusing unsupported URL: %s\n' "$URL" >&2
        exit 2
        ;;
esac

[[ -d "${VORTEX_PREFIX:-}" ]] || {
    printf 'Vortex prefix is unavailable: %s\n' "${VORTEX_PREFIX:-}" >&2
    exit 3
}
[[ -x "${WINE_BINARY:-}" ]] || {
    printf 'Configured Wine binary is unavailable: %s\n' "${WINE_BINARY:-}" >&2
    exit 4
}
[[ -f "${VORTEX_EXECUTABLE:-}" ]] || {
    printf 'Vortex executable is unavailable: %s\n' "${VORTEX_EXECUTABLE:-}" >&2
    exit 5
}

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
{
    printf '[%s] URL received: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$URL"
    env \
        WINEPREFIX="$VORTEX_PREFIX" \
        WINEDEBUG=-all \
        "$WINE_BINARY" "$VORTEX_EXECUTABLE" -d "$URL"
} >>"$LOG_DIR/nxm-handler.log" 2>&1 &
disown || true
