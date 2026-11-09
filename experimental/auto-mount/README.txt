Fixel iPod Auto Mount (experimental)

This is a background helper for the original Apple OS on a 512GB iFlash iPod named FIXEL IPOD.
It does not install or remove Rockbox and does not modify the iPod filesystem layout.

HOW TO INSTALL
1. Disconnect/eject the iPod first.
2. Double-click install.command (or run bash install.command from Terminal).
3. Enter the Mac administrator password when requested.
4. Connect the iPod in Apple OS mode. Allow about 30 seconds.
5. Finder should show both the mounted volume and the iPod sync page.

HOW IT WORKS
- A root launchd daemon checks for the exact external USB FAT32 partition named FIXEL IPOD, approximately 512GB, every 5 seconds.
- It attempts to mount using mount_msdos only once per detected connection. If you eject, it will not intentionally remount until disconnected and reconnected.
- A separate user LaunchAgent detects the mount, waits 8 seconds, restarts AMPDeviceDiscoveryAgent and AMPDevicesAgent, waits 8 seconds, then restarts Finder.
- Neither helper stores your administrator password or modifies the Apple OS/Rockbox.

LIMITATIONS
- Untested on your Mac; test with the iPod backed up and do not start a sync until Finder is stable.
- The disk must disappear from macOS for at least one polling interval between reconnects; rapid replugging might not trigger a new attempt.
- Root daemon matches the volume name, approximate capacity and USB/external characteristics. Avoid attaching another device with the same name and capacity.
- If macOS already mounted the iPod somewhere else, the daemon will not remount it. The Finder watcher responds only to /Volumes/IPOD_RECOVERY.
- Automatic mounting is available in the original Apple OS USB disk mode; Rockbox's USB behavior may differ.
- macOS updates may change service names or behavior.

UNINSTALL
Double-click uninstall.command (or run bash uninstall.command from Terminal).
This stops and removes both helpers. It does not touch iPod contents.

LOGS
/var/log/fixel-ipod-mount.log
~/Library/Logs/fixel-ipod-finder.log

SAFETY
Always eject before disconnecting, especially after syncing.
