#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

set -e

[ -f all/usr/sbin/synoscgiproxy ] && exit 0

if ! command -v go >/dev/null 2>&1; then
  apt update
  apt install -y golang-go
fi

mkdir -p all/usr/sbin
go build -o all/usr/sbin/synoscgiproxy src/synoscgiproxy.go
