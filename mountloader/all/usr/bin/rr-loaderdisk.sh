#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

function extractInitrd() {
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    return 1
  fi

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
      for i in {1..3}; do
        rm -rf "/mnt/p${i}"
        mkdir -p "/mnt/p${i}"
        mount "/dev/synoboot${i}" "/mnt/p${i}" || {
          echo "Can't mount /dev/synoboot${i}."
          break 2
        }
      done

      if echo "$@" | grep -qw "\-all"; then
        RR_RAMDISK_FILE="/mnt/p3/initrd-rr"
        RR_PATH="/tmp/initrd"
        extractInitrd "${RR_RAMDISK_FILE}" "${RR_PATH}"
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
      RR_PATH="/tmp/initrd"
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
