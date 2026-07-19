#!/usr/bin/env bash
# Build a synthetic Windows Steam installation inside the Vortex Wine prefix.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

PREFIX="${1:-${VORTEX_PREFIX:-}}"
[[ -n "$PREFIX" ]] || oml_die "Usage: $0 /path/to/vortex-prefix"
PREFIX="$(oml_realpath "$PREFIX")"
[[ -d "$PREFIX" ]] || oml_die "Wine prefix does not exist: $PREFIX"

OML_DIR="$PREFIX/openmodlinux"
OML_LOG_FILE="$OML_DIR/logs/sync-steam.log"
DISCOVERY_JSON="$OML_DIR/steam-discovery.json"
STEAM_WIN_ROOT="$PREFIX/drive_c/Program Files (x86)/Steam"
STEAMAPPS="$STEAM_WIN_ROOT/steamapps"
COMMON_DIR="$STEAMAPPS/common"
MANIFEST_DIR="$STEAMAPPS"

oml_require python3 ln mkdir rm
mkdir -p "$COMMON_DIR" "$OML_DIR/logs"

oml_info "Discovering Steam libraries"
python3 "$SCRIPT_DIR/steam-libraries.py" --pretty >"$DISCOVERY_JSON"

mapfile -t APP_ROWS < <(
    python3 - "$DISCOVERY_JSON" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as stream:
    data = json.load(stream)
for app in data.get("apps", []):
    fields = [app.get("appid", ""), app.get("install_dir", ""), app.get("manifest", ""), app.get("library", "")]
    print("\x1f".join(str(value).replace("\n", " ") for value in fields))
PY
)

linked=0
skipped=0
for row in "${APP_ROWS[@]:-}"; do
    [[ -n "$row" ]] || continue
    IFS=$'\x1f' read -r appid install_dir manifest library <<<"$row"
    game_source="$library/steamapps/common/$install_dir"
    game_target="$COMMON_DIR/$install_dir"
    manifest_target="$MANIFEST_DIR/appmanifest_${appid}.acf"

    if [[ ! -d "$game_source" || ! -f "$manifest" ]]; then
        oml_warn "Skipping incomplete Steam app $appid ($install_dir)"
        ((skipped += 1))
        continue
    fi

    if oml_safe_link "$game_source" "$game_target" && oml_safe_link "$manifest" "$manifest_target"; then
        oml_info "Linked Steam app $appid: $install_dir"
        ((linked += 1))
    else
        ((skipped += 1))
    fi
done

# Vortex and other Windows tools commonly look for this executable. It does not
# need to be runnable for detection, but a regular file is safer than a broken link.
if [[ ! -e "$STEAM_WIN_ROOT/Steam.exe" ]]; then
    : >"$STEAM_WIN_ROOT/Steam.exe"
fi

# The synthetic tree intentionally presents all installed games as one library.
cat >"$STEAMAPPS/libraryfolders.vdf" <<'VDF'
"libraryfolders"
{
    "0"
    {
        "path" "C:\\Program Files (x86)\\Steam"
        "label" "OpenModLinux synthetic library"
    }
}
VDF

oml_info "Steam synchronization complete: linked=$linked skipped=$skipped"
printf 'linked=%d\nskipped=%d\ndiscovery=%s\n' "$linked" "$skipped" "$DISCOVERY_JSON"
