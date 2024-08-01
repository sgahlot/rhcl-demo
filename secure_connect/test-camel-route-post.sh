#!/bin/sh

if [ $# -ne 1 ]; then
  printf "\nUSAGE: $0 <numeric_id>"
  printf "\n A new person entry will be created using the numeric id provided on command line"
  printf "\n Please make sure the id does not already belong to an existing person"
  printf "\nExiting!!!\n"
  exit -1
fi

counter=0

person_id=$1
header_api_key="api_key: secret"
header_content_type="Content-Type: application/json"
body_json=$(printf '{"id": %s, "name": "person-%s"}' "$person_id" "$person_id")
api_endpoint="https://$(oc get httproute kamel-rest -n ${KAMEL_NS} -o=jsonpath='{.spec.hostnames[0]}')/api/person"

printf "\nTesting the kamel route for POST operation - with API key in the header - should get 200 or 500 response...\n"
until curl -XPOST -H "$header_api_key" -H "$header_content_type" -s -k -o /dev/null -w "%{http_code}" "$api_endpoint" -d "$body_json" | grep -E "[245][0-9][0-9]"
do
  printf '.'
  sleep 1
  if [ $counter -gt 300 ]; then
    CURL_RESP=`curl -XPOST -H "$header_api_key" -H "$header_content_type" -s -k -o /dev/null -w "%{http_code}" "$api_endpoint" -d "$body_json"`
    printf "\n\n -->> ERROR:: Curl command should have returned 200 response but we got %d instead <<--\n Exiting!!!\n\n" $CURL_RESP
    exit
  fi
  (( counter++ ))
done

printf "\n\n -->> Route tested successfully (for POST call) after %d seconds...\n" $counter
