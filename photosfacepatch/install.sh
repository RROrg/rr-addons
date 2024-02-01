#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Installing addon photosfacepatch - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"
  
  if [ -f "/tmpRoot/usr/lib/libsynosdk.so.7" ]; then
    if [ ! -f "/tmpRoot/usr/lib/libsynosdk.so.7.bak" ]; then
      echo "Backup libsynosdk.so.7"
      cp -vfp "/tmpRoot/usr/lib/libsynosdk.so.7" "/tmpRoot/usr/lib/libsynosdk.so.7.bak"
    fi
    echo "Patching libsynosdk.so.7"
    PatchELFSharp "/tmpRoot/usr/lib/libsynosdk.so.7" "SYNOFSIsRemoteFS" "B8 00 00 00 00 C3"
  else
    echo "libsynosdk.so.7 not found"
  fi
  if [ -f "/tmpRoot/var/packages/SynologyPhotos/target/usr/lib/libsynophoto-plugin-platform.so" ]; then
    if [ ! -f "/tmpRoot/var/packages/SynologyPhotos/target/usr/lib/libsynophoto-plugin-platform.so.bak" ]; then
      echo "Backup libsynophoto-plugin-platform.so"
      cp -vfp "/tmpRoot/var/packages/SynologyPhotos/target/usr/lib/libsynophoto-plugin-platform.so" "/tmpRoot/var/packages/SynologyPhotos/target/usr/lib/libsynophoto-plugin-platform.so.bak"
    fi
    echo "Patching libsynophoto-plugin-platform.so"
    PatchELFSharp "/tmpRoot/var/packages/SynologyPhotos/target/usr/lib/libsynophoto-plugin-platform.so" "_ZN9synophoto6plugin8platform20IsSupportedIENetworkEv" "B8 00 00 00 00 C3"
  else
    echo "libsynophoto-plugin-platform.so not found"
  fi
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon photosfacepatch - ${1}"

  if [ -f "/tmpRoot/usr/lib/libsynosdk.so.7.bak" ]; then
    echo "Restore libsynosdk.so.7"
    mv -f "/tmpRoot/usr/lib/libsynosdk.so.7.bak" "/tmpRoot/usr/lib/libsynosdk.so.7"
  fi
  if [ -f "/tmpRoot/var/packages/SynologyPhotos/target/usr/lib/libsynophoto-plugin-platform.so.bak" ]; then
    echo "Restore libsynophoto-plugin-platform.so"
    mv -f "/tmpRoot/var/packages/SynologyPhotos/target/usr/lib/libsynophoto-plugin-platform.so.bak" "/tmpRoot/var/packages/SynologyPhotos/target/usr/lib/libsynophoto-plugin-platform.so"
  fi
fi
