#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# shellcheck disable=SC2034

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

CKS_PATH="${PART3_PATH}/cks"
LKMS_PATH="${PART3_PATH}/lkms"
ADDONS_PATH="${PART3_PATH}/addons"
MODULES_PATH="${PART3_PATH}/modules"
USER_UP_PATH="${PART3_PATH}/users"
SCRIPTS_PATH="${PART3_PATH}/scripts"

# SYNC configFile.sh

###############################################################################
# Delete a key in config file
# 1 - Path of Key
# 2 - Path of yaml config file
function deleteConfigKey() {
  ${RR_SUDO} yq eval "del(.${1})" --inplace "${2}" 2>/dev/null
}

###############################################################################
# Write to yaml config file
# 1 - Path of Key
# 2 - Value
# 3 - Path of yaml config file
function writeConfigKey() {
  local value="${2}"
  [ "${value}" = "{}" ] && ${RR_SUDO} yq eval ".${1} = {}" --inplace "${3}" 2>/dev/null || ${RR_SUDO} yq eval ".${1} = \"${value}\"" --inplace "${3}" 2>/dev/null
}

###############################################################################
# Read key value from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Return Value
function readConfigKey() {
  local result
  result=$(${RR_SUDO} yq eval ".${1} | explode(.)" "${2}" 2>/dev/null)
  [ "${result}" = "null" ] && echo "" || echo "${result}"
}

###############################################################################
# Write to yaml config file
# 1 - Modules
# 2 - Path of yaml config file
function mergeConfigModules() {
  # Error: bad file '-': cannot index array with '8139cp' (strconv.ParseInt: parsing "8139cp": invalid syntax)
  # When the first key is a pure number, yq will not process it as a string by default. The current solution is to insert a placeholder key.
  local MS ML XF
  MS="RRORG\n${1// /\\n}"
  ML="$(echo -en "${MS}" | awk '{print "modules."$1":"}')"
  XF=$(${RR_SUDO} mktemp 2>/dev/null)
  XF=${XF:-/tmp/tmp.XXXXXXXXXX}
  ${RR_SUDO} sh -c "echo -en '${ML}' | yq -p p -o y >'${XF}'"
  deleteConfigKey "modules.\"RRORG\"" "${XF}"
  ${RR_SUDO} yq eval-all --inplace '. as $item ireduce ({}; . * $item)' --inplace "${2}" "${XF}" 2>/dev/null
  ${RR_SUDO} rm -f "${XF}"
}

###############################################################################
# Read Entries as map(key=value) from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Returns map of values
function readConfigMap() {
  ${RR_SUDO} yq eval ".${1} | explode(.) | to_entries | map([.key, .value] | join(\": \")) | .[]" "${2}" 2>/dev/null
}

###############################################################################
# Read an array from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Returns array/map of values
function readConfigArray() {
  ${RR_SUDO} yq eval ".${1}[]" "${2}" 2>/dev/null
}

