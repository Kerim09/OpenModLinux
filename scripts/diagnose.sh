#!/usr/bin/env bash
# Print a non-destructive diagnostic report.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

PREFIX="${1:-${VORTEX_PREFIX:-}}"

value_or_missing() {
    local value="$1"
    [[ -n "$value" ]] && printf '%s' "$value" || printf 'not detected'
}

os_name=""
os_version=""
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    os_name="${PRETTY_NAME:-${NAME:-}}"
    os_version="${VERSION_ID:-}"
fi

session="${XDG_SESSION_TYPE:-unknown}"
desktop="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
kernel="$(uname -srmo 2>/dev/null || true)"
lutris="$(command -v lutris 2>/dev/null || true)"
wine="$(command -v wine 2>/dev/null || true)"
python="$(command -v python3 2>/dev/null || true)"
steam="$(command -v steam 2>/dev/null || true)"

printf '%s\n' '========================================'
printf '%s\n' 'OpenModLinux diagnostics'
printf '%s\n' '========================================'
printf 'Version       : %s\n' "$OML_VERSION"
printf 'Distribution  : %s\n' "$(value_or_missing "$os_name")"
printf 'Version ID    : %s\n' "$(value_or_missing "$os_version")"
printf 'Kernel        : %s\n' "$(value_or_missing "$kernel")"
printf 'Desktop       : %s\n' "$desktop"
printf 'Session       : %s\n' "$session"
printf 'Lutris        : %s\n' "$(value_or_missing "$lutris")"
printf 'System Wine   : %s\n' "$(value_or_missing "$wine")"
printf 'Python        : %s\n' "$(value_or_missing "$python")"
printf 'Steam command : %s\n' "$(value_or_missing "$steam")"

if command -v lspci >/dev/null 2>&1; then
    gpu="$(lspci 2>/dev/null | grep -Ei 'VGA|3D|Display' | paste -sd ';' - || true)"
    printf 'GPU           : %s\n' "$(value_or_missing "$gpu")"
fi

if command -v vulkaninfo >/dev/null 2>&1; then
    if vulkaninfo --summary >/dev/null 2>&1; then
        printf 'Vulkan        : available\n'
    else
        printf 'Vulkan        : command exists but probe failed\n'
    fi
else
    printf 'Vulkan        : vulkaninfo not installed\n'
fi

if [[ -n "$PREFIX" ]]; then
    PREFIX="$(oml_realpath "$PREFIX")"
    printf 'Prefix        : %s\n' "$PREFIX"
    printf 'Prefix drive_c: %s\n' "$([[ -d "$PREFIX/drive_c" ]] && echo present || echo missing)"
    vortex_exe="$PREFIX/drive_c/Program Files/Black Tree Gaming Ltd/Vortex/Vortex.exe"
    printf 'Vortex.exe    : %s\n' "$([[ -f "$vortex_exe" ]] && echo present || echo missing)"
    printf 'Integration   : %s\n' "$([[ -d "$PREFIX/openmodlinux" ]] && echo present || echo missing)"
    if [[ -x "$SCRIPT_DIR/steam-libraries.py" ]] && command -v python3 >/dev/null 2>&1; then
        app_count="$(python3 "$SCRIPT_DIR/steam-libraries.py" | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("apps", [])))')"
        printf 'Steam games   : %s detected\n' "$app_count"
    fi
fi
