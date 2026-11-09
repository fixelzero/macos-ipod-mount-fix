#!/usr/bin/env python3
"""User launchd helper: refresh Finder once per mount session."""
import os,subprocess,time
MOUNT='/Volumes/IPOD_RECOVERY'
def log(s): print(time.strftime('%Y-%m-%d %H:%M:%S'),s,flush=True)
def run(*args): subprocess.run(args,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=12)
def main():
    active=False
    log('Started Finder watcher')
    while True:
        try:
            is_mounted=os.path.ismount(MOUNT)
            if not is_mounted: active=False
            elif not active:
                active=True
                log('iPod mount detected; waiting before discovery refresh')
                time.sleep(8)
                if os.path.ismount(MOUNT):
                    run('/usr/bin/killall','AMPDeviceDiscoveryAgent')
                    run('/usr/bin/killall','AMPDevicesAgent')
                    time.sleep(8)
                    if os.path.ismount(MOUNT):
                        run('/usr/bin/killall','Finder')
                        log('Finder refreshed')
        except Exception as e: log('Finder watcher error: '+str(e))
        time.sleep(3)
if __name__=='__main__':main()
