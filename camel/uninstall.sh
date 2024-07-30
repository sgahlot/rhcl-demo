#!/bin/sh

printf "\nUninstalling kamel...\n"
oc project $kamelNS
kamel uninstall

printf "\nDeleting %s namespace...\n" $kamelNS
oc delete ns $kamelNS
