#!/bin/sh

CURR_DIR=`dirname "$0"`
cd $CURR_DIR

printf "\nCreating %s namespace...\n" $CAMEL_NS
oc create ns $CAMEL_NS || oc project $CAMEL_NS
if [ $? -ne 0 ]; then
  printf "\n\n *** Error when creating %s namespace in OpenShift ***\n" $CAMEL_NS
  exit 1
fi
oc project $CAMEL_NS > /dev/null

mvn_out_file=`mktemp`

# https://quarkus.io/guides/deploying-to-openshift#build-and-deployment
printf "\nBuilding and installing Camel application in the %s namespace.\n Output from 'mvn' command will be in '%s' file...\n" $CAMEL_NS $mvn_out_file
./mvnw clean install -Dquarkus.openshift.deploy=true > "$mvn_out_file"

if [ $? -eq 0 ]; then
  printf "\nDeleting 'target' directory after successful deployment of Camel app in %s namespace...\n" "$CAMEL_NS"
  rm -rf target   # Delete the target directory created from previous command
  printf "\n\n *** Camel app is getting deployed. Please give it 2 mins before running any messages through ***\n\n"
else
  printf "\n\n *** Error during Came application generation and deployment to OpenShift ***\n"
  printf "  Please look at %s file for details...\n\n" $mvn_out_file
  exit 1
fi
