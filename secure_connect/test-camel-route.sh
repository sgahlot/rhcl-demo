#!/bin/sh


function check_env() {
  if [ "$KAMEL_NS" == "" ]; then
    printf "\n ERROR: Please setup 'KAMEL_NS' env variable to point to the namespace where the Camel application is deployed\n"
    exit 1
  fi  
}

function check_env_for_auth() {
  if [ "$OPENID_CLIENT" == "" ]; then
    printf "\n ERROR: Please setup 'OPENID_CLIENT' env variable\n"
    exit 1
  elif [ "$OPENID_CLIENT_SECRET" == "" ]; then
    printf "\n ERROR: Please setup 'OPENID_CLIENT_SECRET' env variable\n"
    exit 1
  elif [ "$OPENID_AUTH_URL" == "" ]; then
    printf "\n ERROR: Please setup 'OPENID_AUTH_URL' env variable\n"
    exit 1
  elif [ "$OPENID_USER" == "" ]; then
    printf "\n ERROR: Please setup 'OPENID_USER' env variable\n"
    exit 1
  elif [ "$OPENID_PASS" == "" ]; then
    printf "\n ERROR: Please setup 'OPENID_PASS' env variable\n"
    exit 1
  fi  
}

function USAGE_COMMON() {
  cat <<- USAGE_COMMON_INFO
    USAGE: $0 <HTTP_METHOD>
     where HTTP_METHOD is one of the following:
      - GET
      - POST
      - PUT
    Exiting!!!
USAGE_COMMON_INFO
  exit 1
}

function USAGE() {
  cat <<- USAGE_INFO
    USAGE: $0 <HTTP_METHOD> <person_id> <person_name>
     where HTTP_METHOD is one of the following:
      - GET
      - POST
      - PUT    

     If the method is 'POST' then a new person entry will be created using the 
     given 'person_id' and 'person_name'.
      ** Please make sure the id does not already belong to an existing person **

     If the method is 'PUT' then the existing person with the given 'person_id'
     will person_name" be updated using the given 'person_name'
      ** Please make sure a person exists with the given person_id **

    Exiting!!!
USAGE_INFO
  exit 1
}

function perform_get_call() {
  api_endpoint="$1"

  printf "\nTesting the Camel route for GET operation - should get 200 response...\n"
  counter=0
  until curl -s -k -o /dev/null -w "%{http_code}" "$api_endpoint/status" | grep -E "200|403"
  do
    printf '.'
    sleep 1
    (( counter++ ))
    # Wait for some time we just implemeted a new AuthPolicy and that takes some time to come into effect
    if [ $counter -gt 300 ]; then
      CURL_RESP=`curl -k -o /dev/null -w "%{http_code}" "$api_endpoint/status"`
      printf "\n\n -->> ERROR:: Curl command should have returned 200 response but we got %d instead <<--\n Exiting!!!\n\n" $CURL_RESP
      exit
    fi
  done

  printf "\n\n -->> Route tested successfully (for GET call) after %d seconds...\n" $counter
}

function perform_call() {
  check_env

  api_endpoint="https://$(oc get httproute kamel-rest -n ${KAMEL_NS} -o=jsonpath='{.spec.hostnames[0]}')/api/person"

  http_method=""
  case $1 in
    [gG][eE][tT])
      http_method="GET"
      perform_get_call "$api_endpoint"
      exit 0
      ;;
    [pP][uU][tT])
      http_method="PUT"
      ;;
    [Pp][Oo][sS][tT])
      http_method="POST"
      ;;
    *)
      printf "\nOnly GET/POST or PUT are allowed as the first argument"
      printf "\n  first arg: [%s] <- INVALID VALUE" $1
      printf "\nExiting!!!\n"
      exit -1
  esac

  if [ $# -ne 3 ]; then
    USAGE
  fi
  person_id=$2
  person_name="$3"

  get_token

  header_content_type="Content-Type: application/json"
  body_json=$(printf '{"id": %s, "name": "%s"}' "$person_id" "$person_name")
  header_auth="Authorization: Bearer $ACCESS_TOKEN"

  printf "\nTesting the Camel route for %s operation using JWT for Auth - should get either 200 or 500 response...\n" "$http_method"
  # http_method="-X${http_method}"

  # echo "\n header_auth=[$header_auth]\n"

  curl -X${http_method} -H "$header_auth" -H "$header_content_type" -s -k -o /dev/null -w "%{http_code}" "$api_endpoint" -d "$body_json"
}

function get_token() {
  check_env_for_auth

  header_content_type="Content-Type: application/x-www-form-urlencoded"
  grant_type='grant_type=client_credentials'
  client_id="client_id=${OPENID_CLIENT}"
  client_secret="client_secret=${OPENID_CLIENT_SECRET}"
  user="username=${OPENID_USER}"
  pass="password=${OPENID_PASS}"
  openid_token_url="${OPENID_AUTH_URL}/protocol/openid-connect/token"

  export ACCESS_TOKEN=$(curl -s -k -H "$header_content_type" \
          -d "$grant_type" -d 'scope=openid' -d "$client_id" -d "$client_secret" \
          "${openid_token_url}" | jq -r '.access_token')

  if [ "$ACCESS_TOKEN" == "" -o "$ACCESS_TOKEN" == "null" ]; then
    printf "\n\n -->> ERROR: Unable to get the access token. Command used:\n"
    set -x
    $(curl -k -H "$header_content_type" \
          -d "$grant_type" -d 'scope=openid' -d "$client_id" -d "$client_secret" \
          "${openid_token_url}")
    set +x
    exit 1
  fi

  # printf "%s\n" $ACCESS_TOKEN
}


function process_cmd_args() {

  if [ $# -eq 0 ]; then
    USAGE_COMMON
  fi

  perform_call "$@"
}

process_cmd_args "$@"

