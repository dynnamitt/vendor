#!/bin/bash

DEFAULT_SRV=packages_prod
DEFAULT_DIRDEST=.
SRC=work/maven_vendor_all.tar.gz

if [ ! -f $SRC ]
then
  echo finner ikke $SRC ! .. bygg den først
fi

echo
echo Klar for upload av $SRC
echo

read -p "Hva er server navn (packages_prod) :" SRV_INP
read -p "Hva mappe destinasjon (.) :" DIRDEST_INP

SRV=${SRV_INP:-${DEFAULT_SRV}}
DIRDEST=${DIRDEST_INP:-${DEFAULT_DIRDEST}}

scp $SRC $SRV:$DIRDEST 
