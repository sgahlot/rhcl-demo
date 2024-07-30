#!/bin/sh

printf "\nTesting the toystore route for GET operation - should get 200 response...\n"
counter=0
until curl -s -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys" | grep 200
do
  printf '.'
  sleep 1
  (( counter++ ))
  # Wait for some time we just implemeted a new AuthPolicy and that takes some time to come into effect
  if [ $counter -gt 300 ]; then
    printf "\n\n -->> ERROR:: Curl command should have returned 200 response but we got %d instead <<--\n Exiting!!!\n\n" $curl_http_res
    curl -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"
    printf "\n"
    exit
  fi
done
printf "Succeeded in getting 200 response from HttpRoute after %d seconds...\n" $counter

printf "\nTesting the toystore route for POST operation - with API key in the header - should get 200 response...\n"
curl_http_res=`curl -XPOST -H 'api_key: secret' -s -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"`
if [ $curl_http_res -ne 200 ]; then
  printf "\n\n -->> ERROR:: Curl command should have returned 200 response but we got %d instead <<--\n Exiting!!!\n\n" $curl_http_res
  printf "Actual response: "
  curl -XPOST -H 'api_key: secret' -k "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"
  exit
fi

printf "\n\n -->> Route tested successfully...\n"
