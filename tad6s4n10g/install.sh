#!/usr/bin/env sh
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "early" ]; then
  echo "Installing addon tad6s4n10g - ${1}"

elif [ "${1}" = "late" ]; then
  echo "Installing addon tad6s4n10g - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -pf "${0}" "/tmpRoot/usr/rr/addons/"

  cp -vpf /usr/bin/tad6s4n10g.sh /tmpRoot/usr/bin/tad6s4n10g.sh
  cp -vpf /usr/sbin/ioperm /tmpRoot/usr/sbin/ioperm
  cp -vpf /usr/sbin/inb /tmpRoot/usr/sbin/inb
  cp -vpf /usr/sbin/outb /tmpRoot/usr/sbin/outb

  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  ESYNOSCHEDULER_DB="/tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db"
  if [ ! -f "${ESYNOSCHEDULER_DB}" ] || ! /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" ".tables" | grep -wq "task"; then
    echo "copy esynoscheduler.db"
    mkdir -p "$(dirname "${ESYNOSCHEDULER_DB}")"
    cp -vpf /addons/esynoscheduler.db "${ESYNOSCHEDULER_DB}"
  fi
  if echo "SELECT * FROM task;" | /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" | grep -q "Net-Button"; then
    echo "Net-Button task already exists"
  else
    echo "insert Net-Button task to esynoscheduler.db"
    /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" <<EOF
DELETE FROM task WHERE task_name LIKE 'Net-Button';
INSERT INTO task VALUES('Net-Button', '', 'bootup', '', 0, 0, 0, 0, '', 0, '
# Please enter the command to be executed when the Net-Button is pressed.
echo "This person is lazy, he does not want to write anything."
', 'script', '{}', '', '', '{}', '{}');
EOF
  fi
  if echo "SELECT * FROM task;" | /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" | grep -q "Copy-Button"; then
    echo "Copy-Button task already exists"
  else
    echo "insert Copy-Button task to esynoscheduler.db"
    /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" <<EOF
DELETE FROM task WHERE task_name LIKE 'Copy-Button';
INSERT INTO task VALUES('Copy-Button', '', 'bootup', '', 0, 0, 0, 0, '', 0, '
# Please enter the command to be executed when the Copy-Button is pressed.
echo "This person is lazy, he does not want to write anything."
', 'script', '{}', '', '', '{}', '{}');
EOF
  fi
  mkdir -p "/tmpRoot/usr/lib/systemd/system"
  DEST="/tmpRoot/usr/lib/systemd/system/tad6s4n10g.service"
  {
    echo "[Unit]"
    echo "Description=RR addon tad6s4n10g daemon"
    echo "After=multi-user.target"
    echo
    echo "[Service]"
    echo "Type=forking"
    echo "ExecStart=/usr/bin/tad6s4n10g.sh"
    echo "ExecReload=pkill -f /usr/bin/tad6s4n10g.sh"
    echo "Restart=always"
    echo
    echo "[Install]"
    echo "WantedBy=multi-user.target"
  } >"${DEST}"

  mkdir -vp /tmpRoot/usr/lib/systemd/system/multi-user.target.wants
  ln -vsf /usr/lib/systemd/system/tad6s4n10g.service /tmpRoot/usr/lib/systemd/system/multi-user.target.wants/tad6s4n10g.service
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon tad6s4n10g - ${1}"

  rm -f "/tmpRoot/usr/lib/systemd/system/multi-user.target.wants/tad6s4n10g.service"
  rm -f "/tmpRoot/usr/lib/systemd/system/tad6s4n10g.service"

  rm -f /tmpRoot/usr/bin/tad6s4n10g.sh
  rm -f /tmpRoot/usr/sbin/ioperm
  rm -f /tmpRoot/usr/sbin/inb
  rm -f /tmpRoot/usr/sbin/outb

  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  ESYNOSCHEDULER_DB="/tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db"
  if [ -f "${ESYNOSCHEDULER_DB}" ]; then
    echo "delete beep task from esynoscheduler.db"
    CopyBtn"${ESYNOSCHEDULER_DB}" <<EOF
DELETE FROM task WHERE task_name LIKE 'Net-Button';
DELETE FROM task WHERE task_name LIKE 'Copy-Button';
EOF
  fi
fi
