#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

RR_PATH="/tmp/initrd"
[ -f "/sbin/rrmdo" ] && RR_SUDO="/sbin/rrmdo" || RR_SUDO=""

function mountLoaderDisk() {
  if [ ! -f "/usr/rr/.mountloader" ]; then
    while true; do
      if [ ! -b /dev/synoboot ] || [ ! -b /dev/synoboot1 ] || [ ! -b /dev/synoboot2 ] || [ ! -b /dev/synoboot3 ]; then
        echo "Loader disk not found!"
        break
      fi

      echo 1 | ${RR_SUDO} tee /proc/sys/kernel/syno_install_flag >/dev/null

      # Make folders to mount partitions
      for i in {1..3}; do
        ${RR_SUDO} rm -rf "/mnt/p${i}"
        ${RR_SUDO} mkdir -p "/mnt/p${i}"
        ${RR_SUDO} mount "/dev/synoboot${i}" "/mnt/p${i}" || {
          echo "Can't mount /dev/synoboot${i}."
          break 2
        }
      done

      if echo "$@" | grep -wq "\-all"; then
        ${RR_SUDO} rm -rf "${RR_PATH}"
        ${RR_SUDO} mkdir -p "${RR_PATH}"
        (cd "${RR_PATH}" && xz -dc <"/mnt/p3/initrd-rr" | ${RR_SUDO} cpio -idm) >/dev/null 2>&1 || true
        if [ ! -f "${RR_PATH}/opt/rr/menu.sh" ]; then
          echo "RR initrd work path not found!"
          break
        fi
      fi
      ${RR_SUDO} mkdir -p /usr/rr
      {
        echo "export LOADER_DISK=\"/dev/synoboot\""
        echo "export LOADER_DISK_PART1=\"/dev/synoboot1\""
        echo "export LOADER_DISK_PART2=\"/dev/synoboot2\""
        echo "export LOADER_DISK_PART3=\"/dev/synoboot3\""
        if [ ! -f "${RR_PATH}/opt/rr/menu.sh" ]; then
          echo "export WORK_PATH=\"${RR_PATH}/opt/rr\""
        fi
      } | ${RR_SUDO} tee "/usr/rr/.mountloader" >/dev/null
      ${RR_SUDO} chmod 755 "/usr/rr/.mountloader"

      sync

      break
    done
  fi
  if [ ! -f "/usr/rr/.mountloader" ]; then
    echo "Loader disk mount failed!"
    return 1
  else
    ${RR_SUDO} "/usr/rr/.mountloader"
    echo "Loader disk mount success!"
    return 0
  fi
}

function unmountLoaderDisk() {
  if [ -f "/usr/rr/.mountloader" ]; then
    {
      echo "export LOADER_DISK=\"\""
      echo "export LOADER_DISK_PART1=\"\""
      echo "export LOADER_DISK_PART2=\"\""
      echo "export LOADER_DISK_PART3=\"\""
      if [ -f "${RR_PATH}/opt/rr/menu.sh" ]; then
        echo "export WORK_PATH=\"\""
      fi
    } | ${RR_SUDO} tee "/usr/rr/.mountloader" >/dev/null
    ${RR_SUDO} chmod 755 "/usr/rr/.mountloader"
    ${RR_SUDO} "/usr/rr/.mountloader"
    ${RR_SUDO} rm -f "/usr/rr/.mountloader"

    sync

    if echo "$@" | grep -wq "\-all"; then
      ${RR_SUDO} rm -rf "${RR_PATH}"
    fi
    for i in {1..3}; do
      ${RR_SUDO} umount "/mnt/p${i}"
      ${RR_SUDO} rm -rf "/mnt/p${i}"
    done

    echo 0 | ${RR_SUDO} tee /proc/sys/kernel/syno_install_flag >/dev/null
  fi
  echo "Loader disk umount success!"
  return 0
}

$@
