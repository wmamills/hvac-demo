#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

#set -x

$FETCH --image $QEMU_DIR $KERNEL $U_BOOT $XEN $ROOTFS

for NAME in demo2b-A demo2b-B; do
	if [ ! -e ${BUILD}/${NAME}-disk.qcow2 ]; then
		echo "make a copy of the debian disk image for $NAME"
		cp ${BUILD}/disk.qcow2 ${BUILD}/${NAME}-disk.qcow2
	fi
done

# make the dtb
(cd $TEST_DIR/dts; make)

# ivshmem-server detaches itself, just run it
$IVSHMEM_SERVER -S shm.sock -p shm.pid -l 1M -n 1
