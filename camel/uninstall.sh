#!/bin/sh

printf "\nDeleting %s namespace...\n" $CAMEL_NS
oc delete ns $CAMEL_NS
