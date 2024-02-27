#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

function extractInitrd() {
  [ -z "${1}" -o -z "${2}" ] && return 1

  if [ -f "${1}" ]; then
    rm -rf "${2}"
    mkdir -p "${2}"
    (
      cd "${2}"
      xz -dc <"${1}" | cpio -idm
    ) >/dev/null 2>&1 || true
  fi
  return 0
}

function mountLoaderDisk() {
  if [ ! -f "/usr/rr/.mountloader" ]; then
    while true; do
      if [ ! -b /dev/synoboot ] || [ ! -b /dev/synoboot1 ] || [ ! -b /dev/synoboot2 ] || [ ! -b /dev/synoboot3 ]; then
        echo "Loader disk not found!"
        break
      fi

      echo 1 >/proc/sys/kernel/syno_install_flag

      # Make folders to mount partitions
      mkdir -p /mnt/p1
      mkdir -p /mnt/p2
      mkdir -p /mnt/p3

      mount /dev/synoboot1 /mnt/p1 2>/dev/null || (
        echo "Can't mount /dev/synoboot1"
        break
      )
      mount /dev/synoboot2 /mnt/p2 2>/dev/null || (
        echo "Can't mount /dev/synoboot2"
        break
      )
      mount /dev/synoboot3 /mnt/p3 2>/dev/null || (
        echo "Can't mount /dev/synoboot3"
        break
      )

      RR_RAMDISK_FILE="/mnt/p3/initrd-rr"
      RR_PATH="/tmp/initrd"
      extractInitrd "${RR_RAMDISK_FILE}" "${RR_PATH}"
      if [ ! -f "${RR_PATH}/opt/rr/menu.sh" ]; then
        echo "RR initrd work path not found!"
        break
      fi

      mkdir -p /usr/rr
      echo "export LOADER_DISK=\"/dev/synoboot\"" >"/usr/rr/.mountloader"
      echo "export LOADER_DISK_PART1=\"/dev/synoboot1\"" >>"/usr/rr/.mountloader"
      echo "export LOADER_DISK_PART2=\"/dev/synoboot2\"" >>"/usr/rr/.mountloader"
      echo "export LOADER_DISK_PART3=\"/dev/synoboot3\"" >>"/usr/rr/.mountloader"
      echo "export WORK_PATH=\"${RR_PATH}/opt/rr\"" >>"/usr/rr/.mountloader"
      break
    done
  fi
  if [ ! -f "/usr/rr/.mountloader" ]; then
    echo "Loader disk mount failed!"
    return 1
  else
    echo "Loader disk mount success!"
    . /usr/rr/.mountloader
    return 0
  fi
}

function unmountLoaderDisk() {
  if [ -f "/usr/rr/.mountloader" ]; then
    rm -f "/usr/rr/.mountloader"
    export LOADER_DISK=
    export LOADER_DISK_PART1=
    export LOADER_DISK_PART2=
    export LOADER_DISK_PART3=

    RR_PATH="/tmp/initrd"
    rm -rf "${RR_PATH}"

    umount /mnt/p1 2>/dev/null
    umount /mnt/p2 2>/dev/null
    umount /mnt/p3 2>/dev/null
    rm -rf /mnt/p1 /mnt/p2 /mnt/p3

    echo 0 >/proc/sys/kernel/syno_install_flag
  fi
  echo "Loader disk umount success!"
  return 0
}

$@
