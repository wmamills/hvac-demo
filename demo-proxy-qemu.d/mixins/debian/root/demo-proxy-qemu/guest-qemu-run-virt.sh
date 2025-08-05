#!/bin/sh

#MACHINE="-M virt,memory-backend=foo.ram"
QEMU=/opt/qemu-msg/bin/qemu-system-aarch64
MACHINE="-M virt"
KERNEL=${HOME}/linux-upstream-Image
ROOTFS=${HOME}/demo-proxy-qemu-kvm-rootfs.cpio.gz
R_VMID=$1
shift

DEV_DOORBELL=0000:00:01.0

set -x
${QEMU} ${MACHINE} -m 512M -cpu host -accel kvm                   \
        -serial mon:stdio -display none                             \
        -kernel ${KERNEL}                                       \
        -initrd ${ROOTFS}                                       \
        -append "console=ttyAMA0 autorun=./demo.sh"     \
        -device virtio-msg-proxy-driver-pci,virtio-id=0x1 \
        -device virtio-msg-bus-ivshmem,dev=${DEV_DOORBELL},iommu=linux-proc-pagemap,remote-vmid=${R_VMID} \
        "$@"

exit 0


