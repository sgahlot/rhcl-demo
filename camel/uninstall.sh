#!/bin/sh

printf "\nUninstalling kamel...\n"
oc project $KAMEL_NS
kamel uninstall

printf "\nDeleting %s namespace...\n" $KAMEL_NS
oc delete ns $KAMEL_NS
