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

upload_url_data "${SUB_URL}" "${SUB_NAME}" "${UPLOAD_DATA}"

sleep 100
done
