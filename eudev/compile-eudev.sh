#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

#set -x

function makeEnvDeploy() {
  ROOT_PATH=$(realpath "${1}")
  VERSION=${2}
  PLATFORM=${3}

  if [ ! -d "${ROOT_PATH}/pkgscripts-ng" ]; then
    git clone https://github.com/SynologyOpenSource/pkgscripts-ng.git ${ROOT_PATH}/pkgscripts-ng
  fi
  pushd "${ROOT_PATH}/pkgscripts-ng"
  git reset --hard
  git pull
  # if VERSION == 6.2, checkout 6.2.4
  git checkout DSM${VERSION}$([ "${VERSION}" = "6.2" ] && echo ".4")
  sudo ./EnvDeploy -v ${VERSION}$([ "${VERSION}" = "6.2" ] && echo ".4") -l # Get Available PLATFORMs
  sudo ./EnvDeploy -q -v ${VERSION} -p ${PLATFORM}
  RET=$?
  popd
  [ ${RET} -ne 0 ] && echo "EnvDeploy failed." && return 1

  ENV_PATH="${ROOT_PATH}/build_env/ds.${PLATFORM}-${VERSION}"
  sudo cp -al "${ROOT_PATH}/pkgscripts-ng" "${ENV_PATH}/"

  # Fault tolerance of pkgscripts-ng
  if [ "${PLATFORM}" == "broadwellntbap" -a "${VERSION}" == "7.1" ]; then
    sudo sed -i '/		broadwellnk	BROADWELLNK/a\		broadwellntbap  BROADWELLNTBAP                  linux-4.4.x             Intel Broadwell with ntb kernel config in AP mode' ${ENV_PATH}/pkgscripts-ng/include/platforms
  fi

  sudo rm -f script.sh
  cat >script.sh <<"EOF"
#!/bin/env bash
source ~/.bashrc
mkdir -p /source
cd pkgscripts
[ ${1:0:1} -gt 6 ] && sed -i 's/print(" ".join(kernels))/pass #&/' ProjectDepends.py
sed -i '/PLATFORM_FAMILY/a\\techo "PRODUCT=$PRODUCT" >> $file\n\techo "KSRC=$KERNEL_SEARCH_PATH" >> $file\n\techo "LINUX_SRC=$KERNEL_SEARCH_PATH" >> $file' include/build
./SynoBuild -c -p ${2}
while read line; do if [ ${line:0:1} != "#" ]; then export ${line%%=*}="${line#*=}"; fi; done < /env${BUILD_ARCH}.mak
if [ -f "${KSRC}/Makefile" ]; then
  # gcc issue "unrecognized command-line option '--param=allow-store-data-races=0'".
  [ "${1}" == "7.2" ] && sed -i 's/--param=allow-store-data-races=0/--allow-store-data-races/g' ${KSRC}/Makefile
  KVERSION=$(cat ${KSRC}/Makefile | grep ^VERSION | awk -F' ' '{print $3}')
  PATCHLEVEL=$(cat ${KSRC}/Makefile | grep ^PATCHLEVEL | awk -F' ' '{print $3}')
  SUBLEVEL=$(cat ${KSRC}/Makefile | grep ^SUBLEVEL | awk -F' ' '{print $3}')
  [ -f "/env32.mak" ] && echo "KVER=${KVERSION}.${PATCHLEVEL}.${SUBLEVEL}" >>/env32.mak
  [ -f "/env64.mak" ] && echo "KVER=${KVERSION}.${PATCHLEVEL}.${SUBLEVEL}" >>/env64.mak
  CCVER=$($CC --version | head -n 1 | awk -F' ' '{print $3}')
  [ -f "/env32.mak" ] && echo "CCVER=${CCVER}" >>/env32.mak
  [ -f "/env64.mak" ] && echo "CCVER=${CCVER}" >>/env64.mak
fi
EOF
  sudo mv -f script.sh "${ENV_PATH}/script.sh"
  sudo chmod +x "${ENV_PATH}/script.sh"
  sudo chroot "${ENV_PATH}" "/script.sh" "${VERSION}" "${PLATFORM}"
  RET=$?
  [ ${RET} -ne 0 ] && echo "Chroot build failed." && return 1
  return 0
}

function getKver() {
  ROOT_PATH=$(realpath "${1}")
  VERSION=${2}
  PLATFORM=${3}

  ENV_PATH="${ROOT_PATH}/build_env/ds.${PLATFORM}-${VERSION}"
  [ ! -d "${ENV_PATH}" ] && echo "ds.${PLATFORM}-${VERSION} not exist." && return 1

  BUILD_ARCH=$(cat ${ENV_PATH}/root/.bashrc 2>/dev/null | grep BUILD_ARCH | awk -F'=' '{print $2}' | sed "s/'//g")
  KVER=$(cat ${ENV_PATH}/env${BUILD_ARCH}.mak 2>/dev/null | grep KVER | awk -F'=' '{print $2}')
  echo ${KVER}
  return 0
}

