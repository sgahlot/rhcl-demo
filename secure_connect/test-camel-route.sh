#!/bin/sh


function check_env() {
  if [ "$CAMEL_NS" == "" ]; then
    printf "\n ERROR: Please setup 'CAMEL_NS' env variable to point to the namespace where the Camel application is deployed\n"
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
  elif [ "$OPENID_ISSUER_URL" == "" ]; then
    printf "\n ERROR: Please setup 'OPENID_ISSUER_URL' env variable\n"
    exit 1
  elif [ "$OPENID_TOKEN_URL" == "" ]; then
    printf "\n ERROR: Please setup 'OPENID_TOKEN_URL' env variable\n"
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

     If the method is 'GET' then one of the following two options can be specified
     on the command line:
      - status: only status endpoint will be invoked
      - data: this will retrieve and display all the persons in the application

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

  if [ "$2" == "status" ]; then
    api_endpoint="$1/status"
  fi

  # printf "\nTesting the Camel route for GET operation (for %s) - should get 200 response...\n" $2
  # echo "API - [$api_endpoint]"
  # set -x
  curl -s -k "$api_endpoint"
  # set +x
  echo ""
}

function perform_post_or_put_call() {
  api_endpoint="$1"
  person_id=$2
  person_name="$3"
  http_method="$4"

  # Get the JWT to use in the next POST/PUT
  get_token

  header_content_type="Content-Type: application/json"
  body_json=$(printf '{"id": %s, "name": "%s"}' "$person_id" "$person_name")
  header_auth="Authorization: Bearer $ACCESS_TOKEN"

  printf "\nUsing the body [%s] for %s operation using JWT for Auth..." "$body_json" "$http_method"

  #set -x
  CURL_RESP=$(curl -X${http_method} -H "$header_auth" -H "$header_content_type" -s -k -w "%{http_code}" "$api_endpoint" -d "$body_json")
  http_code=${CURL_RESP: -3}

  case "$CURL_RESP" in
    40[13]*)
      printf "\n\n -->> ERROR: Got 401 (Unauthorized) error from the server.\n"
      show_bad_openid_issuer_msg
      printf "\n Exiting!!!\n"
      exit 1
  esac

  #set +x
  echo ""
}

function show_bad_openid_issuer_msg() {
  printf "\n Is your OPENID_ISSUER_URL correctly set?"
  printf "\n   Current value: [$OPENID_ISSUER_URL]\n"
  printf "\n Set it correctly and run the following command:"
  printf '\n envsubst < $RHCL_DEMO_HOME/secure_connect/09-camel-auth-policy.yml | oc apply -f -\n'
}

function perform_call() {
  check_env

  api_endpoint="https://$(oc get httproute ${CAMEL_ROUTE_NAME} -n ${CAMEL_NS} -o=jsonpath='{.spec.hostnames[0]}')/api/person"

  http_method=""
  case $1 in
    [gG][eE][tT])
      http_method="GET"
      if [ $# -ne 2 ]; then
        printf "\n*** Missing option for GET call\n\n"
        USAGE
      else
          case $2 in
            [sS][tT][aA][tT][uU][sS])
              perform_get_call "$api_endpoint" "status"
              ;;
            [dD][aA][tT][aA])
              perform_get_call "$api_endpoint" "data"
              ;;
            *)
              printf "\nOnly 'status' or 'data' are allowed when invoking GET call"
              printf "\n  GET arg: [%s] <- INVALID VALUE\n\n" $2
              USAGE
          esac
      fi
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
  perform_post_or_put_call "$api_endpoint" "$2" "$3" "$http_method"
}

function get_token() {
  check_env_for_auth

  header_content_type="Content-Type: application/x-www-form-urlencoded"
  grant_type='grant_type=client_credentials'
  client_id="client_id=${OPENID_CLIENT}"
  client_secret="client_secret=${OPENID_CLIENT_SECRET}"

  export ACCESS_TOKEN=$(curl -s -k -H "$header_content_type" \
          -d "$grant_type" -d 'scope=openid' -d "$client_id" -d "$client_secret" \
          "${OPENID_TOKEN_URL}" | jq -r '.access_token')

  if [ "$ACCESS_TOKEN" == "" -o "$ACCESS_TOKEN" == "null" ]; then
    printf "\n\n -->> ERROR: Unable to get the access token.\n"
    show_bad_openid_issuer_msg

    printf "\n\n Command used to retrieve JWT:\n"
    set -x
    curl -k -H "$header_content_type" \
          -d "$grant_type" -d 'scope=openid' -d "$client_id" -d "$client_secret" \
          "${OPENID_TOKEN_URL}"
    set +x
    exit 1
  fi
}


function process_cmd_args() {

  if [ $# -eq 0 ]; then
    USAGE_COMMON
  fi

  perform_call "$@"
}

process_cmd_args "$@"
