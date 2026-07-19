# Test matrix before Lutris submission

The first release must be tested with a clean Vortex prefix. Reusing an old
prefix can hide missing dependencies.

## Minimum distributions

- Ubuntu or Kubuntu current release, native Lutris package;
- Linux Mint current release;
- Fedora current release;
- Arch Linux or EndeavourOS;
- Steam Deck / SteamOS desktop mode;
- at least one Flatpak Lutris installation, documented separately because its
  filesystem sandbox may require additional permissions.

## GPU/session combinations

- NVIDIA proprietary driver on X11;
- NVIDIA proprietary driver on Wayland;
- AMD Mesa on Wayland;
- Intel Mesa on Wayland or X11.

## Installation checklist

1. `lutris -i lutris/vortex.yml` completes without an unhandled error.
2. Vortex starts a second time from the Lutris Play button.
3. Vortex login works.
4. Native Steam games from the default library are detected.
5. A game on a second Steam library/mount is detected.
6. Flatpak Steam is detected where applicable.
7. Running `openmodlinux/update.sh` twice is safe.
8. Installing another Steam game and rerunning `update.sh` adds it.
9. An `nxm://` browser link opens Vortex and reaches its download flow.
10. The user can still start games normally through native Steam/Proton.
11. Logs contain no passwords, API keys or full NXM authentication query data in
    published bug reports. The local NXM log may contain the received URL and
    must be redacted before sharing.

## Hardlink deployment

Test both a game on the same filesystem as the prefix and a game on another
filesystem. The latter must use a Vortex staging directory on the game's own
filesystem. A cross-filesystem hardlink cannot be made valid by a symbolic link.
