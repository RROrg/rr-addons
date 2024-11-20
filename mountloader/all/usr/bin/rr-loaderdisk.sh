#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

RR_PATH="/tmp/initrd"

function mountLoaderDisk() {
  if [ ! -f "/usr/rr/.mountloader" ]; then
    while true; do
      if [ ! -b /dev/synoboot ] || [ ! -b /dev/synoboot1 ] || [ ! -b /dev/synoboot2 ] || [ ! -b /dev/synoboot3 ]; then
        echo "Loader disk not found!"
        break
      fi

      echo 1 >/proc/sys/kernel/syno_install_flag

      # Make folders to mount partitions
      for i in {1..3}; do
        rm -rf "/mnt/p${i}"
        mkdir -p "/mnt/p${i}"
        mount "/dev/synoboot${i}" "/mnt/p${i}" || {
          echo "Can't mount /dev/synoboot${i}."
          break 2
        }
      done

      if echo "$@" | grep -qw "\-all"; then
        rm -rf "${RR_PATH}"
        mkdir -p "${RR_PATH}"
        (cd "${RR_PATH}" && xz -dc <"/mnt/p3/initrd-rr" | cpio -idm) >/dev/null 2>&1 || true
        if [ ! -f "${RR_PATH}/opt/rr/menu.sh" ]; then
          echo "RR initrd work path not found!"
          break
        fi
      fi
      mkdir -p /usr/rr
      {
        echo "export LOADER_DISK=\"/dev/synoboot\""
        echo "export LOADER_DISK_PART1=\"/dev/synoboot1\""
        echo "export LOADER_DISK_PART2=\"/dev/synoboot2\""
        echo "export LOADER_DISK_PART3=\"/dev/synoboot3\""
        if [ ! -f "${RR_PATH}/opt/rr/menu.sh" ]; then
          echo "export WORK_PATH=\"${RR_PATH}/opt/rr\""
        fi
      } >"/usr/rr/.mountloader"

      sync

      break
    done
  fi
  if [ ! -f "/usr/rr/.mountloader" ]; then
    echo "Loader disk mount failed!"
    return 1
  else
    echo "Loader disk mount success!"
    . "/usr/rr/.mountloader"
    return 0
  fi
}

function unmountLoaderDisk() {
  if [ -f "/usr/rr/.mountloader" ]; then
    rm -f "/usr/rr/.mountloader"

    sync

    export LOADER_DISK=
    export LOADER_DISK_PART1=
    export LOADER_DISK_PART2=
    export LOADER_DISK_PART3=

    if echo "$@" | grep -qw "\-all"; then
      rm -rf "${RR_PATH}"
    fi
    for i in {1..3}; do
      umount "/mnt/p${i}"
      rm -rf "/mnt/p${i}"
    done

    echo 0 >/proc/sys/kernel/syno_install_flag
  fi
  echo "Loader disk umount success!"
  return 0
}

$@
