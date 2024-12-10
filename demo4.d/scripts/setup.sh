#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

#set -x

$FETCH --image $KERNEL1 $KERNEL2 $QEMU_DIR $XEN
#$FETCH --image $UBOOT

# was demo4-A demo4-B
for NAME in demo4-A; do
	if [ ! -e $BUILD/${NAME}-disk.qcow2 ]; then
		echo "make a copy of the debian disk image for $NAME"
		cp $BUILD/disk.qcow2 $BUILD/${NAME}-disk.qcow2
	fi
done

# ivshmem-server detaches itself, just run it
$IVSHMEM_SERVER -S shm.sock -p shm.pid -l 4M -n 2
