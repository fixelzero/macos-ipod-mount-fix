#!/bin/bash
set -euo pipefail
LABEL='com.fixel.ipod.automount'
AGENT='com.fixel.ipod.finder-refresh'
UID_NOW="$(id -u)"
if [[ "$UID_NOW" == 0 ]]; then echo 'Run as normal Mac user.'; exit 1; fi
launchctl bootout "gui/${UID_NOW}/${AGENT}" 2>/dev/null || true
sudo launchctl bootout "system/${LABEL}" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/${AGENT}.plist" "$HOME/Library/Application Support/Fixel iPod/finder_watch.py"
sudo rm -f "/Library/LaunchDaemons/${LABEL}.plist" /usr/local/libexec/fixel-ipod/mount_watch.py
echo 'Auto-mount helpers removed. iPod contents were not changed.'
read -r -p 'Press Return to close...' _
