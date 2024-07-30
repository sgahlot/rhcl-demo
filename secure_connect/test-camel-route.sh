#!/bin/sh

printf "\nTesting the Person route for GET operation - should get 200 response...\n"
api_endpoint="https://$(oc get httproute kamel-rest -n ${kamelNS} -o=jsonpath='{.spec.hostnames[0]}')/api/person"
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
printf "Succeeded in getting 200 or 403 response from HttpRoute after %d seconds...\n" $counter

if [ $# -eq 0 ]; then
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

printf "\nTesting the kamel route for POST operation - with API key in the header - should get 200 response...\n"
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
printf "Succeeded in getting 200 or 403 response from HttpRoute after %d seconds...\n" $counter

printf "\n\n -->> Route tested successfully...\n"
