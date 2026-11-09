# Changelog

## v4
- Mount: poll for `AMPDeviceDiscoveryAgent` to relaunch (15 s cap) instead of a fixed 8 s wait; initial settle delay reduced to 4 s (`SETTLE_SECS`).
- Mount: delete `.Spotlight-V100`, create `.metadata_never_index` and `.fseventsd/no_log` on every mount, so Spotlight/fseventsd stop writing to the iPod.
- Mount: `LABEL` and `MOUNTPOINT` are variables at the top of the script; shows the actual mount point.
- Mount: removed redundant 5 s sleep after restarting Finder.
- New: `Eject_iPod.command` runs `sync`, then unmounts and ejects the whole disk to avoid dirty-FAT problems (orphan clusters, FSInfo mismatch).

## v3
- Added delays between mounting and restarting discovery agents / Finder.
