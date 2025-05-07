#!/usr/bin/env sh
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# shellcheck disable=SC2010

if [ "${1}" = "early" ]; then
  echo "Installing addon tad6s4n10g - ${1}"

  if [ ! "$(/bin/get_key_value /etc/synoinfo.conf supportportmappingv2)" = "yes" ]; then
    echo "non-DT models is not supported tad6s4n10g addon early!"
    exit 0
  fi

  UNIQUE="$(/bin/get_key_value /etc.defaults/synoinfo.conf unique)"
  DEST="/addons/model.dts"
  mkdir -p "$(dirname "${DEST}" 2>/dev/null)"
  {
    echo "/dts-v1/;"
    echo "/ {"
    echo "    compatible = \"Synology\";"
    echo "    model = \"${UNIQUE}\";"
    echo "    version = <0x01>;"
    echo "    power_limit = \"\";"
  } >"${DEST}"

  COUNT=0
  # 02:00.0 SATA controller [0106]: ASMedia Technology Inc. ASM1166 Serial ATA Controller [1b21:1166] (rev 02)
  # removing the mlx5 network card 0000:00:1c.0,00.0
  # inserting the mlx5 network card 0000:00:1c.2,00.0
  ls -ld /sys/block/sata* 2>/dev/null | grep -q "0000:00:1c.0" && PCIEPATH=0000:00:1c.0,00.0 || PCIEPATH=0000:00:1c.2,00.0
  for I in $(seq 5 -1 0); do
    COUNT=$((${COUNT} + 1))
    {
      echo "    internal_slot@${COUNT} {"
      echo "        protocol_type = \"sata\";"
      echo "        ahci {"
      echo "            pcie_root = \"${PCIEPATH}\";"
      echo "            ata_port = <0x$(printf '%02X' ${I})>;"
      echo "        };"
      echo "    };"
    } >>"${DEST}"
  done
  # 00:17.0 SATA controller [0106]: Intel Corporation Device [8086:54d3]
  PCIEPATH=0000:00:17.0
  NGFF_NUM=$(ls -ld /sys/block/sata* 2>/dev/null | grep -c "0000:00:17.0")
  if [ "${NGFF_NUM:-0}" -gt 0 ]; then
    for I in $(seq 0 $((${NGFF_NUM} - 1))); do
      COUNT=$((${COUNT} + 1))
      {
        echo "    internal_slot@${COUNT} {"
        echo "        protocol_type = \"sata\";"
        echo "        ahci {"
        echo "            pcie_root = \"${PCIEPATH}\";"
        echo "            ata_port = <0x$(printf '%02X' ${I})>;"
        echo "        };"
        echo "    };"
      } >>"${DEST}"
    done
  fi

  COUNT=0
  # 04:00.0 Non-Volatile memory controller [0108]: Device [1ed0:2283]
  PCIEPATH=0000:00:1d.0,00.0
  NVME_NUM=$((4 - ${NGFF_NUM:-0}))
  POWER_LIMIT=""
  if [ "${NVME_NUM:-0}" -gt 0 ]; then
    for I in $(seq 0 $((${NVME_NUM} - 1))); do
      POWER_LIMIT="${POWER_LIMIT:+${POWER_LIMIT},}0"
      COUNT=$((${COUNT} + 1))
      {
        echo "    nvme_slot@${COUNT} {"
        echo "        pcie_root = \"${PCIEPATH}\";"
        echo "        port_type = \"ssdcache\";"
        echo "    };"
      } >>"${DEST}"
    done
  fi
  [ -n "${POWER_LIMIT}" ] && sed -i "s/power_limit = .*/power_limit = \"${POWER_LIMIT}\";/" "${DEST}" || sed -i '/power_limit/d' "${DEST}"

  COUNT=0
  # usb
  for I in 1-1 2-1.1 2-1.2 2-1.3 2-1.4 3-3.1 3-3.2 3-3.3 3-3.4 4-1 4-2 4-3 4-4; do
    COUNT=$((${COUNT} + 1))
    {
      echo "    usb_slot@${COUNT} {"
      echo "      usb2 {"
      echo "        usb_port = \"${I}\";"
      echo "      };"
      echo "      usb3 {"
      echo "        usb_port = \"${I}\";"
      echo "      };"
      echo "    };"
    } >>"${DEST}"
  done

  echo "};" >>"${DEST}"

