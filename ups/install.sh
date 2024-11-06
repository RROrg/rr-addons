#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing addon updatenotify - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"

  FILE="/tmpRoot/usr/syno/bin/synoups"
  [ ! -f "${FILE}.bak" ] && cp -f "${FILE}" "${FILE}.bak"

  cp -f "${FILE}.bak" "${FILE}"
  if [ -z "${2}" ] || [ "${2}" = "-f" ]; then
    sed -i "s|/usr/syno/sbin/synopoweroff.*$|/usr/syno/sbin/synopoweroff|g" "${FILE}"
  fi
  if [ "${2}" = "-e" ] || [ "${2}" = "-f" ]; then
    EVENT_POWEROFF="/usr/syno/sbin/esynoscheduler --fireEvent event=shutdown"
    if ! grep -q "${EVENT_POWEROFF}" "${FILE}"; then
      sed -i "/\/usr\/syno\/sbin\/synopoweroff/i\ \ \ \ ${EVENT_POWEROFF}" "${FILE}"
    fi
    if [ ! -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
      echo "copy esynoscheduler.db"
      mkdir -p /tmpRoot/usr/syno/etc/esynoscheduler
      cp -vf /addons/esynoscheduler.db /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db
    fi
    echo "insert start/stop ScsiTarget task to esynoscheduler.db"
    export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
    /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'StartScsiTarget';
INSERT INTO task VALUES('StartScsiTarget', '', 'bootup', '', 1, 0, 0, 0, '', 0, "synopkg start ScsiTarget", 'script', '{}', '', '', '{}', '{}');
DELETE FROM task WHERE task_name LIKE 'StopScsiTarget';
INSERT INTO task VALUES('StopScsiTarget', '', 'shutdown', '', 1, 0, 0, 0, '', 0, "synopkg stop ScsiTarget", 'script', '{}', '', '', '{}', '{}');
EOF
  fi
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon rr-updatenotify - ${1}"

  FILE="/tmpRoot/usr/syno/bin/synoups"
  [ -f "${FILE}.bak" ] && mv -f "${FILE}.bak" "${FILE}"

  if [ -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
    echo "delete synoconfbkp task from esynoscheduler.db"
    export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
    /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'StartScsiTarget';
DELETE FROM task WHERE task_name LIKE 'StopScsiTarget';
EOF
  fi
fi
