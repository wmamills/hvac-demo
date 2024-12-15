#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

$FETCH --image $QEMU_DIR $XEN $KERNEL
copy_debian_disk demo1
