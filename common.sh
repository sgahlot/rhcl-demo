#!/bin/sh

function check_env() {
  missing_vars=()
  required_vars=(GATEWAY_NS GATEWAY_NAME CLUSTER_ISSUER_NAME HOSTED_ZONE_ID ROOT_DOMAIN_ID \
                 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION EMAIL CAMEL_NS \
                 CAMEL_ROUTE_NAME OPENID_HOST OPENID_REALM OPENID_CLIENT OPENID_CLIENT_SECRET)
  for var in "${required_vars[@]}"; do
    [ -z "${!var}" ] && { missing_vars+=("$var"); }
  done

  missing_vars_len=${#missing_vars[@]}
  if [ $missing_vars_len -gt 0 ]; then
    printf "\n ERROR: Please setup the mandatory env variable(s) first.\n"
    printf "\n The following env var(s) are empty or not set:\n"
    for var in "${missing_vars[@]}"; do
        printf "  - $var\n"
    done
    exit 1
  fi
}

function check_openshift_login() {
  OC_FOUND=`which oc`
  if [ -z "$OC_FOUND" ]; then
    printf "\n ERROR: 'oc' binary NOT found in the path. Please install it before running the script\n"
    exit 1
  fi

  check_oc_login=`oc whoami 2>&1`
  case "$check_oc_login" in
    *Error*forbidden*|*error*"must be logged in"*)
      printf "\n\n --->>> Got error when querying 'oc'. Please login to OpenShift first...\n\n"
      exit 1
    ;;
  esac
}
