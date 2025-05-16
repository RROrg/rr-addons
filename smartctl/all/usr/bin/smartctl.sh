#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

args=()
for arg in "$@"; do [[ "$arg" = "ata" ]] && args+=("auto") || args+=("$arg"); done # 替换参数中的 ata 为 auto
/usr/bin/smartctl.bak "${args[@]}"
