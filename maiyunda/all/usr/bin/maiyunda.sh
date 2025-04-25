#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

function _log() {
  echo "maiyunda: $*"
  /bin/logger -p "error" -t "maiyunda" "$@"
}

function operation3s() {
  _log "operation 3s"
  # change admin password
  USERNAME="admin"
  PASSWORD="maiyunda.com"
  NEWPASSWD="$(openssl passwd -6 -salt "$(openssl rand -hex 8)" "${PASSWORD:-rr}")"
  sed -i "s|^${USERNAME}:[^:]*|${USERNAME}:${NEWPASSWD}|" "/etc/shadow"
  sed -i "/^${USERNAME}:/ s/^\(${USERNAME}:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\)[^:]*:/\1:/" "/etc/shadow"

  # restart network
  rm -f /etc/sysconfig/network-scripts/ifcfg-bond* 2>/dev/null
  rm -f /etc/sysconfig/network-scripts/ifcfg-eth* 2>/dev/null
  cp -f /etc.defaults/sysconfig/network-scripts/ifcfg-bond* /etc/sysconfig/network-scripts/ 2>/dev/null
  cp -f /etc.defaults/sysconfig/network-scripts/ifcfg-eth* /etc/sysconfig/network-scripts/ 2>/dev/null
  /etc/rc.network restart

  exit 0
}

function operation9s() {
  _log "operation 9s"
  if [ -x "/usr/bin/loader-reboot.sh" ]; then
    # junior reset
    /usr/bin/loader-reboot.sh "junior"
  else
    # factory reset
    synowebapi --exec api=SYNO.Core.System method=reset version=1
  fi
}

function operation18s() {
  _log "operation 18s"
  # factory reset
  synowebapi --exec api=SYNO.Core.System method=reset version=1
}

function main() {
  port=${1}
  mode=${2}
  timeout=0
  pressed=false
  baseval=$(inb ${port})
  while true; do
    sleep 1
    currval=$(inb ${port})
    if [ ! "${currval}" = "${baseval}" ]; then
      pressed=true
      timeout=$((timeout + 1))
      if [ $((timeout % 3)) -eq 0 ]; then
        beep -f 1000 -l 50 -d 50 -r 3 &
      fi
      if [ "${mode}" = "0" ]; then
        if [ ${timeout} -eq 3 ]; then
          operation3s &
        fi
        if [ ${timeout} -eq 9 ]; then
          operation9s &
        fi
        if [ ${timeout} -eq 18 ]; then
          operation18s &
        fi
      fi
    else
      if [ ! "${mode}" = "0" ]; then
        if [ "${pressed}" = "true" ]; then
          if [ ${timeout} -ge 3 ] && [ ${timeout} -lt 9 ]; then
            operation3s &
          fi
          if [ ${timeout} -ge 9 ] && [ ${timeout} -lt 18 ]; then
            operation9s &
          fi
          if [ ${timeout} -ge 18 ] && [ ${timeout} -lt 60 ]; then
            operation18s &
          fi
        fi
      fi
      pressed=false
      timeout=0
    fi
    if [ ${timeout} -ge 60 ]; then
      timeout=0
    fi
  done
}

PORT=${1:-"0xA03"}
MODE=${2:-0} # 0: trigger when pressed, 1: trigger when release

main "${PORT}" "${MODE}"
