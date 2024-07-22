#!/usr/bin/env bash

export FILE_PATH=${FILE_PATH:-'/root/argox'}

if source ${FILE_PATH}/env_vars.sh; then
  while true
  do
  # up
  upload_url_data() {
      if [ $# -lt 3 ]; then
          return 1
      fi

      UPLOAD_URL="$1"
      URL_NAME="$2"
      URL_TO_UPLOAD="$3"

      if command -v curl &> /dev/null; then
          curl -s -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"URL_NAME\": \"$URL_NAME\", \"URL\": \"$URL_TO_UPLOAD\"}" "$UPLOAD_URL"
      elif command -v wget &> /dev/null; then
          echo "{\"URL_NAME\": \"$URL_NAME\", \"URL\": \"$URL_TO_UPLOAD\"}" | wget --quiet --post-data=- --header="Content-Type: application/json" "$UPLOAD_URL" -O -
      else
        echo "Both curl and wget are not installed. Please install one of them to upload data."
      fi
  }

  if [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
    [ -s ${FILE_PATH}/argo.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi

  VMESS="{ \"v\": \"2\", \"ps\": \"vmess-${country_abbreviation}-${SUB_NAME}\", \"add\": \"${CF_IP}\", \"port\": \"${CFPORT}\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${VMESS_WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"
  vmess_url="vmess://$(echo "$VMESS" | base64 | tr -d '\n')"
  vless_url="vless://${UUID}@${CF_IP}:${CFPORT}?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#${country_abbreviation}-${SUB_NAME}"
  reality_url="vless://${UUID}@${MYIP}:${REAL_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PublicKey}&sid=${shortid}&type=tcp&headerType=none#${country_abbreviation}-${SUB_NAME}"
  export UPLOAD_DATA="$vless_url\n$reality_url"

  upload_url_data "${SUB_URL}" "${SUB_NAME}" "${UPLOAD_DATA}"

  if [ -e ${FILE_PATH}/argo ]; then
    if ! pgrep -f argo > /dev/null; then
      if [ -f /etc/alpine-release ]; then
        systemctl start argo
      else
        systemctl start argo.service
      fi
    fi
  fi

  if [ -e ${FILE_PATH}/web ]; then
    if ! pgrep -f web > /dev/null; then
      if [ -f /etc/alpine-release ]; then
        systemctl start web
      else
        systemctl start web.service
      fi
    fi
  fi

  if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_KEY}" ] && [ -e ${FILE_PATH}/nezha-agent ]; then
    if ! pgrep -f nezha-agent > /dev/null; then
      if [ -f /etc/alpine-release ]; then
        systemctl start nezha-agent
      else
        systemctl start nezha-agent.service
      fi
    fi
  fi

  sleep 300
  done
fi
