#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# 
# all\usr\bin\kmod  # will be overwritten by eudev.
#     ver: 30
#     url: DSM_HD6500_69057\rd\usr\bin\kmod
#     ldd: 

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# yq
TAG="$(curl -skL "https://github.com/mikefarah/yq/tags" | grep "/refs/tags/.*\.zip" | head -1 | sed -E 's/.*\/refs\/tags\/(.*)\.zip.*$/\1/')"
echo "Downloading yq ${TAG}"
curl -#kL "https://github.com/mikefarah/yq/releases/download/${TAG}/yq_linux_amd64" -o ${ROOT_PATH}/all/usr/bin/yq

# pup
TAG="$(curl -skL "https://github.com/ericchiang/pup/tags" | grep "/refs/tags/.*\.zip" | head -1 | sed -E 's/.*\/refs\/tags\/(.*)\.zip.*$/\1/')"
echo "Downloading pup ${TAG}"
curl -#kL "https://github.com/ericchiang/pup/releases/download/${TAG}/pup_${TAG}_linux_amd64.zip" -o ${ROOT_PATH}/pup.zip && { unzip -o ${ROOT_PATH}/pup.zip -d ${ROOT_PATH}/all/usr/bin/ >/dev/null 2>&1; rm -f ${ROOT_PATH}/pup.zip; }

# ttyd
TAG="$(curl -skL "https://github.com/tsl0922/ttyd/tags" | grep "/refs/tags/.*\.zip" | head -1 | sed -E 's/.*\/refs\/tags\/(.*)\.zip.*$/\1/')"
echo "Downloading ttyd ${TAG}"
curl -#kL "https://github.com/tsl0922/ttyd/releases/download/${TAG}/ttyd.x86_64" -o ${ROOT_PATH}/all/usr/sbin/ttyd

# dufs
TAG="$(curl -skL "https://github.com/sigoden/dufs/tags" | grep "/refs/tags/.*\.zip" | head -1 | sed -E 's/.*\/refs\/tags\/(.*)\.zip.*$/\1/')"
echo "Downloading dufs ${TAG}"
curl -#kL "https://github.com/sigoden/dufs/releases/download/${TAG}/dufs-${TAG}-x86_64-unknown-linux-musl.tar.gz" | tar -zxf - -C ${ROOT_PATH}/all/usr/sbin/ dufs

# inxi
echo "Downloading inxi"
curl -#kL https://codeberg.org/smxi/inxi/raw/branch/master/inxi -o ${ROOT_PATH}/all/usr/sbin/inxi
