#!/usr/bin/env bash
# Install/update the OpenModLinux integration files in a Vortex prefix.

set -Eeuo pipefail
IFS=$'\n\t'

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=common.sh
source "$SOURCE_DIR/common.sh"

PREFIX="${1:-}"
WINE_BINARY="${2:-}"
[[ -n "$PREFIX" && -n "$WINE_BINARY" ]] || oml_die "Usage: $0 PREFIX WINE_BINARY"
PREFIX="$(oml_realpath "$PREFIX")"
WINE_BINARY="$(oml_realpath "$WINE_BINARY")"
[[ -d "$PREFIX/drive_c" ]] || oml_die "Invalid Wine prefix: $PREFIX"

TARGET_DIR="$PREFIX/openmodlinux"
OML_LOG_FILE="$TARGET_DIR/logs/post-install.log"
mkdir -p "$TARGET_DIR/logs"

files=(
    common.sh
    steam-libraries.py
    sync-steam.sh
    nxm-handler.sh
    install-nxm-handler.sh
    diagnose.sh
    uninstall-integration.sh
)

for file in "${files[@]}"; do
    [[ -f "$SOURCE_DIR/$file" ]] || oml_die "Required integration file missing: $file"
    install -m 0755 "$SOURCE_DIR/$file" "$TARGET_DIR/$file"
done

cat >"$TARGET_DIR/update.sh" <<'EOF_UPDATE'
#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/state.env"
"$SCRIPT_DIR/sync-steam.sh" "$VORTEX_PREFIX"
"$SCRIPT_DIR/install-nxm-handler.sh" "$VORTEX_PREFIX" "$WINE_BINARY"
printf 'OpenModLinux integration updated successfully.\n'
EOF_UPDATE
chmod 0755 "$TARGET_DIR/update.sh"

oml_info "Synchronizing Steam libraries"
"$TARGET_DIR/sync-steam.sh" "$PREFIX"

oml_info "Writing Steam registry keys"
REG_FILE="$TARGET_DIR/steam-path.reg"
cat >"$REG_FILE" <<'EOF_REG'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Valve\Steam]
"SteamPath"="C:\\Program Files (x86)\\Steam"
"SteamExe"="C:\\Program Files (x86)\\Steam\\Steam.exe"
EOF_REG
WINEPREFIX="$PREFIX" WINEDEBUG=-all "$WINE_BINARY" regedit /S "$REG_FILE" >/dev/null 2>&1 || \
    oml_warn "Wine regedit returned an error; Lutris registry tasks may still have configured SteamPath"

oml_info "Installing NXM URL handler"
"$TARGET_DIR/install-nxm-handler.sh" "$PREFIX" "$WINE_BINARY"

oml_info "OpenModLinux integration installed in $TARGET_DIR"
printf '%s\n' "$TARGET_DIR"
