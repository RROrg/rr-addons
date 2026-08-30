#!/usr/bin/env bash
#
# Copyright (C) 2022 Ing <https://github.com/wjz304>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

function Create() {
  if grep -q '^name=RR-UpdateHosts' /usr/syno/etc/synoschedule.d/root/*.task; then
    echo "Existence tasks"
  else
    echo "Create tasks"
    schedule='{"date_type":0,"week_day":"0,1,2,3,4,5,6","repeat_date":1001,"monthly_week":[],"hour":0,"minute":0,"repeat_hour":2,"repeat_min":0,"last_work_hour":0,"repeat_min_store_config":[1,5,10,15,20,30],"repeat_hour_store_config":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]}'
    extra='{"notify_enable":false,"script":"
DOMAINS=(
  www.synology.com
  find.synology.com
  account.synology.com
  kb.synology.com
  help.synology.com
  router.synology.com
  notification.synology.com
  sns.synology.com
  www-ai.synology.com
  archive.synology.com
  update7.synology.com
  pkgupdate7.synology.com
  dataautoupdate7.synology.com
  global.download.synology.com
  webec.synology.com
  fileres.synology.com
  gallery.synology.com
  synostatic.synology.com
  www.synology.cn
  find.synology.cn
  account.synology.cn
  kb.synology.cn
  archive.synology.cn
  cndl.synology.cn
  global.synologydownload.com
)

/usr/bin/rr-updatehosts.sh hosts \"${DOMAINS[@]}\"
","notify_mail":"","notify_if_error":false}'
    synowebapi -s --exec api=SYNO.Core.TaskScheduler.Root method=create version=4 name='"RR-UpdateHosts"' owner='"root"' enable=true schedule="${schedule}" extra="${extra}" type='"script"'
  fi
  exit 0
}

function Delete() {
  for F in $(LC_ALL=C printf '%s\n' /usr/syno/etc/synoschedule.d/root/*.task | sort -V); do
    [ ! -e "${F}" ] && continue
    if grep -q '^name=RR-UpdateHosts' "${F}"; then
      id=$(grep '^id=' "${F}" | cut -d'=' -f2)
      [ -n "${id}" ] && synoschedtask --del id=${id}
    fi
  done
  exit 0
}

function Hosts() {
  echo "Update hosts..."

  _resolve() {
    local DOMAIN="${1}"
    local IP=""
    [ -z "${DOMAIN}" ] && return 1
    # LC_ALL=C ping -c 1 -W 1 "${DOMAIN}" >/dev/null 2>&1 && return 0
    # Try Cloudflare DoH
    [ -z "${IP}" ] && IP="$(curl -skL --connect-timeout 5 "https://cloudflare-dns.com/dns-query?name=${DOMAIN}&type=A" -H "accept: application/dns-json" 2>/dev/null | jq -r '.Answer[]? | select(.type == 1) | .data' 2>/dev/null | head -1)"
    # Try Google DoH
    [ -z "${IP}" ] && IP="$(curl -skL --connect-timeout 5 "https://dns.google/resolve?name=${DOMAIN}&type=A" 2>/dev/null | jq -r '.Answer[]? | select(.type == 1) | .data' 2>/dev/null | head -1)"
    # Try AliDNS DoH
    [ -z "${IP}" ] && IP="$(curl -skL --connect-timeout 5 "https://dns.alidns.com/resolve?name=${DOMAIN}&type=A" 2>/dev/null | jq -r '.Answer[]? | select(.type == 1) | .data' 2>/dev/null | head -1)"
    [ -n "${IP}" ] && printf '%- 16s%s\n' "${IP}" "${DOMAIN}"
    return 0
  }

  data=()
  data+=("# RR Hosts Start")
  for D in "${@}"; do
    STR="$(_resolve "${D}" 2>/dev/null)"
    [ -n "${STR}" ] && data+=("${STR}")
  done
  data+=("# RR Hosts End")

  sed -i '/# RR Hosts Start/,/# RR Hosts End/d' /etc/hosts
  [ -n "$(tail -n 1 /etc/hosts)" ] && printf '\n' >>/etc/hosts # # Add new line at the end of /etc/hosts if it doesn't already have one
  printf '%s\n' "${data[@]}" >>/etc/hosts

  exit 0
}

ACTION="${1}"
[ -z "${ACTION}" ] && ACTION="hosts"

case "${ACTION,,}" in
  "create")
    Create
    ;;
  "delete")
    Delete
    ;;
  "hosts")
    shift
    Hosts "$@"
    ;;
  *)
    echo "Unknown command!"
    ;;
esac
