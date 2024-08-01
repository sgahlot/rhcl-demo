#!/bin/sh

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
