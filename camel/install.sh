#!/bin/sh

CURR_DIR=`dirname "$0"`
cd $CURR_DIR

KAMEL_FOUND=`which kamel`
if [ "$KAMEL_FOUND" == "" ]; then
  printf "\n ERROR: kamel binary NOT found in the path. Please install it from OCP 'command line tools' and re-run this script\n"
  exit -1
fi

if [ "$kamelNS" == "" ]; then
  printf "\n ERROR: Please setup 'kamelNS' env variable to point to the namespace that will be used for Kamel application\n"
  exit -1
fi

printf "\nSetting up Kamel using the binary found in [%s]. Will be used to setup kamel \n" $KAMEL_FOUND

printf "\nCreating %s namespace...\n" $kamelNS
oc create ns $kamelNS
oc project $kamelNS

printf "\nInstall kamel in the %s namespace...\n" $kamelNS
kamel install

printf "\nRunning API in the %s namespace (in the background)...\n"
kamel run RestApi.java

printf "\n\n *** Kamel app is getting deployed. Please give it 10 mins before running any messages through ***\n\n"
