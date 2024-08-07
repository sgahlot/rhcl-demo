#!/bin/sh

if [ "$OPENID_CLIENT" == "" ]; then
  printf "\n ERROR: Please setup 'OPENID_CLIENT' env variable\n"
  exit -1
elif [ "$OPENID_CLIENT_SECRET" == "" ]; then
  printf "\n ERROR: Please setup 'OPENID_CLIENT_SECRET' env variable\n"
  exit -1
elif [ "$OPENID_AUTH_URL" == "" ]; then
  printf "\n ERROR: Please setup 'OPENID_AUTH_URL' env variable\n"
  exit -1
elif [ "$OPENID_USER" == "" ]; then
  printf "\n ERROR: Please setup 'OPENID_USER' env variable\n"
  exit -1
elif [ "$OPENID_PASS" == "" ]; then
  printf "\n ERROR: Please setup 'OPENID_PASS' env variable\n"
  exit -1
fi

header_content_type="Content-Type: application/x-www-form-urlencoded"
grant_type='grant_type=client_credentials'
client_id="client_id=${OPENID_CLIENT}"
client_secret="client_secret=${OPENID_CLIENT_SECRET}"
user="username=${OPENID_USER}"
pass="password=${OPENID_PASS}"
openid_token_url="${OPENID_AUTH_URL}/protocol/openid-connect/token"
# set -x
export ACCESS_TOKEN=$(curl -s -k -H "$header_content_type" \
        -d "$grant_type" -d 'scope=openid' -d "$client_id" -d "$client_secret" \
        "${openid_token_url}" | jq -r '.access_token')
# set +x

if [ "$ACCESS_TOKEN" == "" -o "$ACCESS_TOKEN" == "null" ]; then
  printf "\n\n -->> ERROR: Unable to get the access token. Command used:\n"
  set -x
  $(curl -k -H "$header_content_type" \
        -d "$grant_type" -d 'scope=openid' -d "$client_id" -d "$client_secret" \
        "${openid_token_url}")
  set +x
  exit -1
fi

printf "%s\n" $ACCESS_TOKEN
