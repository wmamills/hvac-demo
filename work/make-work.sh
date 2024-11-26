#!/bin/bash

ME=$(readlink -f $0)
MY_DIR=$(dirname $ME)
DEMO_BASE=$(dirname $MY_DIR)

mksymdir() {
	DIRPATH=$1; shift
	mkdir -p $BASE/$DIRPATH

	for i in $@; do
		echo ln -fsT $LINK_BASE/$DIRPATH/$i $BASE/$DIRPATH/$i
		ln -fsT $LINK_BASE/$DIRPATH/$i $BASE/$DIRPATH/$i
	done
}

cd $DEMO_BASE/work

LINK_BASE=$DEMO_BASE/../linux-virtio-msg
BASE=linux-virtio-msg
mksymdir drivers uio virtio
mksymdir include linux uapi
mksymdir arch/arm64 configs

LINK_BASE=$DEMO_BASE/../qemu-virtio-msg
BASE=qemu-virtio-msg
mksymdir hw virtio vfio i2c
mksymdir include/hw virtio vfio i2c
mksymdir include qemu
