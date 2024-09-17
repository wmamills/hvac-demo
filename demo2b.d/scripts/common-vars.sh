# to be sourced, not run

# if we are run by multi-qemu these should be set
# if not set some defaults
: ${TEST_DIR:=$(cd $MY_DIR/.. ; pwd)}
: ${BASE_DIR:=$(cd $MY_DIR/../.. ; pwd)}}
: ${LOGS:=$BASE_DIR/logs}
: ${TMPDIR:=.}
: ${IMAGES:=$BASE_DIR/build}

QEMU=$IMAGES/qemu-msg-install/bin/qemu-system-aarch64
XEN=$IMAGES/xen-virtio-msg
KERNEL=$IMAGES/Image
UBOOT=$IMAGES/u-boot-el2.bin
DTB=$TEST_DIR/dts/xen.dtb
ROOTFS=$IMAGES/disk/virtio_msg_rootfs.cpio.gz

IVSHMEM_SERVER=$IMAGES/qemu-msg/contrib/ivshmem-server/ivshmem-server

QEMU_BASE="
-machine virt,gic_version=3,iommu=smmuv3
-machine virtualization=true
-object memory-backend-file,id=vm0_mem,size=1G,mem-path=./qemu-xen-vm0-ram,share=on
-object memory-backend-file,id=vm1_mem,size=1G,mem-path=./qemu-xen-vm1-ram,share=on
-cpu cortex-a57 -machine type=virt -m 1G -smp 2
-drive file=${IMAGES}/${NAME}-disk.qcow2,id=hd0,if=none,format=qcow2 \
-device virtio-scsi-pci -device scsi-hd,drive=hd0 \
-bios ${UBOOT}
-device loader,file=${XEN},force-raw=on,addr=0x42000000
-device loader,file=${KERNEL},addr=0x47000000
-device loader,file=${DTB},addr=0x44000000
-device loader,file=${ROOTFS},force-raw=on,addr=0x50000000
-device loader,file=${KERNEL},addr=0x60000000
-device loader,file=${ROOTFS},force-raw=on,addr=0x70000000
-nographic -no-reboot
-device virtio-net-pci,netdev=net0,romfile=
-device ivshmem-doorbell,vectors=2,chardev=ivsh
-chardev socket,path=shm.sock,id=ivsh"
