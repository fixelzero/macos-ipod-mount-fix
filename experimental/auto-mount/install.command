#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
LABEL='com.fixel.ipod.automount'
AGENT='com.fixel.ipod.finder-refresh'
USER_ID="$(id -u)"
if [[ "$USER_ID" == 0 ]]; then echo 'Run as your normal Mac user, not sudo.'; exit 1; fi
echo 'Installing iPod Auto Mount. Administrator password required for root helper.'
sudo /usr/bin/install -d -m 755 /usr/local/libexec/fixel-ipod
sudo /usr/bin/install -m 755 mount_watch.py /usr/local/libexec/fixel-ipod/mount_watch.py
sudo /usr/bin/install -m 644 "${LABEL}.plist" "/Library/LaunchDaemons/${LABEL}.plist"
sudo /usr/sbin/chown root:wheel "/Library/LaunchDaemons/${LABEL}.plist" /usr/local/libexec/fixel-ipod/mount_watch.py
mkdir -p "$HOME/Library/Application Support/Fixel iPod" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
/usr/bin/install -m 755 finder_watch.py "$HOME/Library/Application Support/Fixel iPod/finder_watch.py"
/usr/bin/python3 - "$PWD/${AGENT}.plist" "$HOME/Library/LaunchAgents/${AGENT}.plist" "$HOME/Library/Application Support/Fixel iPod/finder_watch.py" "$HOME/Library/Logs" <<'PY'
import plistlib,sys
src,dst,script,logs=sys.argv[1:]
with open(src,'rb') as f: p=plistlib.load(f)
p['ProgramArguments']=['/usr/bin/python3',script]
p['StandardOutPath']=logs+'/fixel-ipod-finder.log'
p['StandardErrorPath']=logs+'/fixel-ipod-finder-error.log'
with open(dst,'wb') as f: plistlib.dump(p,f)
PY
sudo launchctl bootout "system/${LABEL}" 2>/dev/null || true
launchctl bootout "gui/${USER_ID}/${AGENT}" 2>/dev/null || true
sudo launchctl bootstrap system "/Library/LaunchDaemons/${LABEL}.plist"
launchctl bootstrap "gui/${USER_ID}" "$HOME/Library/LaunchAgents/${AGENT}.plist"
echo 'Installed. Connect the iPod in Apple OS and wait about 30 seconds.'
echo 'To remove, double-click uninstall.command.'
read -r -p 'Press Return to close...' _
