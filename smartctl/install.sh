#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing addon smartctl - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -pf "${0}" "/tmpRoot/usr/rr/addons/"

  FILE="/tmpRoot/usr/bin/smartctl"
  [ ! -f "${FILE}.bak" ] && cp -pf "${FILE}" "${FILE}.bak"
  
  cp -vpf /usr/bin/smartctl.sh "${FILE}"
  
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon smartctl - ${1}"

  FILE="/tmpRoot/usr/bin/smartctl"
  [ -f "${FILE}.bak" ] && mv -f "${FILE}.bak" "${FILE}"
fi
