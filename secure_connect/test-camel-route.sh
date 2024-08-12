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
  elif [ "$OPENID_AUTH_URL" == "" ]; then
    printf "\n ERROR: Please setup 'OPENID_AUTH_URL' env variable\n"
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

  # set -x
  curl -X${http_method} -H "$header_auth" -H "$header_content_type" -s -k "$api_endpoint" -d "$body_json"
  # set +x
  echo ""
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
}


function process_cmd_args() {

  if [ $# -eq 0 ]; then
    USAGE_COMMON
  fi

  perform_call "$@"
}

process_cmd_args "$@"
