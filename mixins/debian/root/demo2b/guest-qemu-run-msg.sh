#!/bin/sh

#MACHINE="-M virt,memory-backend=foo.ram"
QEMU=qemu-system-aarch64
MACHINE="-M x-virtio-msg"
VMID=$1
shift 1

DEV_DOORBELL=0000:00:02.0
DEV_SYSMEM=0000:00:03.0

MEMFILE=/sys/bus/pci/devices/${DEV_SYSMEM}/resource2_wc

set -x
${QEMU} ${MACHINE} -m 4G             \
        -object memory-backend-file,id=mem,size=4G,mem-path=${MEMFILE},share=on \
        -serial mon:stdio -display none                         \
	-device virtio-msg-bus-ivshmem,dev=${DEV_DOORBELL},remote-vmid=${VMID},memdev=mem,mem-offset=0x40000000,reset-queues=true \
        -device virtio-net-device,mq=on,netdev=net0,iommu_platform=on           \
        -netdev user,id=net0                                                    \
        "$@"

exit 0
