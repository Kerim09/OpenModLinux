# Design

## Scope

OpenModLinux is an installer and integration layer. Vortex remains the mod
manager and is installed from the official Nexus Mods GitHub release.

## Synthetic Steam installation

Vortex runs inside a dedicated Wine prefix. Native Steam games live outside that
prefix. `sync-steam.sh` creates this view:

```text
C:\\Program Files (x86)\\Steam\\steamapps\\
├── appmanifest_*.acf -> native manifests
├── common\\Game Name -> native game directories
└── libraryfolders.vdf (generated)
```

Windows software therefore sees conventional Steam paths while Linux keeps the
actual game files in their original libraries. Existing non-symlink paths are
never overwritten.

## NXM handler

The desktop handler launches the exact Wine binary selected by Lutris at install
time. It does not edit Lutris' SQLite database or mutate Lutris YAML configuration
for every URL. State is stored in shell-escaped form under
`<prefix>/openmodlinux/state.env` with mode 0600.

## Idempotency

Steam synchronization and URL-handler registration can be repeated. Existing
correct symlinks are retained, stale OpenModLinux symlinks are replaced, and
unrelated real files/directories are not overwritten.
