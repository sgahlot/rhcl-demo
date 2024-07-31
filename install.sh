#!/bin/sh

printf "\n-> Calling Camel install...\n"
cd camel
./install.sh
cd ..

if [ $? -ne 0 ]; then
  printf "\n -->> FAILURE in Camel installation...\n"
  exit -1
fi

printf "\n-> Calling RHCL install...\n"
cd initiai-setup
./install.sh
cd ..

if [ $? -ne 0 ]; then
  printf "\n -->> FAILURE in RHCL installation...\n"
  exit -1
fi

printf "\n-> Calling RHCL config install...\n"
cd secure_connect
./install.sh
cd ..
