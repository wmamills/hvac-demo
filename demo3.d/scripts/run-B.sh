#!/bin/bash

NAME=demo3

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

echo "Waiting for qemu1 to start first (so it gets VMID 0)"
sleep 5

#set -x

QEMU=$IMAGES/qemu-ivshmem-flat-install/bin/qemu-system-aarch64
KERNEL=$IMAGES/linux-ivshmem-uio-Image
#DISK=${IMAGES}/${NAME}-disk.qcow2
DISK=$IMAGES/../demo3.d/rootfs.qcow2

${QEMU} \
	-machine virt,gic_version=3,iommu=smmuv3 \
	-machine virtualization=true \
	-cpu cortex-a57 -machine type=virt -m 1G -smp 2
	-drive file=$DISK,id=hd0,if=none,format=qcow2 \
	-device virtio-scsi-pci -device scsi-hd,drive=hd0 \
	-nographic -no-reboot
	-device virtio-net-pci,netdev=net0,romfile=
	-device ivshmem-doorbell,vectors=2,chardev=ivsh
	-chardev socket,path=shm.sock,id=ivsh
	-netdev type=user,id=net0,hostfwd=tcp::2224-:22,hostfwd=tcp::2225-10.0.2.16:22 \
	-kernel "${KERNEL}"
	-append "root=/dev/sda2 console=ttyAMA0 earlycon autorun=./$NAME/${NAME}.sh"
