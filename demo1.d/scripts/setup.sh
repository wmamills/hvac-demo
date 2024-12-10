#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

#set -x

$FETCH --image $QEMU_DIR $XEN $KERNEL

if [ ! -e ${BUILD}/demo1-disk.qcow2 ]; then
	cp ${BUILD}/disk.qcow2 ${BUILD}/demo1-disk.qcow2
fi

