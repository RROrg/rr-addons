#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing addon addincards - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"

  MODEL="$(cat /proc/sys/kernel/syno_hw_version)"
  FILE="/tmpRoot/usr/syno/etc.defaults/adapter_cards.conf"

  [ ! -f "${FILE}.bak" ] && cp -f "${FILE}" "${FILE}.bak"
  echo -n "" >"${FILE}"
  for N in $(cat "${FILE}.bak" | grep '\['); do
    echo "${N}" >>"${FILE}"
    echo "${MODEL}=yes" >>"${FILE}"
  done
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon addincards - ${1}"

  FILE="/tmpRoot/usr/syno/etc.defaults/adapter_cards.conf"
  [ -f "${FILE}.bak" ] && mv -f "${FILE}.bak" "${FILE}"
fi
