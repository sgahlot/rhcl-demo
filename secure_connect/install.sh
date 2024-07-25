#!/bin/sh

# Create namespace for Gateway
printf "\nCreating $gatewayNS namespace...\n"
oc create ns $gatewayNS

printf "\nCreating secret (using AWS env vars) for ManagedZone - in kuadrant-system namespace...\n"
envsubst < 01-secret.yml | oc apply -f - -n $gatewayNS

printf "\nCreating ManagedZone...\n"
envsubst < 02-create-managed-zone.yml | oc apply -f -

printf "\nWaiting for the ManagedZone to be fully ready...\n"
oc wait managedzone/managedzone -n $gatewayNS --for="condition=Ready=true"

printf "\nDefining a TLS issuer for TLS certificates for secure communications to the Gateway...\n"
envsubst < 03-tls-issuer.yml | oc apply -f -

printf "\nWaiting for the ClusterIssuer to be ready...\n"
oc wait clusterissuer/${clusterIssuerName} --for="condition=ready=true"

printf "\nSetting up Gateway to accept HttpRoute...\n"
envsubst < 04-gateway.yml | oc apply -f -

printf "\nChecking the status of Gateway for Accepted...\n"
counter=0
until oc get gateway ${gatewayName} -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}' 2>/dev/null | grep -i 'accepted'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> Could NOT get Gateway Accepted message (waited 10 seconds) <<--\n\n"
    oc get gateway ${gatewayName} -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}'
    printf "\n"
    exit
  fi
done

printf "\nChecking the status of Gateway for Programmed...\n"
counter=0
until oc get gateway ${gatewayName} -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Programmed")].message}' 2>/dev/null | grep -i 'programmed'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> Could NOT get Gateway Programmed message (waited 10 seconds) <<--\n\n"
    oc get gateway ${gatewayName} -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Programmed")].message}'
    printf "\n"
    exit
  fi
done

printf "\nVerifying we have 'Bad TLS configuration' at this moment...\n"
counter=0
until oc get gateway ${gatewayName} -n ${gatewayNS} -o=jsonpath='{.status.listeners[0].conditions[?(@.type=="Programmed")].message}' 2>/dev/null | grep -i 'bad'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> Could NOT get Gateway Listener Programmed message for Bad config (waited 10 seconds) <<--\n\n"
    oc get gateway ${gatewayName} -n ${gatewayNS} -o=jsonpath='{.status.listeners[0].conditions[?(@.type=="Programmed")].message}'
    printf "\n"
    exit
  fi
done

printf "\nApplying a 'Deny All' AuthPolicy...\n"
envsubst < 05-auth-policy.yml | oc apply -f -

printf "\nVerifying our Auth policy is accepted...\n"
counter=0
until oc get authpolicy ${gatewayName}-auth -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}' 2>/dev/null | grep -i 'accepted'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> Could NOT get Auth Policy Accepted message (waited 10 seconds) <<--\n\n"
    oc get authpolicy ${gatewayName}-auth -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}'
    printf "\n"
    exit
  fi
done

printf "\nApplying a TLS Policy...\n"
envsubst < 06-tls-policy.yml | oc apply -f -

printf "\nVerifying our TLS policy is accepted...\n"
counter=0
until oc get tlspolicy ${gatewayName}-tls -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}' 2>/dev/null | grep -i 'accepted'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> Could NOT get TLS Policy Accepted message (waited 10 seconds) <<--\n\n"
    oc get tlspolicy ${gatewayName}-tls -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}'
    printf "\n"
    exit
  fi
done

printf "\nApplying a DNS Policy...\n"
envsubst < 07-dns-policy.yml | oc apply -f -

printf "\nVerifying our DNS policy is accepted...\n"
counter=0
until oc get dnspolicy ${gatewayName}-dnspolicy -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}' 2>/dev/null | grep -i 'accepted'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> Could NOT get DNS Policy Accepted message (waited 10 seconds) <<--\n\n"
    oc get dnspolicy ${gatewayName}-dnspolicy -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}'
    printf "\n"
    exit
  fi
done

printf "\nCreating $devNS namespace...\n"
oc create ns $devNS

printf "\nDeploying a new version of 'toystore' application in the $devNS namespace...\n"
oc apply -f https://raw.githubusercontent.com/Kuadrant/kuadrant-operator/main/examples/toystore/toystore.yaml -n $devNS

printf "\nCreating a HTTPRoute for our Gateway to route traffic to the 'toystore' app...\n"
envsubst < 08-toystore-httproute.yml | oc apply -f -

printf "\nVerifying the DNS policy whether it is Enforced or not...\n"
counter=0
until oc get dnspolicy ${gatewayName}-dnspolicy -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Enforced")].message}' 2>/dev/null | grep -i 'enforced'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> Could NOT get DNS Policy Enforced message (waited 10 seconds) <<--\n\n"
    oc get dnspolicy ${gatewayName}-dnspolicy -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Enforced")].message}'
    printf "\n"
    exit
  fi
done

printf "\nVerifying the Auth policy whether it is Enforced or not...\n"
counter=0
until oc get authpolicy ${gatewayName}-auth -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Enforced")].message}' 2>/dev/null | grep -i 'enforced'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 30 ]; then
    printf "\n\n -->> Could NOT get DNS Policy Accepted message (waited 30 seconds) <<--\n\n"
    printf "Auth Policy Enforced message: "
    oc get authpolicy ${gatewayName}-auth -n ${gatewayNS} -o=jsonpath='{.status.conditions[?(@.type=="Enforced")].message}'
    printf "\n\n"
    exit
  fi
done

printf "\nTesting connectivity using the newly created HttpRoute - should be 403\n"
curl -s -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"

printf "\nApplying API key secret to allow access to the route...\n"
envsubst < 09-api-key-secret.yml | oc apply -f -

printf "\nApplying an Auth policy for GET/POST operations on the toystore HTTPRoute...\n"
envsubst < 10-toystore-auth-policy.yml | oc apply -f -

printf "\nTesting the toystore route for GET operation - should get 200 response...\n"
curl -s -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"

printf "\nTesting the toystore route for POST operation - should get 401 response...\n"
curl -XPOST -s -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"

printf "\nTesting the toystore route for POST operation - with API key in the header - should get 200 response...\n"
curl -XPOST -H 'api_key: secret' -s -k -o /dev/null -w "%{http_code}" "https://$(oc get httproute toystore -n ${devNS} -o=jsonpath='{.spec.hostnames[0]}')/v1/toys"

printf "\n\n -->> APIs are secured...\n"
