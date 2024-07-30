#!/bin/sh

printf "\n-->> Deleting all the resources used for securing and connecting the APIs...\n"
for i in 13-toystore-auth-policy.yml    \
         12-toystore-api-key-secret.yml \
         11-toystore-httproute.yml      \
         10-kamel-auth-policy.yml       \
         09-kamel-api-key-secret.yml    \
         08-kamel-httproute.yml         \
         07-dns-policy.yml              \
         06-tls-policy.yml              \
         05-auth-policy.yml             \
         04-gateway.yml                 \
         03-tls-issuer.yml              \
         02-create-managed-zone.yml
do
  printf "Deleting using %s...\n" $i
  envsubst < $i | oc delete -f -
  printf "\n"
done

printf "\nDeleting %s namespace...\n" $devNS
oc delete ns $devNS

printf "\nDeleting %s namespace...\n" $gatewayNS
oc delete ns $gatewayNS

printf "\n Deleted all the config for RHCL\n"
