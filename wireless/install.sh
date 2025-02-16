#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing addon wireless - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -pf "${0}" "/tmpRoot/usr/rr/addons/"

  cp -vpf /usr/bin/wireless_supplicant.sh /tmpRoot/usr/bin/wireless_supplicant.sh
  cp -vpf /usr/sbin/iw /tmpRoot/usr/sbin/iw
  cp -vpf /usr/sbin/rfkill /tmpRoot/usr/sbin/rfkill

  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  ESYNOSCHEDULER_DB="/tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db"
  if [ ! -f "${ESYNOSCHEDULER_DB}" ] || ! /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" ".tables" | grep -wq "task"; then
    echo "copy esynoscheduler.db"
    mkdir -p "$(dirname "${ESYNOSCHEDULER_DB}")"
    cp -vpf /addons/esynoscheduler.db "${ESYNOSCHEDULER_DB}"
  fi
  if echo "SELECT * FROM task;" | /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" | grep -q "Wireless"; then
    echo "wireless task already exists"
  else
    echo "insert wireless task to esynoscheduler.db"
    /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" <<EOF
INSERT INTO task VALUES('Wireless', '', 'bootup', '', 0, 0, 0, 0, '', 0, '
# NAME: The name of the wireless network interface, "*" is All, Support "," segmentation; e.g. wlan0,eth81. (wlan0 = eth80, wlan1 = eth81, ...)
# SSID: The SSID of the wireless network.
# PASSWD: The password of the wireless network.
/usr/bin/wireless_supplicant.sh "NAME" "SSID" "PASSWD"
', 'script', '{}', '', '', '{}', '{}');
EOF
  fi
elif [ "${1}" = "uninstall" ]; then
  echo "Uninstalling daemon for wireless - ${1}"

  rm -f /tmpRoot/usr/bin/wireless_supplicant.sh
  rm -f /tmpRoot/usr/sbin/iw
  rm -f /tmpRoot/usr/sbin/rfkill

  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  ESYNOSCHEDULER_DB="/tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db"
  if [ -f "${ESYNOSCHEDULER_DB}" ]; then
    echo "delete wireless task from esynoscheduler.db"
    /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" <<EOF
DELETE FROM task WHERE task_name LIKE 'Wireless';
EOF
  fi
fi
