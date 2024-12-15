# to be sourced, not run

# include the demo common settings and functions
. $MY_DIR/../../scripts/demo-common.sh

QEMU_DIR=host/${HOST_ARCH}/qemu-msg
QEMU=$IMAGES/$QEMU_DIR/bin/qemu-system-aarch64

KERNEL=target/aarch64/linux-upstream-Image
ROOTFS=demo2a-rootfs.cpio.gz

DISK_TARGETS[$ROOTFS]=disk_demo2a
