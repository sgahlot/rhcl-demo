#!/bin/sh

CURR_DIR=`dirname "$0"`
cd $CURR_DIR

KS_NAMESPACE="kuadrant-system"
DELETE_PARAMS="--wait=true --cascade=background --ignore-not-found --timeout=300s"

printf "\nDeleting kuadrant config...\n"
oc delete -f 06-kuadrant-config.yml $DELETE_PARAMS

printf "\nUninstalling Kuadrant operator...\n"
CSV=`oc get subscription -n kuadrant-system kuadrant-operator -o yaml | grep currentCSV | awk '{print $2}'`
oc delete -f 05-kuadrant-op.yml $DELETE_PARAMS
oc delete clusterserviceversion $CSV -n $KS_NAMESPACE

printf "\nDeleting CatalogSource for Kuadrant operator image...\n"
oc delete -f 03-catalog-source.yml $DELETE_PARAMS

printf "\nDeleting operators..."
for i in 'authorino-operator-stable-kuadrant-operator-catalog-kuadrant-system' \
         'dns-operator-stable-kuadrant-operator-catalog-kuadrant-system' \
         'limitador-operator-stable-kuadrant-operator-catalog-kuadrant-system' \
         'cert-manager-stable-community-operators-openshift-marketplace'
do
    printf "\nDeleting $i operator subscription...\n"
    CSV=`oc get subscription $i -n $KS_NAMESPACE -o yaml | grep currentCSV | awk '{print $2}'`
    oc delete subscription $i -n $KS_NAMESPACE $DELETE_PARAMS

    printf "\nDeleting $i operator CSV ($CSV)...\n"
    oc delete clusterserviceversion $CSV -n $KS_NAMESPACE $DELETE_PARAMS
done

printf "\nDeleting CRD associated with Kuadrant Cert-manager...\n"
oc get crd -l operators.coreos.com/cert-manager.kuadrant-system -o Name | xargs oc delete $DELETE_PARAMS

printf "\nDeleting CRD associated with Kuadrant...\n"
# oc get crd | grep kuadrant | awk '{print $1}' | xargs oc delete crd
oc get crd -l operators.coreos.com/authorino-operator.kuadrant-system -o Name | xargs oc delete $DELETE_PARAMS
oc get crd -l operators.coreos.com/dns-operator.kuadrant-system -o Name | xargs oc delete $DELETE_PARAMS
oc get crd -l operators.coreos.com/limitador-operator.kuadrant-system -o Name | xargs oc delete $DELETE_PARAMS
oc get crd -l operators.coreos.com/kuadrant-operator.kuadrant-system -o Name | xargs oc delete $DELETE_PARAMS

printf "\nDeleting $KS_NAMESPACE namespace...\n"
oc delete ns $KS_NAMESPACE

printf "\nDeleting 'ingress-gateway' namespace...\n"
oc delete ns ingress-gateway

printf "\nDeleting Istio configuration...\n"
oc delete -f 02-istio-configure.yml $DELETE_PARAMS

printf "\nUninstalling Sail operator for Istio service mesh...\n"
oc delete -f 01-istio-sail-op.yml

printf "\nDeleting CRD associated with Istio...\n"
oc get crd -l operators.coreos.com/sailoperator.istio-system -o Name | xargs oc delete $DELETE_PARAMS

printf "\nDeleting 'istio-system' namespace...\n"
oc delete ns istio-system

printf "\nUninstalling Gateway API v1...\n"
oc delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml $DELETE_PARAMS

printf "\n RHCL and its dependent components are uninstalled...\n"
