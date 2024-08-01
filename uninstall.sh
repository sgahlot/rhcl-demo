#!/bin/sh

printf "\n-> Calling RHCL Config uninstall...\n"
./secure_connect/uninstall.sh

if [ $? -ne 0 ]; then
  printf "\n -->> FAILURE in RHCL config uninstallation...\n"
  exit -1
fi

printf "\n-> Calling RHCL uninstall...\n"
./initiai-setup/uninstall.sh

if [ $? -ne 0 ]; then
  printf "\n -->> FAILURE in RHCL uninstallation...\n"
  exit -1
fi

printf "\n-> Calling Camel uninstall...\n"
./camel/uninstall.sh
