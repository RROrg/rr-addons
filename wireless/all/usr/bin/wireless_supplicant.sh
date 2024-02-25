#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# TODO:
# 2024-01-11T06:00:34+08:00 test synoscgi_SYNO.Core.Network.TrafficControl.Rules_1_load[28982]: utils.cpp:44 can not get iftype for wlan0
# [ 1093.186544] SYNO.Core.Syste[29358]: segfault at 0 ip 00007f4bef3bef59 sp 00007ffd65d9fe48 error 4 in libc.so.6[7f4bef298000+14c000]

NAME="${1}"
SSID="${2}"
PSK="${3}"

if [ -n "${NAME}" -a -n "${SSID}" -a -n "${PSK}" ]; then
  # fix iwlwifi module
  if [ -z "$(ls /sys/class/net/wlan* 2>/dev/null)" ] && lsmod | grep -q ^iwlwifi; then
    rmmod iwlmvm 2>/dev/null
    rmmod iwlwifi 2>/dev/null
    rmmod mac80211 2>/dev/null
    rmmod cfg80211 2>/dev/null
    rmmod libarc4 2>/dev/null

    insmod /lib/modules/libarc4.ko
    insmod /lib/modules/cfg80211.ko
    insmod /lib/modules/mac80211.ko
    insmod /lib/modules/iwlwifi.ko
    insmod /lib/modules/iwlmvm.ko

    sleep 1
  fi

  if [ ! -d "/sys/class/net/${NAME}" ]; then
    echo "Interface ${NAME} not found"
    exit 1
  fi

  if [ -f "/var/run/wpa_supplicant.pid.${NAME}" ]; then
    kill -9 $(cat /var/run/wpa_supplicant.pid.${NAME})
    rm -f /var/run/wpa_supplicant.pid.${NAME}
  fi
  rm -f /etc/sysconfig/network-scripts/ifcfg-wlan* /etc.defaults/sysconfig/network-scripts/ifcfg-wlan*
  #echo -e "DEVICE=${NAME}\nONBOOT=yes\nBOOTPROTO=dhcp\nIPV6INIT=dhcp\nIPV6_ACCEPT_RA=1" >"/etc/sysconfig/network-scripts/ifcfg-${NAME}"
  #cp -f "/etc/sysconfig/network-scripts/ifcfg-${NAME}" "/etc.defaults/sysconfig/network-scripts/ifcfg-${NAME}"
  echo -e "ctrl_interface=/var/run/wpa_supplicant\nupdate_config=1\nnetwork={\n        ssid=\"${SSID}\"\n        priority=1\n        psk=\"${PSK}\"\n}" >/usr/syno/etc/wpa_supplicant.conf.${NAME}
  /usr/sbin/wpa_supplicant -i ${NAME} -c /usr/syno/etc/wpa_supplicant.conf.${NAME} -B -P /var/run/wpa_supplicant.pid.${NAME}
  /usr/syno/sbin/synonet --dhcp ${NAME}
fi
