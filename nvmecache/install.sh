#!/usr/bin/env ash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

MODELS="DS918+ RS1619xs+ DS419+ DS1019+ DS719+ DS1621xs+"
MODEL=$(cat /proc/sys/kernel/syno_hw_version)

if [ "${1}" = "patches" ]; then
  echo "Installing addon nvmecache - ${1}"

  if ! echo ${MODELS} | grep -q ${MODEL}; then
    echo "${MODEL} is not in models"
    exit 0
  fi
  BOOTDISK=""
  BOOTDISK_PART3=$(blkid -L RR3 | sed 's/\/dev\///')
  [ -n "${BOOTDISK_PART3}" ] && BOOTDISK=$(ls -d /sys/block/*/${BOOTDISK_PART3} 2>/dev/null | cut -d'/' -f4)
  [ -n "${BOOTDISK}" ] && BOOTDISK_PHYSDEVPATH="$(cat /sys/block/${BOOTDISK}/uevent | grep 'PHYSDEVPATH' | cut -d'=' -f2)" || BOOTDISK_PHYSDEVPATH=""
  echo "BOOTDISK=${BOOTDISK}"
  echo "BOOTDISK_PHYSDEVPATH=${BOOTDISK_PHYSDEVPATH}"
  rm -f /etc/nvmePorts
  for P in $(ls -d /sys/block/nvme* 2>/dev/null); do
    if [ -n "${BOOTDISK_PHYSDEVPATH}" -a "${BOOTDISK_PHYSDEVPATH}" = "$(cat ${P}/uevent | grep 'PHYSDEVPATH' | cut -d'=' -f2)" ]; then
      echo "bootloader: ${P}"
      continue
    fi
    PCIEPATH=$(cat ${P}/uevent 2>/dev/null | grep 'PHYSDEVPATH' | cut -d'/' -f4)
    if [ -n "${PCIEPATH}" ]; then
      # TODO: Need check?
      MULTIPATH=$(cat ${P}/uevent 2>/dev/null | grep 'PHYSDEVPATH' | cut -d'/' -f5)
      if [ -z "${MULTIPATH}" ]; then
        echo "${PCIEPATH} does not support!"
        continue
      fi
      echo "${PCIEPATH}" >>/etc/nvmePorts
    fi
  done
  [ -f /etc/nvmePorts ] && cat /etc/nvmePorts
elif [ "${1}" = "late" ]; then
  echo "Installing addon nvmecache - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"

  if ! echo ${MODELS} | grep -q ${MODEL}; then
    echo "${MODEL} is not in models"
    exit 0
  fi
  #
  # |       models      |     1st      |     2nd      |
  # | DS918+            | 0000:00:13.1 | 0000:00:13.2 |
  # | RS1619xs+         | 0000:00:03.2 | 0000:00:03.3 |
  # | DS419+, DS1019+   | 0000:00:14.1 |              |
  # | DS719+, DS1621xs+ | 0000:00:01.1 | 0000:00:01.0 |
  #
  # In the late stage, the /sys/ directory does not exist, and the device path cannot be obtained.
  # (/dev/ does exist, but there is no useful information.)
  # (The information obtained by lspci is incomplete and an error will be reported.)
  # Therefore, the device path is obtained in the early stage and stored in /etc/nvmePorts.
  declare -A PCI1ST
  PCI1ST[0]=$(echo -n "0000:00:13.1" | xxd -ps)
  PCI1ST[1]=$(echo -n "0000:00:03.2" | xxd -ps)
  PCI1ST[2]=$(echo -n "0000:00:14.1" | xxd -ps)
  PCI1ST[3]=$(echo -n "0000:00:01.1" | xxd -ps)
  declare -A PCI2ND
  PCI2ND[0]=$(echo -n "0000:00:13.2" | xxd -ps)
  PCI2ND[1]=$(echo -n "0000:00:03.3" | xxd -ps)
  PCI2ND[2]=$(echo -n "0000:00:99.9" | xxd -ps) # dummy
  PCI2ND[3]=$(echo -n "0000:00:01.0" | xxd -ps)

  SO_FILE="/tmpRoot/usr/lib/libsynonvme.so.1"
  [ ! -f "${SO_FILE}.bak" ] && cp -vf "${SO_FILE}" "${SO_FILE}.bak"
  
  cp -vf "${SO_FILE}.bak" "${SO_FILE}"
  num=1
  for N in $(cat /etc/nvmePorts 2>/dev/null); do
    LOCHEX=$(echo -n "${N}" | xxd -c 256 -ps)
    echo "${num} - ${N} - ${LOCHEX}"
    if [ ${num} -eq 1 ]; then
      xxd -c $(xxd -p "${SO_FILE}" | wc -c) -p "${SO_FILE}" > "so.hex"
      sed -i "s/${PCI1ST[0]}/$LOCHEX/; s/${PCI1ST[1]}/$LOCHEX/; s/${PCI1ST[2]}/$LOCHEX/; s/${PCI1ST[3]}/$LOCHEX/" "so.hex" 
      xxd -r -p "so.hex" "${SO_FILE}"
      rm -f "so.hex"
    elif [ ${num} -eq 2 ]; then
      xxd -c $(xxd -p "${SO_FILE}" | wc -c) -p "${SO_FILE}" > "so.hex" 
      sed -i "s/${PCI2ND[0]}/$LOCHEX/; s/${PCI2ND[1]}/$LOCHEX/; s/${PCI2ND[2]}/$LOCHEX/; s/${PCI2ND[3]}/$LOCHEX/" "so.hex" 
      xxd -r -p "so.hex" "${SO_FILE}"
      rm -f "so.hex"
    else
      break
    fi
    num=$((num + 1))
  done
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon nvmecache - ${1}"

  if ! echo ${MODELS} | grep -q ${MODEL}; then
    echo "${MODEL} is not in models"
    exit 0
  fi

  SO_FILE="/tmpRoot/usr/lib/libsynonvme.so.1"
  [ -f "${SO_FILE}.bak" ] && mv -f "${SO_FILE}.bak" "${SO_FILE}"
fi
