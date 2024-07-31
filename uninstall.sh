#!/bin/sh

printf "\n-> Calling RHCL Config uninstall...\n"
cd secure_connect
./uninstall.sh
cd ..

if [ $? -ne 0 ]; then
  printf "\n -->> FAILURE in RHCL config uninstallation...\n"
  exit -1
fi

printf "\n-> Calling RHCL uninstall...\n"
cd initiai-setup
./uninstall.sh
cd ..

if [ $? -ne 0 ]; then
  printf "\n -->> FAILURE in RHCL uninstallation...\n"
  exit -1
fi

printf "\n-> Calling Camel uninstall...\n"
cd camel
./uninstall.sh
cd ..
