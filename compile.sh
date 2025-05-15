#!/usr/bin/env bash

# shellcheck disable=SC2115

set -e

[ -z "${WORK_PATH}" ] || [ ! -d "${WORK_PATH}" ] && WORK_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

TEMP_PATH="/tmp"

if ! type yq >/dev/null 2>&1 || ! yq --version 2>/dev/null | grep -q "v4."; then
  sudo curl -kL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/bin/yq && sudo chmod a+x /usr/bin/yq
fi

###############################################################################
# Read key value from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Return Value
function readConfigKey() {
  result=$(yq eval ".${1} | explode(.)" "${2}" 2>/dev/null)
  [ "${result}" = "null" ] && echo "" || echo "${result}"
}

###############################################################################
# Read Entries as array from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Returns array of values
function readConfigEntriesArray() {
  yq eval ".${1} | explode(.) | to_entries | map([.key])[] | .[]" "${2}" 2>/dev/null
}

###############################################################################
function compile_addon() {
  # Read manifest file
  ADDON_PATH="${1}"
  ADDON_NAME="$(basename "${ADDON_PATH}")"
  MANIFEST="${ADDON_PATH}/manifest.yml"
  if [ ! -f "${MANIFEST}" ]; then
    echo -e "\033[1;44mError: ${MANIFEST} not found, ignoring it\033[0m"
    return 0
  fi
  echo -e "\033[7mProcessing manifest ${MANIFEST}\033[0m"
  OUT_PATH="${TEMP_PATH}/${ADDON_NAME}"
  rm -rf "${OUT_PATH}"
  mkdir -p "${OUT_PATH}"

  # Check if has compile script
  COMPILESCRIPT=$(readConfigKey "compile-script" "${MANIFEST}")
  if [ -n "${COMPILESCRIPT}" ]; then
    echo "Running compile script"
    (
      cd "${ADDON_PATH}"
      chmod +x "${COMPILESCRIPT}"
      "${COMPILESCRIPT}"
      cd -
    )
  fi
  # Copy manifest to destiny
  cp -f "${MANIFEST}" "${OUT_PATH}"
  # Check if exist files for all platforms
  if readConfigKey "all" "${MANIFEST}"; then
    echo -e "\033[1;32m Processing 'all' section\033[0m"
    HAS_FILES=0
    # Get name of script to install, if defined. This script has low priority
    INSTALL_SCRIPT="$(readConfigKey "all.install-script" "${MANIFEST}")"
    if [ -n "${INSTALL_SCRIPT}" ]; then
      if [ -f "${ADDON_PATH}/${INSTALL_SCRIPT}" ]; then
        echo -e "\033[1;35m  Copying install script ${INSTALL_SCRIPT}\033[0m"
        mkdir -p "${OUT_PATH}/all"
        cp -f "${ADDON_PATH}/${INSTALL_SCRIPT}" "${OUT_PATH}/all/install.sh"
        HAS_FILES=1
      else
        echo -e "\033[1;33m  WARNING: install script '${INSTALL_SCRIPT}' not found\033[0m"
      fi
    fi
    # Get folder name for copy
    COPY_PATH="$(readConfigKey "all.copy" "${MANIFEST}")"
    # If folder exists, copy
    if [ -n "${COPY_PATH}" ]; then
      if [ -d "${ADDON_PATH}/${COPY_PATH}" ]; then
        echo -e "\033[1;35m  Copying folder '${COPY_PATH}'\033[0m"
        mkdir -p "${OUT_PATH}/all/root"
        cp -rf "${ADDON_PATH}/${COPY_PATH}/"* "${OUT_PATH}/all/root"
        HAS_FILES=1
      else
        echo -e "\033[1;33m  WARNING: folder '${COPY_PATH}' not found\033[0m"
      fi
    fi
    if [ ${HAS_FILES} -eq 1 ]; then
      # Create tar gziped
      tar -caf "${OUT_PATH}/all.tgz" -C "${OUT_PATH}/all" .
      echo -e "\033[1;36m  Created file '${OUT_PATH}/all.tgz' \033[0m"
    fi
    # Clean
    rm -rf "${OUT_PATH}/all"
  fi

  # Loop in each available platform-kver
  for P in $(readConfigEntriesArray "available-for" "${MANIFEST}"); do
    echo -e "\033[1;32m Processing '${P}' platform-kver section\033[0m"
    HAS_FILES=0
    # Get name of script to install, if defined. This script has high priority
    INSTALL_SCRIPT="$(readConfigKey 'available-for."'${P}'".install-script' "${MANIFEST}")"
    if [ -n "${INSTALL_SCRIPT}" ]; then
      if [ -f "${ADDON_PATH}/${INSTALL_SCRIPT}" ]; then
        echo -e "\033[1;35m  Copying install script ${INSTALL_SCRIPT}\033[0m"
        mkdir -p "${OUT_PATH}/${P}"
        cp -f "${ADDON_PATH}/${INSTALL_SCRIPT}" "${OUT_PATH}/${P}/install.sh"
        HAS_FILES=1
      else
        echo -e "\033[1;33m  WARNING: install script '${INSTALL_SCRIPT}' not found\033[0m"
      fi
    fi
    # Get folder name for copy
    COPY_PATH="$(readConfigKey 'available-for."'${P}'".copy' "${MANIFEST}")"
    # If folder exists, copy
    if [ -n "${COPY_PATH}" ]; then
      if [ -d "${ADDON_PATH}/${COPY_PATH}" ]; then
        echo -e "\033[1;35m  Copying folder '${COPY_PATH}'\033[0m"
        mkdir -p "${OUT_PATH}/${P}/root"
        cp -rf "${ADDON_PATH}/${COPY_PATH}/"* "${OUT_PATH}/${P}/root"
        HAS_FILES=1
      else
        echo -e "\033[1;33m  WARNING: folder '${ADDON_PATH}/${COPY_PATH}' not found\033[0m"
      fi
    fi
    if [ ${HAS_FILES} -eq 1 ]; then
      # Create tar gziped
      tar -caf "${OUT_PATH}/${P}.tgz" -C "${OUT_PATH}/${P}" .
      echo -e "\033[1;36m  Created file '${P}.tgz' \033[0m"
    fi
    # Clean
    rm -rf "${OUT_PATH}/${P}"
  done
  # Create addon package
  tar -caf "${ADDON_NAME}.addon" -C "${OUT_PATH}" .
  rm -rf "${OUT_PATH}"
}

# Main
if [ $# -ge 1 ]; then
  for A in "$@"; do
    compile_addon "$(realpath "${A}")"
  done
else
  while read -r A; do
    compile_addon "$(realpath "${A}")"
  done <<<"$(find "${WORK_PATH}" -mindepth 1 -maxdepth 1 -type d ! -name '.*')"
fi

# zip -9 addons-$(cat VERSION 2>/dev/null).zip -j *.addon VERSION