# Return list of all modules available
# 1 - Platform
# 2 - Kernel Version
function getAllModules() {
  local PLATFORM=${1}
  local PKVER=${2}
  local KERNEL
  if [ -z "${PLATFORM}" ] || [ -z "${PKVER}" ]; then
    echo ""
    return 1
  fi
  # Unzip modules for temporary folder
  ${RR_SUDO} rm -rf "${TMP_PATH}/modules"
  ${RR_SUDO} mkdir -p "${TMP_PATH}/modules"
  KERNEL="$(readConfigKey "kernel" "${USER_CONFIG_FILE}")"
  if [ "${KERNEL}" = "custom" ]; then
    ${RR_SUDO} tar -zxf "${CKS_PATH}/modules-${PLATFORM}-${PKVER}.tgz" -C "${TMP_PATH}/modules"
  else
    ${RR_SUDO} tar -zxf "${MODULES_PATH}/${PLATFORM}-${PKVER}.tgz" -C "${TMP_PATH}/modules"
  fi
  # ${RR_SUDO} chown -R root:root "${TMP_PATH}/modules"
  # ${RR_SUDO} chmod -R 755 "${TMP_PATH}/modules"
  # Get list of all modules
  for F in $(${RR_SUDO} ls ${TMP_PATH}/modules/*.ko 2>/dev/null); do
    [ ! -e "${F}" ] && continue
    local X M DESC
    X=$(basename "${F}")
    M=$(basename "${F}" .ko)
    DESC=$(${RR_SUDO} modinfo "${F}" 2>/dev/null | awk -F':' '/description:/{ print $2}' | awk '{sub(/^[ ]+/,""); print}')
    [ -z "${DESC}" ] && DESC="${X}"
    echo "${M} \"${DESC}\""
  done
  ${RR_SUDO} rm -rf "${TMP_PATH}/modules"
}

# SYNC menu.sh

function progresslog {
  local PROGRESS_FILE="${3:-"/tmp/rr_update_progress"}"
  if [ -f "${PROGRESS_FILE}" ]; then
    [ ! -w "${PROGRESS_FILE}" ] && ${RR_SUDO} chmod a+rw "${PROGRESS_FILE}"
  else
    ${RR_SUDO} touch "${PROGRESS_FILE}"
    ${RR_SUDO} chmod a+rw "${PROGRESS_FILE}"
  fi
  echo "{\"progress\": \"${1}\", \"progressmsg\": \"${2}\"}" | ${RR_SUDO} tee "${3}"
}

# 1 - update.zip path
# 2 - progress file path
function updateRR() {
  local UPDATE_FILE="${1:-"/tmp/update.zip"}"
  local PROGRESS_FILE="${2:-"/tmp/rr_update_progress"}"

  progresslog "0" "Update RR ..." "${PROGRESS_FILE}"
  if [ ! -d "${PART1_PATH}" ] || [ ! -d "${PART3_PATH}" ]; then
    progresslog "-1" "No loader disk found!" "${PROGRESS_FILE}"
    return 1
  fi
  if [ ! -f "${UPDATE_FILE}" ]; then
    progresslog "-1" "No update file found!" "${PROGRESS_FILE}"
    return 1
  fi
  progresslog "10" "Unzip update file ..." "${PROGRESS_FILE}"
  ${RR_SUDO} rm -rf "${TMP_PATH}/update"
  ${RR_SUDO} mkdir -p "${TMP_PATH}/update"
  ${RR_SUDO} unzip -oq "${UPDATE_FILE}" -d "${TMP_PATH}/update"
  if [ $? -ne 0 ]; then
    progresslog "-2" "Update file unzip failed!" "${PROGRESS_FILE}"
    return 1
  fi
  # Check checksums
  progresslog "20" "Check checksums ..." "${PROGRESS_FILE}"
  ${RR_SUDO} sh -c "cd '${TMP_PATH}/update' && sha256sum --status -c sha256sum"
  if [ $? -ne 0 ]; then
    progresslog "-3" "Update file checksum failed!" "${PROGRESS_FILE}"
    return 1
  fi
  # Check conditions
  progresslog "30" "Check conditions ..." "${PROGRESS_FILE}"
  if [ -f "${TMP_PATH}/update/update-check.sh" ]; then
    ${RR_SUDO} chmod a+x "${TMP_PATH}/update/update-check.sh"
    ${RR_SUDO} bash "${TMP_PATH}/update/update-check.sh"
    if [ $? -ne 0 ]; then
      progresslog "-4" "Update file check failed!" "${PROGRESS_FILE}"
      return 1
    fi
  fi

  progresslog "40" "Check disk space ..." "${PROGRESS_FILE}"
  SIZENEW=0
  SIZEOLD=0
  while IFS=': ' read -r KEY VALUE; do
    VALUE="${VALUE#/}" # Remove leading slash
    VALUE="${VALUE%/}" # Remove trailing slash
    if [ "${KEY: -1}" = "/" ]; then
      ${RR_SUDO} rm -rf "${TMP_PATH}/update/${VALUE}"
      ${RR_SUDO} mkdir -p "${TMP_PATH}/update/${VALUE}/"

      ${RR_SUDO} tar -zxf "${TMP_PATH}/update/$(basename "${KEY}").tgz" -C "${TMP_PATH}/update/${VALUE}"
      if [ $? -ne 0 ]; then
        progresslog "-5" "Failed to extract update file!" "${PROGRESS_FILE}"
        return 1
      fi
      # ${RR_SUDO} chown -R root:root "${TMP_PATH}/update/${VALUE}"
      # ${RR_SUDO} chmod -R 644 "${TMP_PATH}/update/${VALUE}"
      ${RR_SUDO} rm "${TMP_PATH}/update/$(basename "${KEY}").tgz"
    else
      ${RR_SUDO} mkdir -p "${TMP_PATH}/update/$(dirname "/${VALUE}")"
      ${RR_SUDO} mv -f "${TMP_PATH}/update/$(basename "${KEY}")" "${TMP_PATH}/update/${VALUE}"
    fi
    FSNEW=$(${RR_SUDO} du -sm "${TMP_PATH}/update/${VALUE}" 2>/dev/null | awk '{print $1}')
    FSOLD=$(${RR_SUDO} du -sm "/${VALUE}" 2>/dev/null | awk '{print $1}')
    SIZENEW=$((${SIZENEW} + ${FSNEW:-0}))
    SIZEOLD=$((${SIZEOLD} + ${FSOLD:-0}))
  done <<<"$(readConfigMap "replace" "${TMP_PATH}/update/update-list.yml")"

  SIZESPL=$(${RR_SUDO} df -m "${PART3_PATH}" 2>/dev/null | awk 'NR==2 {print $4}')
  if [ ${SIZENEW:-0} -ge $((${SIZEOLD:-0} + ${SIZESPL:-0})) ]; then
    progresslog "-6" "Not enough disk space! Need ${SIZENEW:-0}MB, but only $((${SIZEOLD:-0} + ${SIZESPL:-0}))MB available." "${PROGRESS_FILE}"
    return 1
  fi

  # Process update-list.yml
  progresslog "50" "Process update-list ..." "${PROGRESS_FILE}"
  while read -r F; do
    [ -f "${F}" ] && ${RR_SUDO} rm -f "${F}"
    [ -d "${F}" ] && ${RR_SUDO} rm -rf "${F}"
  done <<<"$(readConfigArray "remove" "${TMP_PATH}/update/update-list.yml")"

  progresslog "60" "Process update-list ..." "${PROGRESS_FILE}"
  while IFS=': ' read -r KEY VALUE; do
    progresslog "70" "Update ${VALUE} ..." "${PROGRESS_FILE}"
    VALUE="${VALUE#/}" # Remove leading slash
    VALUE="${VALUE%/}" # Remove trailing slash
    if [ "${KEY: -1}" = "/" ]; then
      ${RR_SUDO} rm -rf "/${VALUE}/"*
      ${RR_SUDO} mkdir -p "/${VALUE}/"
      ${RR_SUDO} cp -rf "${TMP_PATH}/update/${VALUE}/". "/${VALUE}/"
      if [ "$(realpath "/${VALUE}/")" = "$(realpath "${MODULES_PATH}")" ]; then
        MODEL="$(readConfigKey "model" "${USER_CONFIG_FILE}")"
        PRODUCTVER="$(readConfigKey "productver" "${USER_CONFIG_FILE}")"
        PLATFORM="$(readConfigKey "platform" "${USER_CONFIG_FILE}")"
        KVER="$(readConfigKey "kver" "${USER_CONFIG_FILE}")"
        KPRE="$(readConfigKey "kpre" "${USER_CONFIG_FILE}")"

        if [ -n "${PLATFORM}" ] && [ -n "${PRODUCTVER}" ] && [ -z "${KVER}" ]; then
          _release=$(/bin/uname -r)
          KVER="$(/bin/echo ${_release%%[-+]*} | /usr/bin/cut -d'.' -f1-3)"
          PLATFORMS="epyc7002"
          PLATFORM="$(/bin/get_key_value /etc/synoinfo.conf unique | cut -d"_" -f2)"
          majorversion="$(/bin/get_key_value /etc/VERSION majorversion)"
          minorversion="$(/bin/get_key_value /etc/VERSION minorversion)"
          echo "${PLATFORMS}" | grep -wq "${PLATFORM}" && KPRE="${majorversion}.${minorversion}" || KPRE=""
        fi
        if [ -n "${PLATFORM}" ] && [ -n "${KVER}" ]; then
          progresslog "70" "Update /${VALUE} merge modules ..." "${PROGRESS_FILE}"
          writeConfigKey "modules" "{}" "${USER_CONFIG_FILE}"
          mergeConfigModules "$(getAllModules "${PLATFORM}" "${KPRE:+${KPRE}-}${KVER}" | awk '{print $1}')" "${USER_CONFIG_FILE}"
        fi

      fi
    else
      ${RR_SUDO} mkdir -p "$(dirname "/${VALUE}")"
      ${RR_SUDO} cp -f "${TMP_PATH}/update/${VALUE}" "/${VALUE}"
    fi
  done <<<"$(readConfigMap "replace" "${TMP_PATH}/update/update-list.yml")"

  ${RR_SUDO} rm -rf "${TMP_PATH}/update"
  progresslog "90" "Update RR success!" "${PROGRESS_FILE}"
  ${RR_SUDO} touch ${PART1_PATH}/.upgraded
  ${RR_SUDO} touch ${PART1_PATH}/.build
  ${RR_SUDO} sync
  progresslog "100" "Update RR success!" "${PROGRESS_FILE}"
  return 0
}

[ -z "${1}" ] && {
  echo "Usage: $0 [updateRR] [update.zip] [progress file]"
  exit 11
}

[ -x "/sbin/rrmdo" ] && RR_SUDO="/sbin/rrmdo" || RR_SUDO=""
${RR_SUDO} ls /root >/dev/null 2>&1 || {
  echo "No root permission!"
  exit 12
}

exec 268>"${TMP_PATH}/rr-update.lock"
flock -n 268 || {
  echo "Another menu is running!"
  exit 91
}

trap 'flock -u 268; rm -f "${TMP_PATH}/rr-update.lock"' EXIT INT TERM HUP

"$@"
