#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

$FETCH --image $KERNEL1 $KERNEL2 $QEMU_DIR
$CHK_BUILD $INITRD2
copy_debian_disk demo4-A

# ivshmem-server detaches itself, just run it
$IVSHMEM_SERVER -S shm.sock -p shm.pid -l 4M -n 2
