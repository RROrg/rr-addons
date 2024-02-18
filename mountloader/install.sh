#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing addon mountloader - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"

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
echo 1 > /proc/sys/kernel/syno_install_flag
mkdir -p /mnt/p1 /mnt/p2 /mnt/p3
mount /dev/synoboot1 /mnt/p1 2>/dev/null
mount /dev/synoboot2 /mnt/p2 2>/dev/null
mount /dev/synoboot3 /mnt/p3 2>/dev/null
export LOADER_DISK=/dev/synoboot
export LOADER_DISK_PART1=/dev/synoboot1
export LOADER_DISK_PART2=/dev/synoboot2
export LOADER_DISK_PART3=/dev/synoboot3
', 'script', '{}', '', '', '{}', '{}');
DELETE FROM task WHERE task_name LIKE 'UnMountLoaderDisk';
INSERT INTO task VALUES('UnMountLoaderDisk', '', 'shutdown', '', 0, 0, 0, 0, '', 0, '
sync
export LOADER_DISK=
export LOADER_DISK_PART1=
export LOADER_DISK_PART2=
export LOADER_DISK_PART3=
umount /mnt/p1 2>/dev/null
umount /mnt/p2 2>/dev/null
umount /mnt/p3 2>/dev/null
rm -rf /mnt/p1 /mnt/p2 /mnt/p3
echo 0 > /proc/sys/kernel/syno_install_flag
', 'script', '{}', '', '', '{}', '{}');
EOF
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon mountloader - ${1}"

  if [ -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
    echo "delete mountloader task from esynoscheduler.db"
    export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
    /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'MountLoaderDisk';
DELETE FROM task WHERE task_name LIKE 'UnMountLoaderDisk';
EOF
  fi
fi
