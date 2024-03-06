#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# SYNC consts.sh
PART1_PATH="/mnt/p1"
PART2_PATH="/mnt/p2"
PART3_PATH="/mnt/p3"
#DSMROOT_PATH="/mnt/dsmroot"
TMP_PATH="/tmp"

#UNTAR_PAT_PATH="${TMP_PATH}/pat"
#RAMDISK_PATH="${TMP_PATH}/ramdisk"
#LOG_FILE="${TMP_PATH}/log.txt"

USER_CONFIG_FILE="${PART1_PATH}/user-config.yml"
GRUB_PATH="${PART1_PATH}/boot/grub"

ORI_ZIMAGE_FILE="${PART2_PATH}/zImage"
ORI_RDGZ_FILE="${PART2_PATH}/rd.gz"

RR_BZIMAGE_FILE="${PART3_PATH}/bzImage-rr"
RR_RAMDISK_FILE="${PART3_PATH}/initrd-rr"
MOD_ZIMAGE_FILE="${PART3_PATH}/zImage-dsm"
MOD_RDGZ_FILE="${PART3_PATH}/initrd-dsm"

CKS_PATH="${PART3_PATH}/cks"
LKMS_PATH="${PART3_PATH}/lkms"
ADDONS_PATH="${PART3_PATH}/addons"
MODULES_PATH="${PART3_PATH}/modules"
USER_UP_PATH="${PART3_PATH}/users"
SCRIPTS_PATH="${PART3_PATH}/scripts"

# SYNC configFile.sh

# Read key value from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Return Value
function readConfigKey() {
  RESULT=$(yq eval '.'${1}' | explode(.)' "${2}" 2>/dev/null)
  [ "${RESULT}" == "null" ] && echo "" || echo ${RESULT}
}

# Read Entries as map(key=value) from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Returns map of values
function readConfigMap() {
  yq eval '.'${1}' | explode(.) | to_entries | map([.key, .value] | join(": ")) | .[]' "${2}" 2>/dev/null
}

# Read an array from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Returns array/map of values
function readConfigArray() {
  yq eval '.'${1}'[]' "${2}" 2>/dev/null
}

# Write to yaml config file
# 1 - Path of Key
# 2 - Value
# 3 - Path of yaml config file
function writeConfigKey() {
  [ "${2}" = "{}" ] && yq eval '.'${1}' = {}' --inplace "${3}" 2>/dev/null || yq eval '.'${1}' = "'"${2}"'"' --inplace "${3}" 2>/dev/null
}

# Read key value from model config file
# 1 - Model
# 2 - Key
# Return Value
function readModelKey() {
  readConfigKey "${2}" "${WORK_PATH}/model-configs/${1}.yml"
}

