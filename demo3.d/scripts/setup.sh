#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

# all zephyr apps fetch as part of the zephyr dir
$FETCH --image zephyr $KERNEL2 $QEMU_DIR
copy_debian_disk demo3

# ivshmem-server detaches itself, just run it
$IVSHMEM_SERVER -S shm.sock -p shm.pid -l 4M -n 16
