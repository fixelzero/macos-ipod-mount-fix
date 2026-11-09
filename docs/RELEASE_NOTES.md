# Release notes

## v1.0 — Confirmed manual workaround

- Detects one FAT32 partition named `FIXEL IPOD`.
- Uses direct `mount_msdos` rather than the macOS Disk Arbitration FSKit mounting path.
- Waits 8 seconds, refreshes Apple media discovery agents, waits another 8 seconds, and restarts Finder.
- Confirmed by the original tester to show both the mounted storage volume and Finder sync options, with music syncing successfully.

### Known limitations

- Requires administrator authentication for mounting.
- Does not fix native automatic mounting.
- Detection is tailored to a specific partition label.
- The experimental launchd auto-mount helper is not part of the confirmed release.
