#!/bin/bash

while true
do

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
  [ -s ${FILE_PATH}/boot.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/boot.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  # [ -s ${FILE_PATH}/boot.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/boot.log | grep -o "https://.*trycloudflare.com" | tail -n 1 | sed 's/https:\/\///')
fi

# vmess_url="vmess://$(echo "$VMESS" | base64 | tr -d '\n')"
vless_url="vless://${UUID}@${CF_IP}:${CFPORT}?host=${ARGO_DOMAIN}&path=%2Fvless%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}"
hysteria_url="hysteria2://${UUID}@${MYIP}:${HY2_PORT}/?sni=www.bing.com&alpn=h3&insecure=1#${country_abbreviation}-${SUB_NAME}"
tuic_url="tuic://${UUID}:${tuicpass}@${MYIP}:${TUIC_PORT}?sni=www.bing.com&congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#${country_abbreviation}-${SUB_NAME}"
reality_url="vless://${UUID}@${MYIP}:${REAL_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${public_key}&type=tcp&headerType=none#${country_abbreviation}-${SUB_NAME}"

UPLOAD_DATA="$vless_url"

if [ -n "$HY2_PORT" ]; then
  UPLOAD_DATA="$UPLOAD_DATA\n$hysteria_url"
fi

if [ -n "$TUIC_PORT" ]; then
  UPLOAD_DATA="$UPLOAD_DATA\n$tuic_url"
fi

if [ -n "$REAL_PORT" ]; then
  UPLOAD_DATA="$UPLOAD_DATA\n$reality_url"
fi

export UPLOAD_DATA
# echo -e "${UPLOAD_DATA}"

upload_url_data "${SUB_URL}" "${SUB_NAME}" "${UPLOAD_DATA}"
# echo "upload ok!"

sleep 100
done
