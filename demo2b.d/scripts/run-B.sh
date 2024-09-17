#!/bin/bash

ARG1=${1:-KVM}; shift
ARG2=${1:-$ARG1}; shift

MODE=$ARG2
NAME=demo2b-B

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

if [ ! -e $IMAGES/${NAME}-disk.qcow2 ]; then
	echo "make a copy of the debian disk image for $NAME"
	cp $IMAGES/disk.qcow2 $IMAGES/${NAME}-disk.qcow2
fi

if [ "$MODE" == "U_BOOT" ]; then
    echo booti 0x42000000 - 0x44000000
    echo booti 0x47000000 - 0x44000000
fi

#set -x
OPT_MODE_NAME="QEMU_$MODE[@]"

${QEMU} \
	"${QEMU_BASE[@]}" \
	"${!OPT_MODE_NAME}" \
	-machine memory-backend=vm1_mem \
	-netdev type=user,id=net0,hostfwd=tcp::2224-:22,hostfwd=tcp::2225-10.0.2.16:22 \
	-device ivshmem-plain,memdev=vm0_mem \
	"$@"

exit 0

#	-device ivshmem-doorbell,memdev=hostmem \
#	-object memory-backend-file,size=1M,share=on,mem-path=/dev/shm/ivshmem,id=hostmem \

#	-device virtio-net-device,netdev=net0 \
#	-device virtio-net-pci,netdev=net0,romfile="" \
#	-device loader,file=${ROOTFS},addr=0x50000000 \
#	-device loader,file=${KERNEL},addr=0x60000000 \
#	-device loader,file=${ROOTFS},addr=0x70000000 \

# Coverage
# -d nochain -etrace elog -etrace-flags exec -accel tcg,thread=single

#	-bios ${UBOOT} \
#	-device loader,file=${XEN},force-raw=on,addr=0x42000000 \
#	-device loader,file=${KERNEL},addr=0x47000000 \
#	-device loader,file=${DTB},addr=0x44000000 \

#	-kernel ${KERNEL} \
#	-initrd ${ROOTFS} \
#	-append "rdinit=/sbin/init console=ttyAMA0,115200n8 earlyprintk=serial,ttyAMA0" \

#	-d int,guest_errors,exec -D log \
#
