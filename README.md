# iPod Video / Classic Mount & Sync Fix for macOS Tahoe

A practical workaround for an iPod that appears in macOS but fails to mount automatically, or shows a never-ending **Loading** screen instead of Finder's music-sync controls.

**Status:** The manual one-click Terminal launcher has been confirmed working on one iPod Video 5th-generation setup. The background auto-mount helper is **experimental and unverified**. This is not an official Apple or Rockbox project.

## Tested setup

| Component | Setup |
|---|---|
| iPod | iPod Video / 5th generation (5.5-era hardware) |
| Storage | iFlash Quad adapter, single 512 GB microSD card |
| Firmware | Original Apple OS + Rockbox dual boot |
| Mac | MacBook Pro running macOS Tahoe |
| Format | FAT32 (MBR/FDisk partition scheme) |
| Result | Manual mount + Finder discovery refresh restores working music sync |

The script is tailored to a FAT32 partition **named `FIXEL IPOD`**. Other names require editing the script. Compatibility with other iPod generations and macOS versions has not been verified.

## Symptoms

- macOS detects the iPod, but Finder remains on **Loading**.
- macOS may say the iPod appears corrupted and suggest restoring it.
- `diskutil mount /dev/diskXsY` fails, sometimes suggesting `readOnly`.
- Music still plays normally in both Apple OS and Rockbox.
- Direct `mount_msdos` can mount the FAT32 partition, but Finder may still not display the iPod sync interface until device discovery services restart.

**Do not restore or erase the iPod as a first troubleshooting step. Back up music and `iPod_Control/iTunes` before filesystem repairs.**

## Quick start: confirmed working workaround

1. Boot the iPod into the **original Apple firmware**, connect it to the Mac, and wait for USB detection.
2. Download or clone this repository.
3. Open `scripts/Mount iPod.command` from Terminal (or double-click it if macOS allows it).
4. Enter the administrator password when prompted for mounting.
5. Wait roughly 20–30 seconds; look under **Finder → Locations** for the mounted `IPOD_RECOVERY` drive and the separate iPod sync device.
6. Sync normally, then **eject the iPod before unplugging it**.

To run from Terminal:

```bash
bash "scripts/Mount iPod.command"
```

The script runs `sudo /sbin/mount_msdos` only for the identified iPod partition. It does **not** store your password, erase or repartition the disk, edit the iTunes database, or modify Rockbox. It does restart Finder and Apple's media discovery agents, which may briefly interrupt Finder windows or other connected-device views.

### What the launcher actually does

1. Searches `diskutil list` for **exactly one** FAT32 partition named `FIXEL IPOD`.
2. Reads the current device identifier, such as `disk6s2` (the number can change).
3. If not already mounted, mounts it at `/Volumes/IPOD_RECOVERY` using `/sbin/mount_msdos` with administrator privileges.
4. Verifies the mount and waits **8 seconds**.
5. Runs `killall AMPDeviceDiscoveryAgent` and `killall AMPDevicesAgent` (ignoring “not found”).
6. Waits another **8 seconds**, restarts Finder, then opens Finder.

The timing was empirically successful on the tested machine; the 8-second delays are not an Apple-documented requirement.

## Technical diagnosis

The iPod was visible as an external USB disk with a 511.8 GB FAT32 partition. Initial read-only filesystem checks (`fsck_msdos -n`) found **22 orphaned clusters**, an **FSInfo free-space mismatch**, and an inconsistent Spotlight `JOURNAL.1` file. After backing up, a filesystem repair freed the 22 clusters and corrected the free-space count. A subsequent read-only check reported no previous errors.

**The automatic mount failure continued after the FAT32 repair.** macOS Disk Arbitration logs showed:

```text
Found FSModule: msdos_fskit
probed disk ... success
staged fsmodule ... success
failed to activate volume (Error Domain=NSPOSIXErrorDomain Code=60)
unable to mount /dev/disk6s2 (status code 0x00000005)
```

POSIX error **60 (`ETIMEDOUT`)** indicates a timeout during FSKit volume activation. This suggests a problem in the macOS FSKit mounting path or its interaction with the iPod's storage/USB behavior; it **does not establish a universal Tahoe bug**. Direct `mount_msdos` worked on the same partition. Restarting Apple's media-device discovery processes then restored the Finder sync interface.

### Why this is different from `iTunesLock` fixes

