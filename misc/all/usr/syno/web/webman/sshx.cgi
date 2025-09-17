#!/usr/bin/env sh
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# shellcheck disable=SC3037

echo -en "Content-type: text/plain; charset=\"UTF-8\"\r\n\r\n"

if ps -aux | grep -v grep | grep -q sshx; then
  kill "$(ps -aux | grep -v grep | grep sshx | awk '{print $2}')"
  echo "sshx is killed"
  exit 0
else
  sshx -q --name "RR-Helper" 2>&1 &
  sleep 1
  echo "sshx is started"
fi
