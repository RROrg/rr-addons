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
  cp -pf "${0}" "/tmpRoot/usr/rr/addons/"

  cp -vpf /usr/bin/yq /tmpRoot/usr/bin/yq
  cp -vpf /usr/bin/cpio /tmpRoot/usr/bin/cpio
  cp -vpf /usr/bin/unzip /tmpRoot/usr/bin/unzip

  cp -vpf /usr/sbin/rrmdo /tmpRoot/sbin/rrmdo
  chown root:root /tmpRoot/sbin/rrmdo
  chmod u+s /tmpRoot/sbin/rrmdo

  [ ! -f /tmpRoot/sbin/fatlabel ] && cp -vpf /usr/sbin/fatlabel /tmpRoot/sbin/fatlabel
  [ ! -f /tmpRoot/sbin/dosfslabel ] && ln -vsf fatlabel /tmpRoot/sbin/dosfslabel
  [ ! -f /tmpRoot/sbin/fsck.fat ] && cp -vpf /usr/sbin/fsck.fat /tmpRoot/sbin/fsck.fat
  [ ! -f /tmpRoot/sbin/dosfsck ] && ln -vsf fsck.fat /tmpRoot/sbin/dosfsck
  [ ! -f /tmpRoot/sbin/fsck.msdos ] && ln -vsf fsck.fat /tmpRoot/sbin/fsck.msdos
  [ ! -f /tmpRoot/sbin/fsck.vfat ] && ln -vsf fsck.fat /tmpRoot/sbin/fsck.vfat
  [ ! -f /tmpRoot/sbin/mkfs.fat ] && cp -vpf /usr/sbin/mkfs.fat /tmpRoot/sbin/mkfs.fat
  [ ! -f /tmpRoot/sbin/mkdosfs ] && ln -vsf mkfs.fat /tmpRoot/sbin/mkdosfs
  [ ! -f /tmpRoot/sbin/mkfs.msdos ] && ln -vsf mkfs.fat /tmpRoot/sbin/mkfs.msdos
  [ ! -f /tmpRoot/sbin/mkfs.vfat ] && ln -vsf mkfs.fat /tmpRoot/sbin/mkfs.vfat

  cp -vpf /usr/bin/rr-update.sh /tmpRoot/usr/bin/rr-update.sh
  cp -vpf /usr/bin/rr-loaderdisk.sh /tmpRoot/usr/bin/rr-loaderdisk.sh

  rm -f /tmpRoot/usr/rr/.mountloader

  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  ESYNOSCHEDULER_DB="/tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db"
  if [ ! -f "${ESYNOSCHEDULER_DB}" ] || ! /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" ".tables" | grep -wq "task"; then
    echo "copy esynoscheduler.db"
    mkdir -p "$(dirname "${ESYNOSCHEDULER_DB}")"
    cp -vpf /addons/esynoscheduler.db "${ESYNOSCHEDULER_DB}"
  fi
  echo "insert mountloader task to esynoscheduler.db"
  /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" <<EOF
DELETE FROM task WHERE task_name LIKE 'MountLoaderDisk';
INSERT INTO task VALUES('MountLoaderDisk', '', 'bootup', '', 0, 0, 0, 0, '', 0, '/usr/bin/rr-loaderdisk.sh mountLoaderDisk', 'script', '{}', '', '', '{}', '{}');
DELETE FROM task WHERE task_name LIKE 'UnMountLoaderDisk';
INSERT INTO task VALUES('UnMountLoaderDisk', '', 'shutdown', '', 0, 0, 0, 0, '', 0, '/usr/bin/rr-loaderdisk.sh unmountLoaderDisk', 'script', '{}', '', '', '{}', '{}');
EOF
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon mountloader - ${1}"

  #rm -f "/tmpRoot/usr/bin/yq"
  #rm -f "/tmpRoot/lib/usr/bin/cpio"
  #rm -f "/tmpRoot/lib/usr/bin/unzip"

  rm -f "/tmpRoot/sbin/rrmdo"

  #rm -f "/tmpRoot/sbin/fatlabel"
  #rm -f "/tmpRoot/sbin/dosfslabel"
  #rm -f "/tmpRoot/sbin/fsck.fat"
  #rm -f "/tmpRoot/sbin/dosfsck"F
  #rm -f "/tmpRoot/sbin/fsck.msdos"
  #rm -f "/tmpRoot/sbin/fsck.vfat"
  #rm -f "/tmpRoot/sbin/mkfs.fat"
  #rm -f "/tmpRoot/sbin/mkdosfs"
  #rm -f "/tmpRoot/sbin/mkfs.msdos"
  #rm -f "/tmpRoot/sbin/mkfs.vfat"

  rm -f "/tmpRoot/usr/bin/rr-update.sh"
  rm -f "/tmpRoot/usr/bin/rr-loaderdisk.sh"

  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  ESYNOSCHEDULER_DB="/tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db"
  if [ -f "${ESYNOSCHEDULER_DB}" ]; then
    echo "delete mountloader task from esynoscheduler.db"
    /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" <<EOF
DELETE FROM task WHERE task_name LIKE 'MountLoaderDisk';
DELETE FROM task WHERE task_name LIKE 'UnMountLoaderDisk';
EOF
  fi
fi
