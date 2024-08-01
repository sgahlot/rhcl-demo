#!/bin/sh

api_endpoint="https://$(oc get httproute kamel-rest -n ${KAMEL_NS} -o=jsonpath='{.spec.hostnames[0]}')/api/person"

printf "\nTesting the Person route for GET operation - should get 200 response...\n"
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