Some sync-hang reports describe deleting a stale `iPod_Control/iTunes/iTunesLock` file. That file was **not present** on this iPod. Once Finder recognized the device, actual music syncing worked normally, so there was no evidence of an iTunes database lock problem. **Do not delete database files blindly.**

## Manual recovery commands

First, identify your iPod carefully:

```bash
diskutil list
```

The commands below use `/dev/disk6s2` **as an example only**. Verify the identifier and partition name every time, especially if other external disks are connected.

```bash
sudo mkdir -p /Volumes/IPOD_RECOVERY
sudo /sbin/mount_msdos /dev/disk6s2 /Volumes/IPOD_RECOVERY
sleep 8
killall AMPDeviceDiscoveryAgent 2>/dev/null || true
killall AMPDevicesAgent 2>/dev/null || true
sleep 8
killall Finder 2>/dev/null || true
open -a Finder
```

To eject after syncing:

```bash
diskutil unmount /dev/disk6s2
```

For a non-writing filesystem inspection **only while unmounted**:

```bash
sudo fsck_msdos -n /dev/rdisk6s2
```

**Do not run `fsck_msdos -y` casually.** It modifies filesystem metadata; back up your music and database first, and only repair confirmed errors on the correct unmounted partition.

## Troubleshooting

| Issue | What to check |
|---|---|
| Script finds zero or multiple iPods | Confirm the FAT32 volume is named exactly `FIXEL IPOD`; inspect `diskutil list` |
| `Operation not permitted` | Run the `.command` script in Terminal so `sudo` executes in the expected context; don't disable system protections |
| Volume mounted, sync device missing | Retry the discovery-agent/Finder refresh commands above |
| `diskutil mount` still fails | This was the original problem; direct `mount_msdos` is the workaround |
| Finder syncs normally | No reason to delete `iTunesDB`, create an `iTunesLock`, or reinstall Rockbox |
| iPod shows “Do Not Disconnect” | Eject through Finder or `diskutil unmount` before unplugging |
| Script fails after reconnect | Recheck the device identifier and the iPod's Apple OS / USB connection |

## Rockbox compatibility

Rockbox was preserved throughout troubleshooting. On the tested setup, the reliable Finder workflow was to **boot into Apple's original iPod OS**, connect, run the launcher, sync, and eject. Rockbox can still be used afterward for playback. This project does not install, modify, or remove Rockbox.

## Experimental background auto-mount helper

The `experimental/auto-mount/` directory contains a prototype `launchd`-based background watcher that attempts to recognize the iPod and mount it automatically, plus a separate user agent for Finder refresh. **It has not been confirmed working on the tested Mac and is not recommended as the default installation.** It installs privileged components and requires careful code review before use. Start with the proven manual launcher.

## Safety and limitations

- This is a workaround, not a confirmed fix for the underlying FSKit timeout.
- It has been tested on **one specific iPod/Mac configuration**; your mileage may vary.
- The launcher is tailored to `FIXEL IPOD`; it does not safely generalize to every FAT32 USB disk.
- Finder and device-discovery processes are restarted, which may disrupt other device sessions.
- No disk format, partition changes, Rockbox changes, or iTunes database edits are required by the launcher.
- Always eject before unplugging, and maintain independent backups.

## Project history

1. macOS detected the iPod but would not mount it automatically; Finder stayed on Loading.
2. A read-only `mount_msdos` mount enabled recovery of music and database backups.
3. FAT32 inconsistencies were repaired; the filesystem then checked clean, but automatic mounting still failed.
4. Logs identified an FSKit FAT32 activation timeout (`NSPOSIXErrorDomain Code=60`).
5. Direct read/write `mount_msdos` succeeded; restarting Apple discovery agents and Finder restored sync controls.
6. An initial `.app` launcher encountered `Operation not permitted`.
7. A Terminal `.command` launcher mounted successfully but did not reliably expose the sync interface.
8. The updated launcher added **8-second waits** around discovery refresh and was confirmed working flawlessly.
9. A fully automatic `launchd` prototype was created but remains unverified.

## Contributing

If you reproduce this on another iPod or macOS version, please include the iPod model, storage adapter/card, macOS version, filesystem format, relevant **redacted** `diskutil`/FSKit logs, and whether Finder sync actually succeeds. Never post personal file paths, device serial numbers, or private library contents without reviewing them.

## License

No license has been selected yet. Add a `LICENSE` file before presenting this as an openly licensed project; publishing source code alone does not grant general reuse rights.
