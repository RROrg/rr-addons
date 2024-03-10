#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# From：https://github.com/007revad/Synology_enable_M2_volume
# From: https://github.com/PeterSuh-Q3/tcrp-addons/blob/main/nvmevolume-onthefly/src/install.sh
#

if [ "${1}" = "late" ]; then
  echo "Installing addon nvmevolume - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"
  
  SO_FILE="/tmpRoot/usr/lib/libhwcontrol.so.1"
  [ ! -f "${SO_FILE}.bak" ] && cp -vf "${SO_FILE}" "${SO_FILE}.bak"
  xxd -c $(xxd -p "${SO_FILE}.bak" | wc -c) -p "${SO_FILE}.bak" | sed "s/803e00b8010000007524488b/803e00b8010000009090488b/" | xxd -r -p > "${SO_FILE}"
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon nvmevolume - ${1}"

  SO_FILE="/tmpRoot/usr/lib/libhwcontrol.so.1"
  [ -f "${SO_FILE}.bak" ] && mv -f "${SO_FILE}.bak" "${SO_FILE}"
fi
