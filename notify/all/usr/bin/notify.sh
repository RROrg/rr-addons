#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

if [ "${1}" = "-r" ]; then
  TEXTS_PATH="/usr/local/share/notification/rr"
  CACHE_PATH="/var/cache/texts/rr"
  [ -d "${TEXTS_PATH}" ] && rm -rf "${TEXTS_PATH}"
  [ -d "${CACHE_PATH}" ] && rm -rf "${CACHE_PATH}"
  /usr/syno/bin/notification_utils --remove_category_db_file rr
  /usr/syno/bin/notification_utils --sync_setting_db
else
  TEXTS_PATH="/usr/local/share/notification/rr"
  CACHE_PATH="/var/cache/texts/rr"
  for F in /usr/syno/synoman/webman/texts/*; do
    N=$(basename "${F}")
    rm -rf "${TEXTS_PATH}/${N}"
    mkdir -p "${TEXTS_PATH}/${N}"
    echo -en '[rr_notify]\nCategory: System\nLevel: NOTIFICATION_INFO\nDesktop: %NOTIFICATION%\n\n\n' >>"${TEXTS_PATH}/${N}/mails"
    echo -en '[rr_notify_subject]\nCategory: System\nLevel: NOTIFICATION_INFO\nDesktop: %NOTIFICATION%\nSubject: %NOTIFICATION%\n\n%SUBJECT%\n\nFrom %HOSTNAME%\n\n\n' >>"${TEXTS_PATH}/${N}/mails"
  done
  /bin/rm -rf "${CACHE_PATH}"
  /bin/mkdir -p /var/cache/texts
  /bin/rsync -ar "${TEXTS_PATH}/" "${CACHE_PATH}"
  /usr/syno/bin/notification_utils --remove_category_db_file rr
  /usr/syno/bin/notification_utils --gen_category_db_file rr enu
  /usr/syno/bin/notification_utils --sync_setting_db

  # NOTIFICATION="RR Notify"
  # synodsmnotify -e false -b false "@administrators" "rr_notify" "{\"%NOTIFICATION%\": \"${NOTIFICATION}\"}"
  # NOTIFICATION="RR Notify"
  # SUBJECT="Welcome to <a href=\\\"https://github.com/RROrg\\\" target=blank>RROrg</a>!"
  # synodsmnotify -e false -b false "@administrators" "rr_notify_subject" "{\"%NOTIFICATION%\": \"${NOTIFICATION}\", \"%SUBJECT%\": \"${SUBJECT}\"}"
fi
