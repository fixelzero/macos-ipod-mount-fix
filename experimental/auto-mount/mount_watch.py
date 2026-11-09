#!/usr/bin/env python3
"""Root launchd helper: one mount attempt per observed iPod connection."""
import os, plistlib, subprocess, time, sys
TARGET_NAME='FIXEL IPOD'
MOUNT='/Volumes/IPOD_RECOVERY'

def log(msg): print(time.strftime('%Y-%m-%d %H:%M:%S'),msg,flush=True)
def plist_cmd(*args):
    p=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,timeout=15)
    return plistlib.loads(p.stdout) if p.returncode==0 else {}
def candidate():
    data=plist_cmd('/usr/sbin/diskutil','list','-plist')
    for disk in data.get('AllDisksAndPartitions',[]):
        for part in disk.get('Partitions',[]):
            ident=part.get('DeviceIdentifier','')
            if not ident or part.get('VolumeName')!=TARGET_NAME: continue
            info=plist_cmd('/usr/sbin/diskutil','info','-plist',ident)
            if (info.get('VolumeName')==TARGET_NAME and info.get('FilesystemType') in ('msdos','MS-DOS FAT32',None)
                and info.get('Internal') is False and 480_000_000_000 < info.get('TotalSize',0) < 540_000_000_000
                and info.get('BusProtocol','USB')=='USB'):
                return ident,info
    return None,None

def mounted(ident):
    info=plist_cmd('/usr/sbin/diskutil','info','-plist',ident)
    return bool(info.get('MountPoint'))

def main():
    last=None
    log('Started iPod mount watcher')
    while True:
        try:
            ident,info=candidate()
            if ident is None:
                if last is not None: log('iPod disconnected; rearmed')
                last=None
            elif last is None:
                last=ident
                if mounted(ident):
                    log(f'{ident} already mounted; no action')
                else:
                    os.makedirs(MOUNT,exist_ok=True)
                    if os.path.ismount(MOUNT):
                        log('Mount point occupied; refusing to mount')
                    else:
                        log(f'Mounting {ident}')
                        try:
                            p=subprocess.run(['/sbin/mount_msdos','/dev/'+ident,MOUNT],capture_output=True,text=True,timeout=40)
                            log('Mount succeeded' if p.returncode==0 else 'Mount failed: '+p.stderr.strip())
                        except Exception as e: log('Mount exception: '+str(e))
            # If user ejects, do not remount until physically disconnected.
        except Exception as e: log('Watcher error: '+str(e))
        time.sleep(5)
if __name__=='__main__': main()
