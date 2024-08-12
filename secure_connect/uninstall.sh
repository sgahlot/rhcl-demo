#!/bin/sh

CURR_DIR=`dirname "$0"`
cd $CURR_DIR

printf "\n-->> Deleting all the resources used for securing and connecting the APIs...\n"
for i in 09-camel-auth-policy.yml       \
         08-camel-httproute.yml         \
         07-dns-policy.yml              \
         06-tls-policy.yml              \
         05-auth-policy.yml             \
         04-gateway.yml                 \
         03-tls-issuer.yml              \
         02-managed-zone.yml
do
  printf "Deleting using %s...\n" $i
  envsubst < $i | oc delete -f - --wait=true --cascade=foreground --ignore-not-found --timeout=300s
  printf "\n"
done

printf "\nDeleting %s namespace...\n" $GATEWAY_NS
oc delete ns $GATEWAY_NS

printf "\n Deleted all the config for RHCL\n"
