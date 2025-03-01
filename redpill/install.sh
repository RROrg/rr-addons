#!/usr/bin/env sh
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

PLATFORMS="epyc7002"
PLATFORM="$(/bin/get_key_value /etc.defaults/synoinfo.conf unique | cut -d"_" -f2)"
if ! echo "${PLATFORMS}" | grep -wq "${PLATFORM}"; then
  echo "${PLATFORM} is not supported redpill addon!"
  exit 0
fi

if [ "${1}" = "early" ]; then
  echo "Installing addon redpill - ${1}"

  insmod /usr/lib/modules/rp.ko

elif [ "${1}" = "jrExit" ]; then
  echo "Installing addon redpill - ${1}"

  #rmmod redpill
fi
