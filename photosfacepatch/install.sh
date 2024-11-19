#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing addon photosfacepatch - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -pf "${0}" "/tmpRoot/usr/rr/addons/"

  cp -vpf /usr/bin/PatchELFSharp /tmpRoot/usr/bin/PatchELFSharp
  cp -vpf /usr/bin/photosfacepatch.sh /tmpRoot/usr/bin/photosfacepatch.sh

  mkdir -p "/tmpRoot/usr/lib/systemd/system"
  DEST="/tmpRoot/usr/lib/systemd/system/photosfacepatch.service"
  {
    echo "[Unit]"
    echo "Description=Enable face recognition in Synology Photos"
    echo "After=syno-volume.target syno-space.target"
    echo
    echo "[Service]"
    echo "Type=oneshot"
    echo "RemainAfterExit=yes"
    echo "ExecStart=-/usr/bin/photosfacepatch.sh"
    echo
    echo "[Install]"
    echo "WantedBy=multi-user.target"
  } >"${DEST}"

  mkdir -vp /tmpRoot/usr/lib/systemd/system/multi-user.target.wants
  ln -vsf /usr/lib/systemd/system/photosfacepatch.service /tmpRoot/usr/lib/systemd/system/multi-user.target.wants/photosfacepatch.service
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon photosfacepatch - ${1}"

  rm -f /tmpRoot/usr/bin/PatchELFSharp

  rm -f "/tmpRoot/usr/lib/systemd/system/multi-user.target.wants/photosfacepatch.service"
  rm -f "/tmpRoot/usr/lib/systemd/system/photosfacepatch.service"

  [ ! -f "/tmpRoot/usr/rr/revert.sh" ] && echo '#!/usr/bin/env bash' >/tmpRoot/usr/rr/revert.sh && chmod +x /tmpRoot/usr/rr/revert.sh
  echo "/usr/bin/photosfacepatch.sh -r" >>/tmpRoot/usr/rr/revert.sh
  echo "rm -f /usr/bin/photosfacepatch.sh" >>/tmpRoot/usr/rr/revert.sh
fi
