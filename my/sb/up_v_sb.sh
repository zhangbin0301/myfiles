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
    [ -s ${FILE_PATH}/boot.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/boot.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi

  VMESS="{ \"v\": \"2\", \"ps\": \"${ISP}-${SUB_NAME}\", \"add\": \"${CFIP}\", \"port\": \"${CFPORT}\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\", \"fp\": \"randomized\"}"

  vmess_url="vmess://$(echo "$VMESS" | base64 | tr -d '\n')"
  hysteria_url="hysteria2://${UUID}@${IP}:${H_PORT}/?sni=www.bing.com&alpn=h3&insecure=1#${ISP}-${SUB_NAME}"
  tuic_url="tuic://${UUID}:${password}@${IP}:${TUIC_PORT}?sni=www.bing.com&congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#${ISP}-${SUB_NAME}"
  reality_url="vless://${UUID}@${IP}:${SERVER_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${public_key}&type=tcp&headerType=none#${ISP}-${SUB_NAME}"

  if [ -n "$openreality" ] && [ "$openreality" != "0" ]; then
    export UPLOAD_DATA="$vmess_url\n$hysteria_url\n$tuic_url\n$reality_url"
  elif [ -z "$openreality" ]; then
    export UPLOAD_DATA="$vmess_url"
  else
    export UPLOAD_DATA="$vmess_url"
  fi
  # echo "${UPLOAD_DATA}"

  upload_url_data "${SUB_URL}" "${SUB_NAME}" "${UPLOAD_DATA}"

  if [ -e ${FILE_PATH}/server ] && [ -f /etc/alpine-release ] && [[ ! $(pgrep -laf server) ]]; then
    systemctl start argo
  fi

  if [ -e ${FILE_PATH}/web ] && [ -f /etc/alpine-release ] && [[ ! $(pgrep -laf web) ]]; then
    systemctl start web
  fi

  if [ -e ${FILE_PATH}/nezha-agent ] && [ -f /etc/alpine-release ] && [[ ! $(pgrep -laf nezha-agent) ]]; then
    systemctl start nezha-agent
  fi

  sleep 300
  done
fi
