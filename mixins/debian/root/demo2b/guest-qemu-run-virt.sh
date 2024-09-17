#!/bin/sh

#MACHINE="-M virt,memory-backend=foo.ram"
QEMU=qemu-system-aarch64
MACHINE="-M virt"
KERNEL=${HOME}/Image
ROOTFS=${HOME}/core-image-minimal-qemuarm64.rootfs.cpio.gz

DEV_DOORBELL=0000:00:02.0

set -x
${QEMU} ${MACHINE} -m 2G -cpu host -accel kvm                   \
        -serial mon:stdio -display none                             \
        -kernel ${KERNEL}                                       \
        -initrd ${ROOTFS}                                       \
        -append "rdinit=/sbin/init console=ttyAMA0 lpj=100"     \
        -device virtio-msg-proxy-driver-pci,virtio-id=0x1 \
        -device virtio-msg-bus-ivshmem,dev=${DEV_DOORBELL},iommu=linux-proc-pagemap,remote-vmid=0x1C   \
        "$@"

exit 0


