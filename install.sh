#!/bin/sh

function check_env() {
  missing_vars=()
  required_vars=(GATEWAY_NS GATEWAY_NAME CLUSTER_ISSUER_NAME HOSTED_ZONE_ID ROOT_DOMAIN_ID \
                 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION EMAIL KAMEL_NS \
                 OPENID_HOST OPENID_REALM OPENID_CLIENT OPENID_CLIENT_SECRET)
  for var in "${required_vars[@]}"; do
    [ -z "${!var}" ] && { missing_vars+=("$var"); }
  done

  missing_vars_len=${#missing_vars[@]}
  if [ $missing_vars_len -gt 0 ]; then
    printf "\n ERROR: Please setup the mandatory env variables first.\n"
    printf "\n The following env vars are empty or not set:\n"
    for var in "${missing_vars[@]}"; do
        printf "  - $var\n"
    done
    exit 1
  fi
}

function process_cmd_args() {
  check_env

  printf "\n-> Calling Camel install...\n"
  ./camel/install.sh

  if [ $? -ne 0 ]; then
    printf "\n -->> FAILURE in Camel installation...\n"
    exit -1
  fi

  printf "\n-> Calling RHCL install...\n"
  ./initiai-setup/install.sh

  if [ $? -ne 0 ]; then
    printf "\n -->> FAILURE in RHCL installation...\n"
    exit -1
  fi

  printf "\n-> Calling RHCL config install...\n"
  ./secure_connect/install.sh
}

process_cmd_args "$@"
