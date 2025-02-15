#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

NAME="${1}"
SSID="${2}"
PSK="${3}"

if [ -z "${NAME}" ] || [ -z "${SSID}" ] || [ -z "${PSK}" ]; then
  echo "Usage: $0 <NAME> <SSID> <PSK>"
  exit 1
fi

if [ "${NAME}" = "*" ]; then
  ETHX=$(ls /sys/class/net/ 2>/dev/null | grep 'eth8')
else
  ETHX=$(echo "${NAME}" | sed 's/wlan/eth8/g' | tr ',;|' ' ')
fi

# Ensure ETHX is not empty
if [ -z "${ETHX}" ]; then
  echo "No valid network interfaces found."
  exit 1
fi

for N in ${ETHX}; do
  if [ -f "/var/run/wpa_supplicant.pid.${N}" ]; then
    pkill -F "/var/run/wpa_supplicant.pid.${N}"
    rm -f "/var/run/wpa_supplicant.pid.${N}"
  fi

  PRE=$([ -n "$(cat /usr/syno/etc/synoovs/ovs_reg.conf 2>/dev/null)" ] && echo "ovs_" || echo "")
  N=${PRE}${N}
  echo -e "ctrl_interface=/var/run/wpa_supplicant\nupdate_config=1\nnetwork={\n        ssid=\"${SSID}\"\n        priority=1\n        psk=\"${PSK}\"\n}" >"/usr/syno/etc/wpa_supplicant.conf.${N}"
  /usr/sbin/wpa_supplicant -i "${N}" -c "/usr/syno/etc/wpa_supplicant.conf.${N}" -qq -B -P "/var/run/wpa_supplicant.pid.${N}"
  sleep 3
  /usr/syno/sbin/synonet --dhcp "${N}"
  sleep 1
  /usr/sbin/wpa_cli status
done
