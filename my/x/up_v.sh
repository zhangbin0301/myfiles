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

  splithttp_url="vless://${UUID}@${MYIP}:${SPLIT_PORT}?path=%2Fsplithttp&security=tls&encryption=none&alpn=h3&host=${MYIP}&type=splithttp#${country_abbreviation}-${SUB_NAME}-splithttp"
  reality_url="vless://${UUID}@${MYIP}:${REAL_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PublicKey}&type=tcp&headerType=none#${country_abbreviation}-${SUB_NAME}-tcp"
  reality_grpc_url="vless://${UUID}@${MYIP}:${REAL_PORT}?security=reality&sni=${SNI}&fp=chrome&pbk=${PublicKey}&type=grpc&serviceName=grpc&encryption=none#${country_abbreviation}-${SUB_NAME}-grpc"

  UPLOAD_DATA="$splithttp_url\n$reality_url\n$reality_grpc_url"

  export UPLOAD_DATA
  # echo -e "${UPLOAD_DATA}"

  upload_url_data "${SUB_URL}" "${SUB_NAME}" "${UPLOAD_DATA}"
  # echo "upload ok!"

  sleep 100
  done
fi
