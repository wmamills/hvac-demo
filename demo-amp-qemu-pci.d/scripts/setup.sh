#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

$FETCH --image $KERNEL1 $QEMU_DIR
$CHK_BUILD $INITRD1

echo "This is a setup test"; sleep 3