#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

#set -x

for NAME in demo3; do
	if [ ! -e $IMAGES/${NAME}-disk.qcow2 ]; then
		echo "make a copy of the debian disk image for $NAME"
		cp $IMAGES/disk.qcow2 $IMAGES/${NAME}-disk.qcow2
	fi
done

# ivshmem-server detaches itself, just run it
$IVSHMEM_SERVER -S shm.sock -p shm.pid -l 1M -n 1
