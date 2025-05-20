#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

for F in /usr/rr/once.d/*; do
  [ ! -e "${F}" ] && continue
  case "${F}" in
  *.sh)
    (
      trap - INT QUIT TSTP
      set start
      # shellcheck source=/usr/rr/once.d/*
      . "${F}"
    )
    ;;
  *)
    # No sh extension, so fork subprocess.
    chmod +x "${F}" 2>/dev/null
    "${F}" start
    ;;
  esac
done

rm -f /usr/rr/once.d/* 2>/dev/null
