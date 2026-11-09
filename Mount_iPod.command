#!/bin/bash
# Mount_iPod.command - Version 4
# Mounts a FAT32 iPod (iFlash/Rockbox setups) on macOS Tahoe with mount_msdos,
# then restarts Apple's device-discovery agents and Finder so the sync page appears.
#
# v4 changes: polls for the discovery agent instead of long fixed sleeps,
# keeps Spotlight/fseventsd off the iPod, configurable LABEL/MOUNTPOINT,
# and pairs with Eject_iPod.command for a clean unmount.
set -u

LABEL='FIXEL IPOD'                  # FAT32 volume label as shown by `diskutil list`
MOUNTPOINT='/Volumes/IPOD_RECOVERY'
SETTLE_SECS=4                       # raise back to 8 if Finder sync is ever flaky

pause_and_exit() {
  read -r -p 'Press Return to close...' _
  exit "${1:-1}"
}

mount_point_of() {
  diskutil info "$1" | awk -F: '/Mount Point:/ {sub(/^[[:space:]]+/, "", $2); print $2}'
}

wait_for_proc() {   # wait_for_proc <process name> <timeout secs>
  local i=0
  while ! pgrep -x "$1" >/dev/null 2>&1; do
    i=$((i + 1))
    [ "$i" -ge "$2" ] && return 1
    sleep 1
  done
  return 0
}

printf '\n=== Mount iPod (v4) ===\n\n'

PARTITIONS=$(diskutil list | awk -v label="$LABEL" '$0 ~ "DOS_FAT_32[[:space:]]+" label "[[:space:]]" {print $NF}')
COUNT=$(printf '%s\n' "$PARTITIONS" | sed '/^$/d' | wc -l | tr -d ' ')
if [ "$COUNT" -ne 1 ]; then
  echo "Expected one FAT32 partition named $LABEL; found $COUNT."
  diskutil list
  pause_and_exit 1
fi

DEVICE="/dev/$PARTITIONS"
echo "Detected $DEVICE"

CURRENT=$(mount_point_of "$DEVICE")
if [ -n "$CURRENT" ] && [ "$CURRENT" != 'Not applicable (not mounted)' ]; then
  echo "Already mounted at $CURRENT"
else
  echo 'Mounting (administrator password may be requested)...'
  if ! sudo mkdir -p "$MOUNTPOINT" || ! sudo /sbin/mount_msdos "$DEVICE" "$MOUNTPOINT"; then
    echo 'Mount failed; no discovery services were restarted.'
    pause_and_exit 1
  fi
fi

if ! mount | grep -Fq "$DEVICE on "; then
  echo 'Could not verify the mount; stopping.'
  pause_and_exit 1
fi

MP=$(mount | awk -v d="$DEVICE" '$1 == d {sub(/^.* on /, ""); sub(/ \(.*$/, ""); print; exit}')
echo "Mounted at: $MP"

# Keep Spotlight and fseventsd from writing to the iPod (the earlier fsck
# flagged a damaged .Spotlight-V100 journal). Safe to repeat every time.
sudo rm -rf "$MP/.Spotlight-V100" 2>/dev/null
sudo touch "$MP/.metadata_never_index" 2>/dev/null
sudo mkdir -p "$MP/.fseventsd" 2>/dev/null && sudo touch "$MP/.fseventsd/no_log" 2>/dev/null

printf '\nWaiting %s seconds for USB/iPod discovery to settle...\n' "$SETTLE_SECS"
sleep "$SETTLE_SECS"

printf 'Restarting Apple media-device discovery agents...\n'
killall AMPDeviceDiscoveryAgent 2>/dev/null || true
killall AMPDevicesAgent 2>/dev/null || true
sleep 1
if wait_for_proc AMPDeviceDiscoveryAgent 15; then
  echo 'Discovery agent is back up.'
  sleep 2
else
  echo 'Discovery agent did not report back within 15s; continuing anyway.'
fi

printf 'Refreshing Finder...\n'
killall Finder 2>/dev/null || true
sleep 2
open -a Finder

printf '\nFinished. Check Finder > Locations for both IPOD_RECOVERY and the iPod sync device.\n'
printf 'If sync is missing, run these manually:\n'
printf '  killall AMPDeviceDiscoveryAgent 2>/dev/null\n  killall AMPDevicesAgent 2>/dev/null\n  killall Finder\n'
printf '\nWhen done: run Eject_iPod.command before unplugging.\n\n'
pause_and_exit 0
