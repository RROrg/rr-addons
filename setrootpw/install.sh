#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing addon setrootpw - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"

  [ ! -f "/tmpRoot/etc/ssh/sshd_config.bak" ] && cp -f "/tmpRoot/etc/ssh/sshd_config" "/tmpRoot/etc/ssh/sshd_config.bak"
  SED_PATH='/tmpRoot/usr/bin/sed'
  ${SED_PATH} -i 's|^.*PermitRootLogin.*$|PermitRootLogin yes|' /tmpRoot/etc/ssh/sshd_config

  if [ ! -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
    echo "copy esynoscheduler.db"
    mkdir -p /tmpRoot/usr/syno/etc/esynoscheduler
    cp -vf /addons/esynoscheduler.db /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db
  fi
  echo "insert setrootpw task to esynoscheduler.db"
  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'SetRootPw';
INSERT INTO task VALUES('SetRootPw', '', 'bootup', '', 0, 0, 0, 0, '', 0, 'PW=""; [ -n "\${PW}" ] && /usr/syno/sbin/synouser --setpw root \${PW}; systemctl restart sshd', 'script', '{}', '', '', '{}', '{}');
EOF
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon setrootpw - ${1}"

  [ -f "/tmpRoot/etc/ssh/sshd_config.bak" ] && mv -f "/tmpRoot/etc/ssh/sshd_config.bak" "/tmpRoot/etc/ssh/sshd_config"

  if [ -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
    echo "delete setrootpw task from esynoscheduler.db"
    export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
    /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'SetRootPw';
EOF
  fi
fi
