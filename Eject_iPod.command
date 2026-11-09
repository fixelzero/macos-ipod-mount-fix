#!/bin/bash
# Eject_iPod.command - Version 4
# Cleanly unmounts and ejects the iPod so the FAT32 volume isn't left dirty.
set -u

LABEL='FIXEL IPOD'

pause_and_exit() {
  read -r -p 'Press Return to close...' _
  exit "${1:-1}"
}

printf '\n=== Eject iPod ===\n\n'

PARTITIONS=$(diskutil list | awk -v label="$LABEL" '$0 ~ "DOS_FAT_32[[:space:]]+" label "[[:space:]]" {print $NF}')
COUNT=$(printf '%s\n' "$PARTITIONS" | sed '/^$/d' | wc -l | tr -d ' ')
if [ "$COUNT" -ne 1 ]; then
  echo "Expected one FAT32 partition named $LABEL; found $COUNT. Nothing ejected."
  pause_and_exit 1
fi

DISK=$(printf '%s' "$PARTITIONS" | sed 's/s[0-9][0-9]*$//')
echo "Ejecting /dev/$DISK ..."

sync
if diskutil unmountDisk "/dev/$DISK" && diskutil eject "/dev/$DISK"; then
  printf '\nEjected. Wait for the iPod to show "OK to disconnect" (or its normal menu), then unplug.\n\n'
  pause_and_exit 0
else
  printf '\nEject failed. Close any Finder sync window or apps using the iPod and try again.\n\n'
  pause_and_exit 1
fi
