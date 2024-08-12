#!/bin/sh

CURR_DIR=`dirname "$0"`
cd $CURR_DIR

printf "Installing Gateway API v1...\n"
oc apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

# Create namespace for Sail operator and install Sail operator
printf "\nCreating 'istio-system' namespace...\n"
oc create ns istio-system

printf "\nInstalling Sail operator for Istio service mesh...\n"
oc apply -f 01-istio-sail-op.yml

printf "\nWaiting for the Sail operator to complete installation...\n"
until oc get installplan -n istio-system -o=jsonpath='{.items[0].status.phase}' 2>/dev/null | grep 'Complete'
do
    printf '.'
    sleep 1
done

# Configure Sail operator
printf "\nConfiguring Istio...\n"
oc apply -f 02-istio-configure.yml

printf "\nWaiting for the Sail operator to be fully configured...\n"
oc wait istio/default -n istio-system --for="condition=Ready=true" --timeout=300s

# Create namespace(s) for Kuadrant/ingress and create secret (based on AWS creds) in them
printf "\nCreating 'kuadrant-system' namespace...\n"
oc create ns kuadrant-system

printf "\nCreating 'ingress-gateway' namespace...\n"
oc create ns ingress-gateway

printf "\nCreating secret (using AWS env vars) for TLS - in kuadrant-system namespace...\n"
envsubst < 04-secret.yml | oc apply -f - -n kuadrant-system

printf "\nCreating secret (using AWS env vars) for managing DNS records - in ingress-gateway namespace...\n"
envsubst < 04-secret.yml | oc apply -f - -n ingress-gateway

# Install Kuadrant operator
printf "\nApplying CatalogSource for Kuadrant operator image...\n"
oc apply -f 03-catalog-source.yml

printf "\nInstalling Kuadrant operator...\n"
oc apply -f 05-kuadrant-op.yml

printf "\nWaiting for the Kuadrant operator to complete installation...\n"
until oc get installplan -n kuadrant-system -o=jsonpath='{.items[0].status.phase}' 2>/dev/null | grep 'Complete'
do
    printf '.'
    sleep 1
done

printf "\nConfiguring Kuadrant...\n"
oc apply -f 06-kuadrant-config.yml

printf "\n\n -->> Installation complete. Proceed to securing and connecting the APIs\n"
