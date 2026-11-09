#!/bin/bash
# Mount iPod and refresh Finder device discovery on macOS Tahoe.
set -u
printf '\n=== Mount iPod (updated) ===\n\n'
PARTITIONS=$(diskutil list | awk '/DOS_FAT_32[[:space:]]+FIXEL IPOD[[:space:]]/ {print $NF}')
COUNT=$(printf '%s\n' "$PARTITIONS" | sed '/^$/d' | wc -l | tr -d ' ')
if [ "$COUNT" -ne 1 ]; then
  echo "Expected one FAT32 partition named FIXEL IPOD; found $COUNT."
  diskutil list
  read -r -p 'Press Return to close...' _
  exit 1
fi
DEVICE="/dev/$PARTITIONS"
echo "Detected $DEVICE"
MOUNTPOINT='/Volumes/IPOD_RECOVERY'
CURRENT=$(diskutil info "$DEVICE" | awk -F: '/Mount Point:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
if [ -n "$CURRENT" ] && [ "$CURRENT" != 'Not applicable (not mounted)' ]; then
  echo "Already mounted at $CURRENT"
else
  echo 'Mounting (administrator password may be requested)...'
  if ! sudo mkdir -p "$MOUNTPOINT" || ! sudo /sbin/mount_msdos "$DEVICE" "$MOUNTPOINT"; then
    echo 'Mount failed; no discovery services were restarted.'
    read -r -p 'Press Return to close...' _
    exit 1
  fi
fi
if ! mount | grep -Fq "$DEVICE on "; then
  echo 'Could not verify the mount; stopping.'
  read -r -p 'Press Return to close...' _
  exit 1
fi
printf '\nMounted. Waiting 8 seconds for iPod/USB discovery to settle...\n'
sleep 8
printf 'Restarting Apple media-device discovery agents...\n'
killall AMPDeviceDiscoveryAgent 2>/dev/null || true
killall AMPDevicesAgent 2>/dev/null || true
printf 'Waiting 8 seconds for discovery agents to relaunch...\n'
sleep 8
printf 'Refreshing Finder...\n'
killall Finder 2>/dev/null || true
sleep 5
open -a Finder
printf '\nFinished. Check Finder > Locations for both IPOD_RECOVERY and the iPod sync device.\n'
printf 'If sync is missing, run these manually:\n'
printf '  killall AMPDeviceDiscoveryAgent 2>/dev/null\n  killall AMPDevicesAgent 2>/dev/null\n  killall Finder\n'
printf '\nEject the iPod before unplugging it.\n\n'
read -r -p 'Press Return to close this window...' _
