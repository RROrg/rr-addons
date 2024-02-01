#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.

MajorVersion=$(/bin/get_key_value /etc.defaults/VERSION majorversion)
MinorVersion=$(/bin/get_key_value /etc.defaults/VERSION minorversion)

if [ "${1}" = "late" ]; then
  echo "Installing addon acpid - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"

  mkdir -p /tmpRoot/etc/acpi/events/
  # [ ! -f /tmpRoot/etc/acpi/events/power.bak -a -f /tmpRoot/etc/acpi/events/power ] && cp -vf /tmpRoot/etc/acpi/events/power /tmpRoot/etc/acpi/events/power.bak
  # [ ! -f /tmpRoot/etc/acpi/power.sh.bak -a -f /tmpRoot/etc/acpi/power.sh ] && cp -vf /tmpRoot/etc/acpi/power.sh /tmpRoot/etc/acpi/power.sh.bak
  # [ ! -f /tmpRoot/usr/sbin/acpid.bak -a -f /tmpRoot/usr/sbin/acpid ] && cp -vf /tmpRoot/usr/sbin/acpid /tmpRoot/usr/sbin/acpid.bak
  cp -vf /etc/acpi/events/power /tmpRoot/etc/acpi/events/power
  cp -vf /etc/acpi/power.sh /tmpRoot/etc/acpi/power.sh
  cp -vf /usr/sbin/acpid /tmpRoot/usr/sbin/acpid
  cp -vf /usr/lib/modules/button.ko /tmpRoot/usr/lib/modules/button.ko

  if [ ${MajorVersion:-0} -lt 7 ]; then # < 7
    mkdir -p /tmpRoot/etc/init
    DEST="/tmpRoot/etc/init/acpid.conf"
    echo 'description "addon acpid"'                     >${DEST}
    echo 'author "Virtualization Team"'                 >>${DEST}
    echo 'start on runlevel 1'                          >>${DEST}
    echo 'stop on runlevel [06]'                        >>${DEST}
    echo 'expect fork'                                  >>${DEST}
    echo 'respawn'                                      >>${DEST}
    echo 'respawn limit 5 10'                           >>${DEST}
    echo 'console log'                                  >>${DEST}
    echo 'pre-start script'                             >>${DEST}
    echo '    date'                                     >>${DEST}
    echo '    insmod /lib/modules/button.ko'            >>${DEST}
    echo 'end script'                                   >>${DEST}
    echo 'post-stop script'                             >>${DEST}
    echo '    rmmod button'                             >>${DEST}
    echo 'end script'                                   >>${DEST}
    echo 'exec /usr/sbin/acpid'                         >>${DEST}
  else
    DEST="/tmpRoot/usr/lib/systemd/system/acpid.service"
    echo "[Unit]"                                        >${DEST}
    echo "Description=addon acpid"                      >>${DEST}
    echo "DefaultDependencies=no"                       >>${DEST}
    echo "IgnoreOnIsolate=true"                         >>${DEST}
    echo "After=multi-user.target"                      >>${DEST}
    echo                                                >>${DEST}
    echo "[Service]"                                    >>${DEST}
    echo "Restart=always"                               >>${DEST}
    echo "RestartSec=30"                                >>${DEST}
    echo "ExecStartPre=-/usr/sbin/modprobe button"      >>${DEST}
    echo "ExecStart=/usr/sbin/acpid -f"                 >>${DEST}
    echo "ExecStopPost=-/usr/sbin/modprobe -r button"   >>${DEST}
    echo                                                >>${DEST}
    echo "[X-Synology]"                                 >>${DEST}
    echo "Author=Virtualization Team"                   >>${DEST}

    mkdir -vp /tmpRoot/lib/systemd/system/multi-user.target.wants
    ln -vsf /usr/lib/systemd/system/acpid.service /tmpRoot/lib/systemd/system/multi-user.target.wants/acpid.service
  fi
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon acpid - ${1}"

  if [ ${MajorVersion:-0} -lt 7 ]; then # < 7
    rm -f "/tmpRoot/etc/init/acpid.conf"
  else
    rm -f "/tmpRoot/lib/systemd/system/multi-user.target.wants/acpid.service"
    rm -f "/tmpRoot/usr/lib/systemd/system/acpid.service"
  fi

  rm -f /tmpRoot/etc/acpi/events/power
  rm -f /tmpRoot/etc/acpi/power.sh
  rm -f /tmpRoot/usr/sbin/acpid
  # [ -f /tmpRoot/etc/acpi/events/power.bak ] && mv -vf /tmpRoot/etc/acpi/events/power.bak /tmpRoot/etc/acpi/events/power
  # [ -f /tmpRoot/etc/acpi/power.sh.bak ] && mv -vf /tmpRoot/etc/acpi/power.sh.bak /tmpRoot/etc/acpi/power.sh
  # [ -f /tmpRoot/usr/sbin/acpid.bak ] && mv -vf /tmpRoot/usr/sbin/acpid.bak /tmpRoot/usr/sbin/acpid
fi
