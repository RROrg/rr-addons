#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Installing daemon for expands"
  cp -vf /usr/bin/expands.sh /tmpRoot/usr/bin/expands.sh

  DEST="/tmpRoot/usr/lib/systemd/system/expands.service"
  echo "[Unit]"                                    >${DEST}
  echo "Description=Expanded miscellaneous"       >>${DEST}
  echo "After=multi-user.target"                  >>${DEST}
  echo                                            >>${DEST}
  echo "[Service]"                                >>${DEST}
  echo "Type=oneshot"                             >>${DEST}
  echo "RemainAfterExit=true"                     >>${DEST}
  echo "ExecStart=/usr/bin/expands.sh"            >>${DEST}
  echo                                            >>${DEST}
  echo "[Install]"                                >>${DEST}
  echo "WantedBy=multi-user.target"               >>${DEST}

  mkdir -vp /tmpRoot/lib/systemd/system/multi-user.target.wants
  ln -vsf /usr/lib/systemd/system/expands.service /tmpRoot/lib/systemd/system/multi-user.target.wants/expands.service
fi
