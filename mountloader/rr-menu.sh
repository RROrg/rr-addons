#!/usr/bin/env bash

wget -O - http://bin.entware.net/x64-k3.2/installer/generic.sh | /bin/sh
/opt/bin/opkg update
/opt/bin/opkg install cpio dialog ttyd

curl -kL https://raw.githubusercontent.com/wjz304/rr-addons/main/yq -o ~/yq
mv -f ~/yq /usr/bin/yq
chmod a+x /usr/bin/yq 

export PATH=$PATH:/opt/bin

echo 1 > /proc/sys/kernel/syno_install_flag

LOADER_DISK_PART3="$(blkid -L RR3 | cut -d':' -f1)"
LOADER_DISK_PART2="${LOADER_DISK_PART3/3/2}"
LOADER_DISK_PART1="${LOADER_DISK_PART3/3/1}"
LOADER_DISK="/dev/$(realpath /sys/block/*/${LOADER_DISK_PART3/\/dev\//} | awk -F'/' '{print $(NF-1)}')"

# Make folders to mount partitions
mkdir -p /mnt/p1
mkdir -p /mnt/p2
mkdir -p /mnt/p3
mount ${LOADER_DISK_PART1} /mnt/p1 2>/dev/null || (
  echo "Can't mount ${LOADER_DISK_PART1}"
)
mount ${LOADER_DISK_PART2} /mnt/p2 2>/dev/null || (
  echo "Can't mount ${LOADER_DISK_PART2}"
)
mount ${LOADER_DISK_PART3} /mnt/p3 2>/dev/null || (
  echo "Can't mount ${LOADER_DISK_PART3}"
)

export LOADER_DISK="${LOADER_DISK}"
export LOADER_DISK_PART1="${LOADER_DISK_PART1}"
export LOADER_DISK_PART2="${LOADER_DISK_PART2}"
export LOADER_DISK_PART3="${LOADER_DISK_PART3}"

RR_RAMDISK_FILE="/mnt/p3/initrd-rr"
RR_PATH="/tmp/initrd"
mkdir -p "${RR_PATH}"
(
  cd "${RR_PATH}"
  xz -dc <"${RR_RAMDISK_FILE}" | cpio -idm
) >/dev/null 2>&1 || true

cd ${RR_PATH}/opt/rr
/opt/bin/ttyd -t enableZmodem=true -t enableSixel=true -t enableTrzsz=true login -f root 
