# to be sourced, not run

# if we are run by multi-qemu these should be set already
# if not set some defaults
: ${TEST_DIR:=$(cd $MY_DIR/.. ; pwd)}
: ${BASE_DIR:=$(cd $MY_DIR/../.. ; pwd)}}
: ${LOGS:=$BASE_DIR/logs}
: ${TMPDIR:=.}
: ${IMAGES:=$BASE_DIR/build}

FETCH=$BASE_DIR/scripts/maybe-fetch
HOST_ARCH=$(uname -m )

QEMU_DIR=host/${HOST_ARCH}/qemu-msg
QEMU=$IMAGES/$QEMU_DIR/bin/qemu-system-aarch64
IVSHMEM_SERVER=$IMAGES/$QEMU_DIR/bin/ivshmem-server

KERNEL=target/aarch64/linux-upstream-Image
UBOOT=target/aarch64/u-boot-el2.bin
XEN=target/aarch64/xen-virtio-msg
ROOTFS=disk/virtio_msg_rootfs.cpio.gz

DTB=$TEST_DIR/dts/xen.dtb

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

# use u-boot and choose which mode to boot at the u-boot prompt
QEMU_U_BOOT=(
-bios ${IMAGES}/${UBOOT}
-device loader,file=${IMAGES}/${XEN},force-raw=on,addr=0x42000000
-device loader,file=${IMAGES}/${KERNEL},addr=0x47000000
-device loader,file=${DTB},addr=0x44000000
-device loader,file=${IMAGES}/${ROOTFS},force-raw=on,addr=0x50000000
-device loader,file=${IMAGES}/${KERNEL},addr=0x60000000
-device loader,file=${IMAGES}/${ROOTFS},force-raw=on,addr=0x70000000
)

# use direct linux boot (where you can use kvm if you wish)
QEMU_KVM=(
-kernel "${IMAGES}/${KERNEL}"
-append "root=/dev/sda2 console=ttyAMA0 earlycon autorun=./demo2b/${NAME}-kvm.sh"
)

# use Xen and Dom0 boot
XBA="root=/dev/sda2 console=hvc0 earlyprintk=xen autorun=./demo2b/${NAME}-xen.sh"
QEMU_XEN=(
-kernel "${IMAGES}/${XEN}"
-append "dom0_mem=512M,max:512M dom0_max_vcpus=7 loglvl=all guest_loglvl=all"
-device "guest-loader,addr=0x49000000,kernel=${IMAGES}/${KERNEL},bootargs=${XBA}"
)
