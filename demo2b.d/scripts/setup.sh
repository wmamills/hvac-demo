#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

$FETCH --image $QEMU_DIR $KERNEL $U_BOOT $XEN $ROOTFS
copy_debian_disk demo2b-A demo2b-B

# make the dtb, only used for u-boot mode
(cd $TEST_DIR/dts; make)

# ivshmem-server detaches itself, just run it
$IVSHMEM_SERVER -S shm.sock -p shm.pid -l 1M -n 1