function makeeudev() {
  ROOT_PATH=$(realpath "${1}")
  VERSION=${2}
  PLATFORM=${3}
  INPUT=$(realpath "${4}")
  OUTPUT=$(realpath "${5}")

  ENV_PATH="${ROOT_PATH}/build_env/ds.${PLATFORM}-${VERSION}"
  [ ! -d "${ENV_PATH}" ] && echo "ds.${PLATFORM}-${VERSION} not exist." && return 1

  sudo mkdir -p "${ENV_PATH}/source/input"
  sudo mkdir -p "${ENV_PATH}/source/output"
  sudo cp -al "${INPUT}/"* "${ENV_PATH}/source/input/"

  sudo rm -f script.sh
  cat >script.sh <<"EOF"
#!/bin/env bash
source ~/.bashrc
sed -i 's/^CFLAGS=/#CFLAGS=/g; s/^CXXFLAGS=/#CXXFLAGS=/g' /env${BUILD_ARCH}.mak
while read line; do if [ ${line:0:1} != "#" ]; then export ${line%%=*}="${line#*=}"; fi; done < /env${BUILD_ARCH}.mak
# build kmod
git clone -c http.sslVerify=false -b v30 --depth=1 https://github.com/kmod-project/kmod.git
pushd kmod
patch -p1 < /source/input/kmod.patch
./autogen.sh
./configure CC=${CC} CFLAGS='-O2' --host=${HOST} --prefix=/usr --sysconfdir=/etc --libdir=/usr/lib --enable-tools --disable-manpages --disable-python --without-zstd --without-xz --without-zlib --without-openssl
[ -z "$(grep 'env.mak' Makefile)" ] && sed -i '1 i include /env.mak' Makefile
make all
make install
make DESTDIR=/source/output install
popd
# # build 
# cp -f ${ToolChainSysRoot}/usr/lib/libblkid.so.1 /source/output/usr/lib/libblkid.so.1
# git clone -c http.sslVerify=false -b v2.39.3 --depth=1 https://github.com/karelzak/util-linux.git
# pushd util-linux
# ./autogen.sh
# ./configure CC=${CC} CFLAGS='-O2' --host=${HOST} --prefix=/usr --sysconfdir=/etc --libdir=/usr/lib --disable-static --without-ncurses --without-python --disable-asciidoc --disable-all-programs --enable-libblkid
# [ -z "$(grep 'env.mak' Makefile)" ] && sed -i '1 i include /env.mak' Makefile
# sed -i 's/explicit_bzero/\/\/explicit_bzero/g' lib/sha1.c
# make all
# make DESTDIR=/source/output install
# popd
# build eudev
git clone -c http.sslVerify=false --depth=1 https://github.com/systemd/systemd.git
git clone -c http.sslVerify=false -b v3.2.14 --depth=1 https://github.com/eudev-project/eudev.git
cp -vf ./systemd/hwdb.d/*.ids ./systemd/hwdb.d/*.hwdb ./eudev/hwdb/
pushd eudev
# error: 'for' loop initial declarations are only allowed in C99 or C11 mode
if [ "${1}" = "6.2" ]; then
  sed -i 's/for (char \*p/char \*p = NULL; for (p/g' ./src/shared/util.h
  sed -i 's/for (size_t a/size_t a = 0; for(a/g; s/for (size_t i/size_t i = 0; for(i/g; s/for (uint16_t i/uint16_t i = 0; for(i/g' ./src/dmi_memory_id/dmi_memory_id.c
  sed -i 's/for (size_t pos/size_t pos = 0; for (pos/g; s/for (size_t i/size_t i = 0; for(i/g' ./src/fido_id/fido_id_desc.c
fi
./autogen.sh
./configure CC=${CC} CFLAGS='-O2' --host=${HOST} --prefix=/usr --sysconfdir=/etc --disable-manpages --disable-selinux --disable-mtd_probe --enable-kmod
[ -z "$(grep 'env.mak' Makefile)" ] && sed -i '1 i include /env.mak' Makefile
make -i CFLAGS="-DSG_FLAG_LUN_INHIBIT=2" all
make -i CFLAGS="-DSG_FLAG_LUN_INHIBIT=2" DESTDIR=/source/output install
popd
# ldd /source/output/usr/bin/kmod | awk  '{if (match($3,"/")){ printf("%s "),$3 } }'
# ldd /source/output/usr/bin/udevadm | awk  '{if (match($3,"/")){ printf("%s "),$3 } }'
rm -Rf /source/output/usr/share /source/output/usr/include /source/output/usr/lib/pkgconfig /source/output/usr/lib/libudev.* /source/output/usr/lib/*.a /source/output/usr/lib/*.la
ln -sf /usr/bin/kmod /source/output/usr/sbin/depmod
cp -f /source/input/50-usb-realtek-net.rules /source/output/usr/lib/udev/rules.d/50-usb-realtek-net.rules
mv -f /source/output/usr/lib/udev/rules.d/60-persistent-storage.rules /source/output/usr/lib/udev/rules.d/60-persistent-storage.rules.bak
mv -f /source/output/usr/lib/udev/rules.d/60-persistent-storage-tape.rules /source/output/usr/lib/udev/rules.d/60-persistent-storage-tape.rules.bak
mv -f /source/output/usr/lib/udev/rules.d/80-net-name-slot.rules /source/output/usr/lib/udev/rules.d/80-net-name-slot.rules.bak
chown 1000.1000 -R /source/output
EOF
  sudo mv -f script.sh "${ENV_PATH}/script.sh"
  sudo chmod +x "${ENV_PATH}/script.sh"
  sudo chroot "${ENV_PATH}" "/script.sh" "${VERSION}" "${PLATFORM}"
  [ $? -ne 0 ] && echo "Chroot build failed." && return 1

  mkdir -p "${OUTPUT}"
  sudo cp -a "${ENV_PATH}/source/output/"* "${OUTPUT}/"
  return 0
}
