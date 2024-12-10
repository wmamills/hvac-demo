#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

rm -f ./queue-linux-user-d*
rm -f ./qemu-ram

${QEMU} \
     -M x-virtio-msg -m 2G -cpu cortex-a72 \
     -object memory-backend-file,id=mem,size=2G,mem-path=./qemu-ram,share=on \
     -machine memory-backend=mem \
     -chardev socket,id=chr0,path=linux-user.socket,server=on,wait=false \
     -serial mon:stdio -display none \
     -device virtio-msg-bus-linux-user,name=linux-user,chardev=chr0,memdev=mem,mem-offset=0x40000000 \
     -device virtio-net-device,netdev=net0,iommu_platform=on \
     -netdev user,id=net0 \
     -object filter-dump,id=f0,netdev=net0,file=$LOGS/net.pcap

rm -f ./queue-linux-user-d*
rm -f ./qemu-ram
