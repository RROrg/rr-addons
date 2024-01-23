#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing daemon for mountloader"

  SED_PATH='/tmpRoot/usr/bin/sed'

  ${SED_PATH} -i 's|^.*PermitRootLogin.*$|PermitRootLogin yes|' /tmpRoot/etc/ssh/sshd_config  

  if [ ! -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
    echo "copy esynoscheduler.db"
    mkdir -p /tmpRoot/usr/syno/etc/esynoscheduler
    cp -vf /addons/esynoscheduler.db /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db
  fi
  echo "insert mountloader task to esynoscheduler.db"
  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'MountLoaderDisk';
INSERT INTO task VALUES('MountLoaderDisk', '', 'bootup', '', 0, 0, 0, 0, '', 0, '
mkdir -p /mnt/loader1 /mnt/loader2 /mnt/loader3
mount /dev/synoboot1 /mnt/loader1 2>/dev/null
mount /dev/synoboot2 /mnt/loader2 2>/dev/null
mount /dev/synoboot3 /mnt/loader3 2>/dev/null
', 'script', '{}', '', '', '{}', '{}');
DELETE FROM task WHERE task_name LIKE 'UnMountLoaderDisk';
INSERT INTO task VALUES('UnMountLoaderDisk', '', 'shutdown', '', 0, 0, 0, 0, '', 0, '
sync
umount /mnt/loader1 2>/dev/null
umount /mnt/loader2 2>/dev/null
umount /mnt/loader3 2>/dev/null
rm -rf /mnt/loader1 /mnt/loader2 /mnt/loader3
', 'script', '{}', '', '', '{}', '{}');
EOF
fi