#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Installing addon lsiutil - ${1}"
  mkdir -p "/tmpRoot/usr/rr/addons/"
  cp -vf "${0}" "/tmpRoot/usr/rr/addons/"
  
  cp -vf /usr/sbin/lsiutil /tmpRoot/usr/sbin/lsiutil
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon lsiutil - ${1}"

  rm -f "/tmpRoot/usr/sbin/lsiutil"
fi