elif [ "${1}" = "late" ]; then
  echo "Installing addon tad6s4n10g - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -pf "${0}" "/tmpRoot/usr/rr/addons/"

  cp -vpf /usr/bin/tad6s4n10g.sh /tmpRoot/usr/bin/tad6s4n10g.sh
  cp -vpf /usr/sbin/ioperm /tmpRoot/usr/sbin/ioperm
  cp -vpf /usr/sbin/inb /tmpRoot/usr/sbin/inb
  cp -vpf /usr/sbin/outb /tmpRoot/usr/sbin/outb

  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  ESYNOSCHEDULER_DB="/tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db"
  if [ ! -f "${ESYNOSCHEDULER_DB}" ] || ! /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" ".tables" | grep -wq "task"; then
    echo "copy esynoscheduler.db"
    mkdir -p "$(dirname "${ESYNOSCHEDULER_DB}")"
    cp -vpf /addons/esynoscheduler.db "${ESYNOSCHEDULER_DB}"
  fi
  if echo "SELECT * FROM task;" | /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" | grep -q "Net-Button"; then
    echo "Net-Button task already exists"
  else
    echo "insert Net-Button task to esynoscheduler.db"
    /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" <<EOF
DELETE FROM task WHERE task_name LIKE 'Net-Button';
INSERT INTO task VALUES('Net-Button', '', 'bootup', '', 0, 0, 0, 0, '', 0, '
# Please enter the command to be executed when the Net-Button is pressed.
echo "This person is lazy, he does not want to write anything."
', 'script', '{}', '', '', '{}', '{}');
EOF
  fi
  if echo "SELECT * FROM task;" | /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" | grep -q "Copy-Button"; then
    echo "Copy-Button task already exists"
  else
    echo "insert Copy-Button task to esynoscheduler.db"
    /tmpRoot/bin/sqlite3 "${ESYNOSCHEDULER_DB}" <<EOF
DELETE FROM task WHERE task_name LIKE 'Copy-Button';
INSERT INTO task VALUES('Copy-Button', '', 'bootup', '', 0, 0, 0, 0, '', 0, '
# Please enter the command to be executed when the Copy-Button is pressed.
echo "This person is lazy, he does not want to write anything."
', 'script', '{}', '', '', '{}', '{}');
EOF
  fi
  mkdir -p "/tmpRoot/usr/lib/systemd/system"
  DEST="/tmpRoot/usr/lib/systemd/system/tad6s4n10g.service"
  {
    echo "[Unit]"
    echo "Description=RR addon tad6s4n10g daemon"
    echo "After=multi-user.target"
    echo
    echo "[Service]"
    echo "Type=forking"
    echo "ExecStart=/usr/bin/tad6s4n10g.sh"
    echo "ExecReload=pkill -f /usr/bin/tad6s4n10g.sh"
    echo "Restart=always"
    echo
    echo "[Install]"
    echo "WantedBy=multi-user.target"
  } >"${DEST}"

  mkdir -vp /tmpRoot/usr/lib/systemd/system/multi-user.target.wants
  ln -vsf /usr/lib/systemd/system/tad6s4n10g.service /tmpRoot/usr/lib/systemd/system/multi-user.target.wants/tad6s4n10g.service
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon tad6s4n10g - ${1}"

  rm -f "/tmpRoot/usr/lib/systemd/system/multi-user.target.wants/tad6s4n10g.service"
  rm -f "/tmpRoot/usr/lib/systemd/system/tad6s4n10g.service"

  rm -f /tmpRoot/usr/bin/tad6s4n10g.sh
  rm -f /tmpRoot/usr/sbin/ioperm
  rm -f /tmpRoot/usr/sbin/inb
  rm -f /tmpRoot/usr/sbin/outb

  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  ESYNOSCHEDULER_DB="/tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db"
  if [ -f "${ESYNOSCHEDULER_DB}" ]; then
    echo "delete beep task from esynoscheduler.db"
    CopyBtn"${ESYNOSCHEDULER_DB}" <<EOF
DELETE FROM task WHERE task_name LIKE 'Net-Button';
DELETE FROM task WHERE task_name LIKE 'Copy-Button';
EOF
  fi
fi
