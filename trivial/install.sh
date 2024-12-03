#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing addon trivial - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -pf "${0}" "/tmpRoot/usr/rr/addons/"

  # logger
  SO_FILE="/tmpRoot/usr/lib/libsynosata.so.1"
  [ ! -f "${SO_FILE}.bak" ] && cp -pf "${SO_FILE}" "${SO_FILE}.bak"
  cp -pf "${SO_FILE}" "${SO_FILE}.tmp"
  xxd -c $(xxd -p "${SO_FILE}.tmp" 2>/dev/null | wc -c) -p "${SO_FILE}.tmp" 2>/dev/null |
    sed "s/8d15ba160000bf03000000e8c0c8ffff/8d15ba160000bf030000009090909090/" |
    xxd -r -p >"${SO_FILE}" 2>/dev/null
  rm -f "${SO_FILE}.tmp"
  
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon trivial - ${1}"

  SO_FILE="/tmpRoot/usr/lib/libsynosata.so.1"
  [ -f "${SO_FILE}.bak" ] && mv -f "${SO_FILE}.bak" "${SO_FILE}"
fi
