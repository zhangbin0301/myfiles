#!/bin/bash

if source /root/env.yml; then
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

  if [ -s "${FILE_PATH}/argo.log" ]; then
    export ARGO_DOMAIN=$(cat ${FILE_PATH}/argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
    # export ARGO_DOMAIN=$(cat ${FILE_PATH}/argo.log | grep -o "https://.*trycloudflare.com" | tail -n 1 | sed 's/https:\/\///')
  fi

  if [ -n "$XHTTP_PATH" ]; then
    vless_url="vless://${UUID}@${CF_IP}:${CFPORT}?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#${country_abbreviation}-${SUB_NAME}"
    xhttp_url="vless://${UUID}@${CF_IP}:${CFPORT}?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=xhttp&host=${ARGO_DOMAIN}&path=%2F${XHTTP_PATH}%3Fed%3D2048&mode=packet-up#${country_abbreviation}-${SUB_NAME}-xhttp"
    UPLOAD_DATA="$vless_url\n$xhttp_url"
  else
    # VMESS="{ \"v\": \"2\", \"ps\": \"${country_abbreviation}-${SUB_NAME}\", \"add\": \"${CF_IP}\", \"port\": \"${CFPORT}\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${VMESS_WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"
    # vmess_url="vmess://$(echo "$VMESS" | base64 | tr -d '\n')"
    vless_url="vless://${UUID}@${CF_IP}:${CFPORT}?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#${country_abbreviation}-${SUB_NAME}"
    # UPLOAD_DATA="$vmess_url\n$vless_url"
    UPLOAD_DATA="$vless_url"
  fi

  if [ -n "$REAL_PORT" ] && [ -n "$shortid" ]; then
    realitytcp_url="vless://${UUID}@${MYIP}:${REAL_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PublicKey}&sid=${shortid}&type=tcp&headerType=none#${country_abbreviation}-${SUB_NAME}-realtcp"
    UPLOAD_DATA="$UPLOAD_DATA\n$realitytcp_url"
  elif [ -n "$REAL_PORT" ] && [ -z "$shortid" ]; then
    realitytcp_url="vless://${UUID}@${MYIP}:${REAL_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PublicKey}&type=tcp&headerType=none#${country_abbreviation}-${SUB_NAME}-realtcp"
    UPLOAD_DATA="$UPLOAD_DATA\n$realitytcp_url"
  fi

  export UPLOAD_DATA
  # echo -e "${UPLOAD_DATA}"

  upload_url_data "${SUB_URL}" "${SUB_NAME}" "${UPLOAD_DATA}"
  # echo "upload ok!"

  sleep 100
  done
fi
