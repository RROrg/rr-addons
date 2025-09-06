#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

case "${1}" in
on)
  dpmstest -g 2>/dev/null | jq -c '.[]' | while read -r row; do
    _id=$(echo "${row}" | jq -r '.id')
    _status=$(echo "${row}" | jq -r '.status')
    _value=$(echo "${row}" | jq -r '.value')
    _on=$(echo "${row}" | jq -r '.dpms.on')
    _off=$(echo "${row}" | jq -r '.dpms.off')

    if [ "${_status}" = "connected" ] && [ "${_value}" != "${_on}" ]; then
      echo "Enabling DPMS on display id ${_id} (current: ${_value}, on: ${_on})"
      dpmstest -w ${_id}:${_on} 2>/dev/null
    fi
  done
  ;;
off)
  dpmstest -g 2>/dev/null | jq -c '.[]' | while read -r row; do
    _id=$(echo "${row}" | jq -r '.id')
    _status=$(echo "${row}" | jq -r '.status')
    _value=$(echo "${row}" | jq -r '.value')
    _on=$(echo "${row}" | jq -r '.dpms.on')
    _off=$(echo "${row}" | jq -r '.dpms.off')

    if [ "${_status}" = "connected" ] && [ "${_value}" != "${_off}" ]; then
      echo "Disabling DPMS on display id ${_id} (current: ${_value}, off: ${_off})"
      dpmstest -w ${_id}:${_off} 2>/dev/null
    fi
  done
  ;;
*)
  echo "Usage: ${0} on|off"
  exit 1
  ;;
esac

exit 0
