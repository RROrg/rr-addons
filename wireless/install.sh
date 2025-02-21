#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
if [ "${1}" = "rcExit" ]; then
  echo "Installing addon wireless - ${1}"

  SSID="$(cat /proc/cmdline 2>/dev/null | grep -Eo 'wpa.ssid=[^ ]+' | sed 's/wpa.ssid=//' | xxd -r -p)"
  PSK="$(cat /proc/cmdline 2>/dev/null | grep -Eo 'wpa.psk=[^ ]+' | sed 's/wpa.psk=//' | xxd -r -p)"

  if [ -n "${SSID}" ] && [ -n "${PSK}" ]; then
    ETHX=$(ls /sys/class/net/ 2>/dev/null | grep '^eth8' | grep -v '^eth8$')
    if [ -n "${ETHX}" ]; then
      echo "Wireless: ${SSID} ${PSK} for ${ETHX}"
      tar -zxf /addons/wireless-7.1.tgz -C /
      for N in ${ETHX}; do
        if [ -f "/var/run/wpa_supplicant.pid.${N}" ]; then
          kill $(cat "/var/run/wpa_supplicant.pid.${N}")
          rm -f "/var/run/wpa_supplicant.pid.${N}"
        fi
        ISOVS=$([ -L "/sys/class/net/ovs_${N}" ] && echo "true" || echo "false")
        [ "${ISOVS}" = "true" ] && /etc/rc.network "stop" "ovs_${N}" >/dev/null 2>&1
        echo -e "ctrl_interface=/var/run/wpa_supplicant\nupdate_config=1\nnetwork={\n        ssid=\"${SSID}\"\n        priority=1\n        psk=\"${PSK}\"\n}" >"/usr/syno/etc/wpa_supplicant.conf.${N}"
        /usr/sbin/wpa_supplicant -i "${N}" -c "/usr/syno/etc/wpa_supplicant.conf.${N}" -qq -B -P "/var/run/wpa_supplicant.pid.${N}"
        sleep 3
        if [ -x /sbin/udhcpc ]; then # junior
          if [ -f "/etc/dhcpc/dhcpcd-${N}.pid" ]; then
            kill $(cat "/etc/dhcpc/dhcpcd-${N}.pid")
            rm -f "/etc/dhcpc/dhcpcd-${N}.pid"
          fi
          /sbin/udhcpc -i ${N} -p "/etc/dhcpc/dhcpcd-${N}.pid" -b -x hostname:$(hostname) || true
        fi
        sleep 1
        [ "${ISOVS}" = "true" ] && /etc/rc.network "start" "ovs_${N}" >/dev/null 2>&1
        sleep 1
        /usr/sbin/wpa_cli status
      done
    fi
  fi

elif [ "${1}" = "late" ]; then
  echo "Installing addon wireless - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -pf "${0}" "/tmpRoot/usr/rr/addons/"

  cp -vpf /usr/bin/wireless_supplicant.sh /tmpRoot/usr/bin/wireless_supplicant.sh
  tar -zxf /addons/wireless-7.1.tgz -C /tmpRoot/usr ./sbin/iw ./sbin/rfkill

  SSID="$(cat /proc/cmdline 2>/dev/null | grep -Eo 'wpa.ssid=[^ ]+' | sed 's/wpa.ssid=//' | xxd -r -p)"
  PSK="$(cat /proc/cmdline 2>/dev/null | grep -Eo 'wpa.psk=[^ ]+' | sed 's/wpa.psk=//' | xxd -r -p)"

  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  ESYNOSCHEDULER_DB="/tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db"
  if [ ! -f "${ESYNOSCHEDULER_DB}" ] || ! /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" ".tables" | grep -wq "task"; then
    echo "copy esynoscheduler.db"
    mkdir -p "$(dirname "${ESYNOSCHEDULER_DB}")"
    cp -vpf /addons/esynoscheduler.db "${ESYNOSCHEDULER_DB}"
  fi
  ENABLE=0
  if [ -n "${SSID}" ] && [ -n "${PSK}" ]; then
    ENABLE=1
    ETHX=$(ls /sys/class/net/ 2>/dev/null | grep '^eth8' | grep -v '^eth8$')
    for N in ${ETHX}; do
      if [ -f "/var/run/wpa_supplicant.pid.${N}" ]; then
        kill $(cat "/var/run/wpa_supplicant.pid.${N}")
        rm -f "/var/run/wpa_supplicant.pid.${N}"
      fi
      if [ -x /sbin/udhcpc ]; then # junior
        if [ -f "/etc/dhcpc/dhcpcd-${N}.pid" ]; then
          kill $(cat "/etc/dhcpc/dhcpcd-${N}.pid")
          rm -f "/etc/dhcpc/dhcpcd-${N}.pid"
        fi
      fi
    done
  fi
  if echo "SELECT * FROM task;" | /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" | grep -q "Wireless"; then
    echo "wireless task already exists"
  else
    echo "insert wireless task to esynoscheduler.db"
    /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" <<EOF
INSERT INTO task VALUES('Wireless', '', 'bootup', '', ${ENABLE}, 0, 0, 0, '', 0, '
# 1: The NAME of the wireless network interface, "*" is All, Support "," segmentation; e.g. wlan0,eth81. (wlan0 = eth80, wlan1 = eth81, ...)
# 2: The SSID of the wireless network.
# 3: The PSK of the wireless network.
/usr/bin/wireless_supplicant.sh "*" "${SSID:-SSID}" "${PSK:-PSK}"
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
