#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

set -e

[ -f all/usr/sbin/powersched ] && exit 0

mkdir -p all/usr/sbin
make -C src clean all
cp -pf src/powersched all/usr/sbin
