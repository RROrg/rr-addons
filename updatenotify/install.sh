#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "late" ]; then
  echo "Installing addon updatenotify - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"
  
  cp -vf /usr/bin/pup /tmpRoot/usr/bin/pup
  cp -vf /usr/bin/rr-updatenotify.sh /tmpRoot/usr/bin/rr-updatenotify.sh
  
  mkdir -p "/tmpRoot/usr/lib/systemd/system"
  DEST="/tmpRoot/usr/lib/systemd/system/rr-updatenotify.service"
  echo "[Unit]"                                         >${DEST}
  echo "Description=addon rr-updatenotify"             >>${DEST}
  echo "After=multi-user.target"                       >>${DEST}
  echo                                                 >>${DEST}
  echo "[Service]"                                     >>${DEST}
  echo "Type=oneshot"                                  >>${DEST}
  echo "RemainAfterExit=yes"                           >>${DEST}
  echo "ExecStart=-/usr/bin/rr-updatenotify.sh create" >>${DEST}
  echo                                                 >>${DEST}
  echo "[Install]"                                     >>${DEST}
  echo "WantedBy=multi-user.target"                    >>${DEST}

  mkdir -vp /tmpRoot/usr/lib/systemd/system/multi-user.target.wants
  ln -vsf /usr/lib/systemd/system/rr-updatenotify.service /tmpRoot/usr/lib/systemd/system/multi-user.target.wants/rr-updatenotify.service
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon rr-updatenotify - ${1}"

  rm -f "/tmpRoot/usr/lib/systemd/system/multi-user.target.wants/rr-updatenotify.service"
  rm -f "/tmpRoot/usr/lib/systemd/system/rr-updatenotify.service"

  [ ! -f "/tmpRoot/usr/rr/revert.sh" ] && echo '#!/usr/bin/env bash' >/tmpRoot/usr/rr/revert.sh && chmod +x /tmpRoot/usr/rr/revert.sh
  echo "/usr/bin/rr-updatenotify.sh delete" >>/tmpRoot/usr/rr/revert.sh
  echo "rm -f /usr/bin/pup /usr/bin/rr-updatenotify.sh" >>/tmpRoot/usr/rr/revert.sh
fi
