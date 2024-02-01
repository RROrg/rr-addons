#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Installing addon cpuinfo - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"
  
  cp -vf /usr/bin/cpuinfo.sh /tmpRoot/usr/bin/cpuinfo.sh
  shift
  DEST="/tmpRoot/usr/lib/systemd/system/cpuinfo.service"
  echo "[Unit]"                                    >${DEST}
  echo "Description=Adds correct CPU Info"        >>${DEST}
  echo "After=multi-user.target"                  >>${DEST}
  echo                                            >>${DEST}
  echo "[Service]"                                >>${DEST}
  echo "Type=oneshot"                             >>${DEST}
  echo "RemainAfterExit=true"                     >>${DEST}
  echo "ExecStart=/usr/bin/cpuinfo.sh $@"         >>${DEST}
  echo                                            >>${DEST}
  echo "[Install]"                                >>${DEST}
  echo "WantedBy=multi-user.target"               >>${DEST}

  mkdir -vp /tmpRoot/lib/systemd/system/multi-user.target.wants
  ln -vsf /usr/lib/systemd/system/cpuinfo.service /tmpRoot/lib/systemd/system/multi-user.target.wants/cpuinfo.service
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon cpuinfo - ${1}"

  rm -f "/tmpRoot/lib/systemd/system/multi-user.target.wants/cpuinfo.service"
  rm -f "/tmpRoot/usr/lib/systemd/system/cpuinfo.service"

  [ ! -f "/tmpRoot/usr/rr/revert.sh" ] && echo '#!/usr/bin/env bash' >/tmpRoot/usr/rr/revert.sh && chmod +x /tmpRoot/usr/rr/revert.sh
  echo "/usr/bin/cpuinfo.sh -r" >>/tmpRoot/usr/rr/revert.sh
  echo "rm -f /usr/bin/cpuinfo.sh" >>/tmpRoot/usr/rr/revert.sh
fi
