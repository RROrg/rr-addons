#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

case "${1}" in
"early" | "jrExit")
  echo "Installing addon dbgutils - ${1}"
  [ ! -L "/usr/sbin/modinfo" ] && ln -vsf /usr/bin/kmod /usr/sbin/modinfo
  loader-logs.sh "${1}"
  ;;
"rcExit")
  echo "Installing addon dbgutils - ${1}"
  [ ! -L "/usr/sbin/modinfo" ] && ln -vsf /usr/bin/kmod /usr/sbin/modinfo
  loader-logs.sh "${1}"
  echo "Starting ttyd ..."
  if /usr/bin/lsof -Pi :7681 -sTCP:LISTEN -t >/dev/null; then
    echo "Port 7681 is already in use. Terminating the existing process..."
    /usr/bin/lsof -i :7681
  fi
  /usr/sbin/ttyd /usr/bin/ash -l &
  echo "Starting dufs ..."
  if /usr/bin/lsof -Pi :7304 -sTCP:LISTEN -t >/dev/null; then
    echo "Port 7304 is already in use. Terminating the existing process..."
    /usr/bin/lsof -i :7304
  fi
  /usr/sbin/dufs -A -p 7304 / &
  ;;
"late")
  echo "Installing addon dbgutils - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"
  
  [ ! -L "/usr/sbin/modinfo" ] && ln -vsf /usr/bin/kmod /usr/sbin/modinfo
  loader-logs.sh "${1}"

  echo "Installing addon dbgutils"
  echo "Killing ttyd ..."
  /usr/bin/killall ttyd
  echo "Killing dufs ..."
  /usr/bin/killall dufs

  echo "Copying utils"
  [ ! -L "/tmpRoot/usr/sbin/modinfo" ] && ln -vsf /usr/bin/kmod /tmpRoot/usr/sbin/modinfo
  cp -vf /usr/bin/bc /tmpRoot/usr/bin/
  cp -vf /usr/bin/dtc /tmpRoot/usr/bin/
  cp -vf /usr/bin/lsscsi /tmpRoot/usr/bin/
  cp -vf /usr/bin/nano /tmpRoot/usr/bin/
  cp -vf /usr/bin/strace /tmpRoot/usr/bin/
  cp -vf /usr/bin/lsof /tmpRoot/usr/bin/
  cp -vf /usr/bin/loader-logs.sh /tmpRoot/usr/bin/
  cp -vf /usr/sbin/ttyd /tmpRoot/usr/sbin/
  cp -vf /usr/sbin/dufs /tmpRoot/usr/sbin/

  DEST="/tmpRoot/lib/systemd/system/savelogs.service"
  echo "[Unit]"                                      >${DEST}
  echo "Description=RR save logs for debug"         >>${DEST}
  echo                                              >>${DEST}
  echo "[Service]"                                  >>${DEST}
  echo "Type=oneshot"                               >>${DEST}
  echo "RemainAfterExit=yes"                        >>${DEST}
  echo "ExecStop=/bin/loader-logs.sh dsm"           >>${DEST}
  echo                                              >>${DEST}
  echo "[Install]"                                  >>${DEST}
  echo "WantedBy=multi-user.target"                 >>${DEST}

  mkdir -p /tmpRoot/lib/systemd/system/multi-user.target.wants
  ln -vsf /lib/systemd/system/savelogs.service /tmpRoot/lib/systemd/system/multi-user.target.wants/savelogs.service
  ;;
"uninstall")
  echo "Installing addon dbgutils - ${1}"

  rm -f "/tmpRoot/lib/systemd/system/multi-user.target.wants/savelogs.service"
  rm -f "/tmpRoot/lib/systemd/system/savelogs.service"

  #rm -f /tmpRoot/usr/bin/bc
  #rm -f /tmpRoot/usr/bin/dtc
  #rm -f /tmpRoot/usr/bin/lsscsi
  #rm -f /tmpRoot/usr/bin/nano
  #rm -f /tmpRoot/usr/bin/strace
  #rm -f /tmpRoot/usr/bin/lsof
  rm -f /tmpRoot/bin/loader-logs.sh
  #rm -f /tmpRoot/usr/sbin/ttyd
  #rm -f /tmpRoot/usr/sbin/dufs
  ;;
*)
  echo "Installing addon dbgutils - ${1} - nothing to do!"
  exit 0
  ;;
esac