# Return list of all modules available
# 1 - Platform
# 2 - Kernel Version
function getAllModules() {
  local PLATFORM=${1}
  local KVER=${2}

  if [ -z "${PLATFORM}" -o -z "${KVER}" ]; then
    echo ""
    return 1
  fi
  # Unzip modules for temporary folder
  rm -rf "${TMP_PATH}/modules"
  mkdir -p "${TMP_PATH}/modules"
  local KERNEL="$(readConfigKey "kernel" "${USER_CONFIG_FILE}")"
  if [ "${KERNEL}" = "custom" ]; then
    tar -zxf "${CKS_PATH}/modules-${PLATFORM}-${KVER}.tgz" -C "${TMP_PATH}/modules"
  else
    tar -zxf "${MODULES_PATH}/${PLATFORM}-${KVER}.tgz" -C "${TMP_PATH}/modules"
  fi
  # Get list of all modules
  for F in $(ls ${TMP_PATH}/modules/*.ko 2>/dev/null); do
    local X=$(basename ${F})
    local M=${X:0:-3}
    local DESC=$(modinfo ${F} 2>/dev/null | awk -F':' '/description:/{ print $2}' | awk '{sub(/^[ ]+/,""); print}')
    [ -z "${DESC}" ] && DESC="${X}"
    echo "${M} \"${DESC}\""
  done
  rm -rf "${TMP_PATH}/modules"
}

# SYNC menu.sh

# 1 - update.zip path
# 2 - progress file path
function updateRR() {
  local UPDATE_FILE="${1:-"/tmp/update.zip"}"
  local PROGRESS_FILE="${2:-"/tmp/rr_update_progress"}"

  echo '{"progress": "0", "progressmsg": "Update RR ..."}' >"${PROGRESS_FILE}"
  if [ ! -f "${UPDATE_FILE}" ]; then
    echo '{"progress": "-1", "progressmsg": "Update file not found!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "10", "progressmsg": "Extracting update file ..."}' >"${PROGRESS_FILE}"
  rm -rf "${TMP_PATH}/update"
  mkdir -p "${TMP_PATH}/update"
  unzip -oq "${UPDATE_FILE}" -d "${TMP_PATH}/update"
  if [ $? -ne 0 ]; then
    echo '{"progress": "-2", "progressmsg": "Update file unzip failed!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  # Check checksums
  echo '{"progress": "20", "progressmsg": "Check checksums ..."}' >"${PROGRESS_FILE}"
  (cd "${TMP_PATH}/update" && sha256sum --status -c sha256sum)
  if [ $? -ne 0 ]; then
    echo '{"progress": "-3", "progressmsg": "Checksum do not match!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  # Check conditions
  echo '{"progress": "30", "progressmsg": "Check conditions ..."}' >"${PROGRESS_FILE}"
  if [ -f "${TMP_PATH}/update/update-check.sh" ]; then
    chmod +x "${TMP_PATH}/update/update-check.sh"
    #${TMP_PATH}/update/update-check.sh
    if [ $? -ne 0 ]; then
      echo '{"progress": "-4", "progressmsg": "Update check failed!"}' >"${PROGRESS_FILE}"
      return 1
    fi
  fi
  # Process update-list.yml
  echo '{"progress": "40", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  while read F; do
    [ -f "${F}" ] && rm -f "${F}"
    [ -d "${F}" ] && rm -Rf "${F}"
  done < <(readConfigArray "remove" "${TMP_PATH}/update/update-list.yml")

  echo '{"progress": "50", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  while IFS=': ' read KEY VALUE; do
    if [ "${KEY: -1}" = "/" ]; then
      rm -Rf "${VALUE}"
      mkdir -p "${VALUE}"
      tar -zxf "${TMP_PATH}/update/$(basename "${KEY}").tgz" -C "${VALUE}"
      if [ "$(realpath "${VALUE}")" = "$(realpath "${MODULES_PATH}")" ]; then
        if [ -n "${MODEL}" -a -n "${PRODUCTVER}" ]; then
          PLATFORM="$(readModelKey "${MODEL}" "platform")"
          KVER="$(readModelKey "${MODEL}" "productvers.[${PRODUCTVER}].kver")"
          KPRE="$(readModelKey "${MODEL}" "productvers.[${PRODUCTVER}].kpre")"
          if [ -n "${PLATFORM}" -a -n "${KVER}" ]; then
            writeConfigKey "modules" "{}" "${USER_CONFIG_FILE}"
            while read ID DESC; do
              writeConfigKey "modules.\"${ID}\"" "" "${USER_CONFIG_FILE}"
            done < <(getAllModules "${PLATFORM}" "$([ -n "${KPRE}" ] && echo "${KPRE}-")${KVER}")
          fi
        fi
      fi
    else
      mkdir -p "$(dirname "${VALUE}")"
      mv -f "${TMP_PATH}/update/$(basename "${KEY}")" "${VALUE}"
    fi
  done < <(readConfigMap "replace" "${TMP_PATH}/update/update-list.yml")
  echo '{"progress": "90", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  touch ${PART1_PATH}/.build
  echo '{"progress": "100", "progressmsg": "RR updated success!"}' >"${PROGRESS_FILE}"
  return 0
}

# 1 - update.zip path
# 2 - progress file path
function updateAddons() {
  local UPDATE_FILE="${1:-"/tmp/addons.zip"}"
  local PROGRESS_FILE="${2:-"/tmp/rr_update_progress"}"

  echo '{"progress": "0", "progressmsg": "Update Addons ..."}' >"${PROGRESS_FILE}"
  if [ ! -f "${UPDATE_FILE}" ]; then
    echo '{"progress": "-1", "progressmsg": "Update file not found!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "10", "progressmsg": "Extracting update file ..."}' >"${PROGRESS_FILE}"
  rm -rf "${TMP_PATH}/update"
  mkdir -p "${TMP_PATH}/update"
  unzip -oq "${UPDATE_FILE}" -d "${TMP_PATH}/update"
  if [ $? -ne 0 ]; then
    echo '{"progress": "-2", "progressmsg": "Update file unzip failed!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "20", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  rm -Rf "${ADDONS_PATH}/"*
  [ -f "${TMP_PATH}/update/VERSION" ] && cp -f "${TMP_PATH}/update/VERSION" "${ADDONS_PATH}/"
  for PKG in $(ls ${TMP_PATH}/update/*.addon 2>/dev/null); do
    ADDON=$(basename ${PKG} | sed 's|.addon||')
    rm -rf "${ADDONS_PATH}/${ADDON}"
    mkdir -p "${ADDONS_PATH}/${ADDON}"
    tar -xaf "${PKG}" -C "${ADDONS_PATH}/${ADDON}" >/dev/null 2>&1
  done
  echo '{"progress": "90", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  touch ${PART1_PATH}/.build
  echo '{"progress": "100", "progressmsg": "Addons updated success!"}' >"${PROGRESS_FILE}"
  return 0
}

# 1 - update.zip path
# 2 - progress file path
function updateModules() {
  local UPDATE_FILE="${1:-"/tmp/modules.zip"}"
  local PROGRESS_FILE="${2:-"/tmp/rr_update_progress"}"

  echo '{"progress": "0", "progressmsg": "Update Modules ..."}' >"${PROGRESS_FILE}"
  if [ ! -f "${UPDATE_FILE}" ]; then
    echo '{"progress": "-1", "progressmsg": "Update file not found!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "10", "progressmsg": "Extracting update file ..."}' >"${PROGRESS_FILE}"
  rm -rf "${TMP_PATH}/update"
  mkdir -p "${TMP_PATH}/update"
  unzip -oq "${UPDATE_FILE}" -d "${TMP_PATH}/update"
  if [ $? -ne 0 ]; then
    echo '{"progress": "-2", "progressmsg": "Update file unzip failed!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "20", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  rm -rf "${MODULES_PATH}/"*
  cp -rf "${TMP_PATH}/update/"* "${MODULES_PATH}/"
  if [ $? -ne 0 ]; then
    echo '{"progress": "-2", "progressmsg": "Update file unzip failed!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "30", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  if [ -n "${MODEL}" -a -n "${PRODUCTVER}" ]; then
    PLATFORM="$(readModelKey "${MODEL}" "platform")"
    KVER="$(readModelKey "${MODEL}" "productvers.[${PRODUCTVER}].kver")"
    KPRE="$(readModelKey "${MODEL}" "productvers.[${PRODUCTVER}].kpre")"
    if [ -n "${PLATFORM}" -a -n "${KVER}" ]; then
      writeConfigKey "modules" "{}" "${USER_CONFIG_FILE}"
      while read ID DESC; do
        writeConfigKey "modules.\"${ID}\"" "" "${USER_CONFIG_FILE}"
      done < <(getAllModules "${PLATFORM}" "$([ -n "${KPRE}" ] && echo "${KPRE}-")${KVER}")
    fi
  fi
  echo '{"progress": "90", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  touch ${PART1_PATH}/.build
  echo '{"progress": "100", "progressmsg": "Modules updated success!"}' >"${PROGRESS_FILE}"
  return 0
}

# 1 - update.zip path
# 2 - progress file path
function updateLKMs() {
  local UPDATE_FILE="${1:-"/tmp/rp-lkms.zip"}"
  local PROGRESS_FILE="${2:-"/tmp/rr_update_progress"}"

  echo '{"progress": "0", "progressmsg": "Update LKMs ..."}' >"${PROGRESS_FILE}"
  if [ ! -f "${UPDATE_FILE}" ]; then
    echo '{"progress": "-1", "progressmsg": "Update file not found!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "10", "progressmsg": "Extracting update file ..."}' >"${PROGRESS_FILE}"
  rm -rf "${TMP_PATH}/update"
  mkdir -p "${TMP_PATH}/update"
  unzip -oq "${UPDATE_FILE}" -d "${TMP_PATH}/update"
  if [ $? -ne 0 ]; then
    echo '{"progress": "-2", "progressmsg": "Update file unzip failed!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "20", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  rm -rf "${LKMS_PATH}/"*
  cp -rf "${TMP_PATH}/update/"* "${LKMS_PATH}/"
  echo '{"progress": "90", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  touch ${PART1_PATH}/.build
  echo '{"progress": "100", "progressmsg": "LKMs updated success!"}' >"${PROGRESS_FILE}"
  return 0
}

# 1 - update.zip path
# 2 - progress file path
function updateCKs() {
  local UPDATE_FILE="${1:-"/tmp/rr-cks.zip"}"
  local PROGRESS_FILE="${2:-"/tmp/rr_update_progress"}"

  echo '{"progress": "0", "progressmsg": "Update CKs ..."}' >"${PROGRESS_FILE}"
  if [ ! -f "${UPDATE_FILE}" ]; then
    echo '{"progress": "-1", "progressmsg": "Update file not found!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "10", "progressmsg": "Extracting update file ..."}' >"${PROGRESS_FILE}"
  rm -rf "${TMP_PATH}/update"
  mkdir -p "${TMP_PATH}/update"
  unzip -oq "${UPDATE_FILE}" -d "${TMP_PATH}/update"
  if [ $? -ne 0 ]; then
    echo '{"progress": "-2", "progressmsg": "Update file unzip failed!"}' >"${PROGRESS_FILE}"
    return 1
  fi
  echo '{"progress": "20", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  rm -rf "${CKS_PATH}/"*
  cp -rf "${TMP_PATH}/update/"* "${CKS_PATH}/"
  echo '{"progress": "90", "progressmsg": "Process update ..."}' >"${PROGRESS_FILE}"
  touch ${PART1_PATH}/.build
  echo '{"progress": "100", "progressmsg": "CKs updated success!"}' >"${PROGRESS_FILE}"
  return 0
}

WORK_PATH="/tmp/initrd/opt/rr"
MODEL="$(readConfigKey "model" "${USER_CONFIG_FILE}")"
PRODUCTVER="$(readConfigKey "productver" "${USER_CONFIG_FILE}")"

$@
