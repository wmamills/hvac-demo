# to be sourced, not run

# include the demo common settings and functions
. $MY_DIR/../../scripts/demo-common.sh

QEMU_DIR=host/${HOST_ARCH}/qemu-msg
QEMU=$IMAGES/$QEMU_DIR/bin/qemu-system-aarch64
IVSHMEM_SERVER=$IMAGES/$QEMU_DIR/bin/ivshmem-server

KERNEL1=target/aarch64/linux-upstream-Image
DISK1=demo4-A
KERNEL2=target/aarch64/linux-virtio-msg-amp-v1-Image
INITRD2=demo4-rootfs.cpio.gz

DISK_TARGETS[$INITRD2]=disk_demo4

QEMU_BASE=(
-machine virt,gic_version=3,iommu=smmuv3
-machine virtualization=true
-object memory-backend-file,id=vm0_mem,size=1G,mem-path=./qemu-xen-vm0-ram,share=on
-object memory-backend-file,id=vm1_mem,size=1G,mem-path=./qemu-xen-vm1-ram,share=on
-cpu cortex-a57 -machine type=virt -m 1G -smp 2
-drive file=${BUILD}/${NAME}-disk.qcow2,id=hd0,if=none,format=qcow2 \
-device virtio-scsi-pci -device scsi-hd,drive=hd0 \
-nographic -no-reboot
-device virtio-net-pci,netdev=net0,romfile=
-device ivshmem-doorbell,vectors=2,chardev=ivsh
-chardev socket,path=shm.sock,id=ivsh
)

# use direct linux boot (where you can use kvm if you wish)
QEMU_KVM=(
-kernel "${IMAGES}/${KERNEL1}"
-append "root=/dev/sda2 console=ttyAMA0 earlycon autorun=./demo4/${NAME}-kvm.sh"
)
