#!/usr/bin/env bash

check_hostname_change() {
  if [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
    [ -s ${FILE_PATH}/boot.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/boot.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi
}

while true
do
# 上传订阅
upload_url_data() {
    if [ $# -lt 3 ]; then
        return 1
    fi

    UPLOAD_URL="$1"
    URL_NAME="$2"
    URL_TO_UPLOAD="$3"

    # 检查curl命令是否存在
    if command -v curl &> /dev/null; then

        curl -s -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"URL_NAME\": \"$URL_NAME\", \"URL\": \"$URL_TO_UPLOAD\"}" "$UPLOAD_URL"

    # 检查wget命令是否存在
    elif command -v wget &> /dev/null; then

        echo "{\"URL_NAME\": \"$URL_NAME\", \"URL\": \"$URL_TO_UPLOAD\"}" | wget --quiet --post-data=- --header="Content-Type: application/json" "$UPLOAD_URL" -O -

    else
        echo "Both curl and wget are not installed. Please install one of them to upload data."
    fi
}

check_hostname_change

export UPLOAD_DATA="vless://${UUID}@${CF_IP}:${CFPORT}?host=${ARGO_DOMAIN}&path=%2F&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#${country_abbreviation}-${SUB_NAME}"
# export UPLOAD_DATA="vless://${UUID}@${ARGO_DOMAIN}:${CFPORT}?host=${ARGO_DOMAIN}&path=%2F&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#${country_abbreviation}-${SUB_NAME}"

if [ -n "$SUB_URL" ]; then
  upload_url_data "${SUB_URL}" "${SUB_NAME}" "${UPLOAD_DATA}"
  echo "upload ok !"
fi

if [ -n "$openkeepalive" ] && [ "$openkeepalive" != "0" ]; then
  if [[ $(pidof server) ]]; then
    echo "server is already running !"
  else
    if [ -e ${FILE_PATH}/server ] && [ -e ${FILE_PATH}/cfstart.sh ]; then
      bash ${FILE_PATH}/cfstart.sh
      sleep 3
      check_hostname_change
      echo "server runs again !"
    fi
  fi

  if [[ $(pidof npm) ]]; then
    echo "npm is already running !"
  else
    if [ -e ${FILE_PATH}/npm ]; then
      ${FILE_PATH}/npm -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} > /dev/null 2>&1 &
      echo "npm runs again !"
    fi
  fi
fi

sleep 50
done
