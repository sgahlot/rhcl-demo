#!/bin/sh

if [ $# -ne 2 ]; then
  printf "\nUSAGE: $0 <person_id> <person_name>"
  printf "\n A existing person with the given numeric person_id will be updated using the given person_name"
  printf "\n Please make sure a person exists with the given person_id"
  printf "\nExiting!!!\n"
  exit -1
fi

counter=0

person_id=$1
person_updated_name="$2"
header_api_key="api_key: secret"
header_content_type="Content-Type: application/json"
body_json=$(printf '{"id": %s, "name": "%s"}' "$person_id" "$person_updated_name")
api_endpoint="https://$(oc get httproute kamel-rest -n ${KAMEL_NS} -o=jsonpath='{.spec.hostnames[0]}')/api/person"

printf "\nTesting the kamel route for PUT operation - with API key in the header - should get 200 or 500 response...\n"
until curl -XPUT -H "$header_api_key" -H "$header_content_type" -s -k -o /dev/null -w "%{http_code}" "$api_endpoint" -d "$body_json" | grep -E "[245][0-9][0-9]"
do
  printf '.'
  sleep 1
  if [ $counter -gt 300 ]; then
    CURL_RESP=`curl -XPUTT -H "$header_api_key" -H "$header_content_type" -s -k -o /dev/null -w "%{http_code}" "$api_endpoint" -d "$body_json"`
    printf "\n\n -->> ERROR:: Curl command should have returned 200 response but we got %d instead <<--\n Exiting!!!\n\n" $CURL_RESP
    exit
  fi
  (( counter++ ))
done

printf "\n\n -->> Route tested successfully (for PUTT call) after %d seconds...\n" $counter
