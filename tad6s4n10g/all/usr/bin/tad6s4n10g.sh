#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

function _log() {
  echo "tad6s4n10g: $*"
  /bin/logger -p "error" -t "tad6s4n10g" "$@"
}

function NetBtnOpt3s() {
  _log "Net-Button pressed"
  # synowebapi -s --exec api=SYNO.Core.EventScheduler method=list version=1
  synowebapi -s --exec api=SYNO.Core.EventScheduler method=run version=1 task_name=\"Net-Button\"
}

function CopyBtnOpt3s() {
  _log "Copy-Button pressed"
  # synowebapi -s --exec api=SYNO.Core.EventScheduler method=list version=1
  synowebapi -s --exec api=SYNO.Core.EventScheduler method=run version=1 task_name=\"Copy-Button\"
}

function ResetBtnOpt3s() {
  _log "Reset-Button pressed"
  synowebapi -s --exec api=SYNO.Core.System method=reset version=1
}

function _beep() {
  local t=1
  [[ "${1}" =~ ^[0-9]+$ ]] && t="${1}"

  # shellcheck disable=SC2034
  for i in $(seq 1 ${t}); do
    beep -l 1 -l 1 -D 3 -r 20
    sleep 0.1
  done
}

function _NetBtnLed() {
  :
}

function _CopyBtnLed() {
  local t=1
  [[ "${1}" =~ ^[0-9]+$ ]] && t="${1}"

  # shellcheck disable=SC2034
  for i in $(seq 1 ${t}); do
    outb 1 "0xA00" 0 
    sleep 0.1
    outb 0 "0xA00" 0
    sleep 0.1
  done
}

function main() {
  NetBtntimeout=0
  # NetBtnpressed=false
  NetBtnbvalue="$(inb "0xA00" 3)"

  CopyBtntimeout=0
  # CopyBtnpressed=false
  CopyBtnbvalue="$(inb "0xA04" 6)"

  while true; do
    sleep 1
    NetBtncval="$(inb "0xA00" 3)"
    if [ ! "${NetBtncval}" = "${NetBtnbvalue}" ]; then
      # NetBtnpressed=true
      NetBtntimeout=$((NetBtntimeout + 1))
      if [ $((NetBtntimeout % 3)) -eq 0 ]; then
        # NetBtnpressed=false
        NetBtntimeout=0
        #_beep 3 &
        NetBtnOpt3s &
      fi
    else
      # NetBtnpressed=false
      NetBtntimeout=0
    fi

    CopyBtncval="$(inb "0xA04" 6)"
    if [ ! "${CopyBtncval}" = "${CopyBtnbvalue}" ]; then
      # CopyBtnpressed=true
      CopyBtntimeout=$((CopyBtntimeout + 1))
      if [ $((CopyBtntimeout % 3)) -eq 0 ]; then
        # CopyBtnpressed=false
        CopyBtntimeout=0
        #_beep 3 &
        _CopyBtnLed 3 &
        CopyBtnOpt3s &
      fi
    else
      # CopyBtnpressed=false
      CopyBtntimeout=0
    fi
  done

}

main
