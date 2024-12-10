#!/bin/bash

NAME=demo4

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

echo "Waiting for device side to start first (so it gets VMID 0)"
sleep 2

#set -x

INITRD=$BUILD/demo4-rootfs.cpio.gz

#DISK=${IMAGES}/${NAME}-B-disk.qcow2
#ROOT="/dev/vda2"

${QEMU} \
	-machine virt,gic_version=3 \
	-machine virtualization=true \
	-cpu cortex-a57 -machine type=virt -m 1G -smp 2 \
	-object memory-backend-file,id=vm1_mem,size=1G,mem-path=./qemu-xen-vm1-ram,share=on \
	-machine memory-backend=vm1_mem \
	-nographic \
	-gdb tcp::2102,server,nowait \
	-device virtio-net-pci,netdev=net0,romfile= \
	-device ivshmem-doorbell,chardev=ivsh \
	-chardev socket,path=shm.sock,id=ivsh \
	-netdev type=user,id=net0,hostfwd=tcp::2224-:22,hostfwd=tcp::2225-10.0.2.16:22 \
	-kernel "${IMAGES}/${KERNEL2}" \
	-initrd "${INITRD}" \
	-append "root=$ROOT console=ttyAMA0 earlycon autorun=./$NAME/${NAME}.sh"

	#-drive file=$DISK,id=hd0,if=none,format=qcow2 \
	#-device virtio-blk-pci,drive=hd0 \
