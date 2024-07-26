#!/bin/sh


# printf "\nTesting connectivity using the newly created HttpRoute - should be 403\n"
# counter=0
# until curl -s -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys" | grep 403
# do
#   printf '.'
#   sleep 1
#   (( counter++ ))
#   # Wait for some time as it gives "Could not resolve host" error when sending the curl immediately after creating the route
#   if [ $counter -gt 300 ]; then
#     printf "\n\n -->> ERROR:: Connectivity for the newly created HttpRoute failed (waited 300 sec)... <<--\n Exiting!!!\n\n"
#     curl -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"
#     printf "\n"
#     exit
#   fi
# done
# printf "Succeeded in connecting to the HttpRoute after %d seconds...\n" $counter


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

# printf "\nTesting the toystore route for POST operation - should get 401 response...\n"
# curl_http_res=`curl -XPOST -s -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"`
# if [ $curl_http_res -ne 401 ]; then
#   printf "\n\n -->> ERROR:: Curl command should have returned 401 response but we got %d instead <<--\n Exiting!!!\n\n" $curl_http_res
#   printf "Actual response: "
#   curl -XPOST -k "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"
#   exit
# fi

printf "\nTesting the toystore route for POST operation - with API key in the header - should get 200 response...\n"
curl_http_res=`curl -XPOST -H 'api_key: secret' -s -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"`
if [ $curl_http_res -ne 200 ]; then
  printf "\n\n -->> ERROR:: Curl command should have returned 200 response but we got %d instead <<--\n Exiting!!!\n\n" $curl_http_res
  printf "Actual response: "
  curl -XPOST -H 'api_key: secret' -k "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"
  exit
fi

printf "\n\n -->> Route tested successfully...\n"
