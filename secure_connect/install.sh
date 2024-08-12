#!/bin/sh

CURR_DIR=`dirname "$0"`
cd $CURR_DIR

# Create namespace for Gateway
printf "\nCreating $GATEWAY_NS namespace...\n"
oc create ns $GATEWAY_NS

printf "\nCreating secret (using AWS env vars) for ManagedZone - in %s namespace...\n" $GATEWAY_NS
envsubst < 01-secret.yml | oc apply -f - -n $GATEWAY_NS

printf "\nCreating ManagedZone - used by Kuadrant to setup DNS configuration...\n"
envsubst < 02-managed-zone.yml | oc apply -f -

printf "\nWaiting for the ManagedZone to be fully ready in %s namespace...\n" $GATEWAY_NS
oc wait managedzone/managedzone -n $GATEWAY_NS --for="condition=Ready=true" --timeout=300s

printf "\nDefining a TLS issuer for TLS certificates for secure communications to the Gateway...\n"
envsubst < 03-tls-issuer.yml | oc apply -f -

printf "\nWaiting for the ClusterIssuer to be ready...\n"
oc wait clusterissuer/${CLUSTER_ISSUER_NAME} --for="condition=ready=true" --timeout=300s

printf "\nSetting up Gateway to accept HttpRoute...\n"
envsubst < 04-gateway.yml | oc apply -f -

printf "\nChecking the status of Gateway for Accepted...\n"
counter=0
until oc get gateway ${GATEWAY_NAME} -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}' 2>/dev/null | grep -i 'accepted'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> ERROR:: Could NOT get Gateway Accepted message (waited 10 seconds) <<--\n Exiting!!!\n\n"
    oc get gateway ${GATEWAY_NAME} -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}'
    printf "\n"
    exit
  fi
done

printf "\nChecking the status of Gateway for Programmed...\n"
counter=0
until oc get gateway ${GATEWAY_NAME} -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Programmed")].message}' 2>/dev/null | grep -i 'programmed'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> ERROR:: Could NOT get Gateway Programmed message (waited 10 seconds) <<--\n Exiting!!!\n\n"
    oc get gateway ${GATEWAY_NAME} -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Programmed")].message}'
    printf "\n"
    exit
  fi
done

printf "\nVerifying we have 'Bad TLS configuration' at this moment...\n"
counter=0
until oc get gateway ${GATEWAY_NAME} -n ${GATEWAY_NS} -o=jsonpath='{.status.listeners[0].conditions[?(@.type=="Programmed")].message}' 2>/dev/null | grep -i 'bad'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> ERROR:: Could NOT get Gateway Listener Programmed message for Bad config (waited 10 seconds) <<--\n Exiting!!!\n\n"
    oc get gateway ${GATEWAY_NAME} -n ${GATEWAY_NS} -o=jsonpath='{.status.listeners[0].conditions[?(@.type=="Programmed")].message}'
    printf "\n"
    exit
  fi
done

printf "\nApplying a 'Deny All' AuthPolicy...\n"
envsubst < 05-auth-policy.yml | oc apply -f -

printf "\nVerifying our Auth policy is accepted...\n"
counter=0
until oc get authpolicy ${GATEWAY_NAME}-auth -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}' 2>/dev/null | grep -i 'accepted'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> ERROR:: Could NOT get Auth Policy Accepted message (waited 10 seconds) <<--\n Exiting!!!\n\n"
    oc get authpolicy ${GATEWAY_NAME}-auth -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}'
    printf "\n"
    exit
  fi
done

# This creates "_acme-challenge.$ROOT_DOMAIN_ID" record in the hosted zone
printf "\nApplying a TLS Policy...\n"
envsubst < 06-tls-policy.yml | oc apply -f -

printf "\nVerifying our TLS policy is accepted...\n"
counter=0
until oc get tlspolicy ${GATEWAY_NAME}-tls -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}' 2>/dev/null | grep -i 'accepted'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> ERROR:: Could NOT get TLS Policy Accepted message (waited 10 seconds) <<--\n Exiting!!!\n\n"
    oc get tlspolicy ${GATEWAY_NAME}-tls -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}'
    printf "\n"
    exit
  fi
done

printf "\nApplying a DNS Policy...\n"
envsubst < 07-dns-policy.yml | oc apply -f -

printf "\nVerifying our DNS policy is accepted...\n"
counter=0
until oc get dnspolicy ${GATEWAY_NAME}-dnspolicy -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}' 2>/dev/null | grep -i 'accepted'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> ERROR:: Could NOT get DNS Policy Accepted message (waited 10 seconds) <<--\n Exiting!!!\n\n"
    oc get dnspolicy ${GATEWAY_NAME}-dnspolicy -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Accepted")].message}'
    printf "\n"
    exit
  fi
done

# On the execution of httproute CR, several records are added to the hosted zone:
#   *.$ROOT_DOMAIN_ID CNAME, klb.$ROOT_DOMAIN_ID CNAME (US), klb.$ROOT_DOMAIN_ID CNAME (Default),
#   kuadrant-cname.us.klb.$ROOT_DOMAIN_ID TXT, us.klb.$ROOT_DOMAIN_ID CNAME, kuadrant-cname-klb.$ROOT_DOMAIN_ID TXT (US),
#   kuadrant-cname-klb.$ROOT_DOMAIN_ID TXT (Default), kuadrant-cname-wokdcard.$ROOT_DOMAIN_ID TXT (Simple)
printf "\nCreating a HTTPRoute for our Gateway to route traffic to the 'Camel' app...\n"
envsubst < 08-camel-httproute.yml | oc apply -f -

printf "\nApplying an Auth policy for GET/POST operations on the camel HTTPRoute...\n"
envsubst < 09-camel-auth-policy.yml | oc apply -f -

printf "\nVerifying the DNS policy whether it is Enforced or not...\n"
counter=0
until oc get dnspolicy ${GATEWAY_NAME}-dnspolicy -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Enforced")].message}' 2>/dev/null | grep -i 'enforced'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 10 ]; then
    printf "\n\n -->> ERROR:: Could NOT get DNS Policy Enforced message (waited 10 seconds) <<--\n Exiting!!!\n\n"
    oc get dnspolicy ${GATEWAY_NAME}-dnspolicy -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Enforced")].message}'
    printf "\n"
    exit
  fi
done

printf "\nVerifying the Auth policy whether it is Enforced or not...\n"
counter=0
until oc get authpolicy ${GATEWAY_NAME}-auth -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Enforced")].message}' 2>/dev/null | grep -Ei 'enforced|overridden|no free routes to enforce'
do
  printf '.'
  sleep 1
  (( counter++ ))
  if [ $counter -gt 30 ]; then
    printf "\n\n -->> ERROR:: Auth policy did not get enforced (waited 30 seconds) <<--\n Exiting!!!\n\n"
    printf "Auth Policy Enforced message: "
    oc get authpolicy ${GATEWAY_NAME}-auth -n ${GATEWAY_NS} -o=jsonpath='{.status.conditions[?(@.type=="Enforced")].message}'
    printf "\n\n"
    exit
  fi
done

printf "\n\n -->> APIs are secured. You can proceed to test the route...\n"
