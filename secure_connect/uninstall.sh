#!/bin/sh

echo "Deleting all the resources used for securing and connecting the APIs..."
for i in 10-toystore-auth-policy.yml \
         09-api-key-secret.yml \
         08-toystore-httproute.yml \
         07-dns-policy.yml \
         06-tls-policy.yml \
         05-auth-policy.yml \
         04-gateway.yml \
         03-tls-issuer.yml \
         02-create-managed-zone.yml
do
  echo "Deleting using $i..."
  envsubst < $i | oc delete -f -
done

echo "Deleting toystore namespace..."
oc delete ns toystore

oc delete ns $gatewayNS
