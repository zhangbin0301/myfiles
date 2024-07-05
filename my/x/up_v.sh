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

if [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
  [ -s ${FILE_PATH}/argo.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
fi

export VM_URL="vmess://$(echo "$VMESS" | base64 | tr -d '\n')"
export VL_URL="vless://${UUID}@${CF_IP}:${CFPORT}?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}"
# upload_url_data "${SUB_URL}" "${SUB_NAME}" "${VM_URL}"
upload_url_data "${SUB_URL}" "${SUB_NAME}" "${VL_URL}"
# echo "upload ok!"

  if [ -e ${FILE_PATH}/argo ]; then
    [[ $(pidof argo) ]] && exit
    systemctl start argo
  fi

  if [ -e ${FILE_PATH}/web ]; then
    [[ $(pidof web) ]] && exit
    systemctl start web
  fi

  if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_KEY}" ] && [ -e ${FILE_PATH}/nezha-agent ]; then
    [[ $(pidof nezha-agent) ]] && exit
    systemctl start nezha-agent
  fi

  if [ -e ${FILE_PATH}/up.sh ]; then
    [[ $(pidof up.sh) ]] && exit
    systemctl start upload
  fi

sleep 300
done

fi
