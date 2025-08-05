# to be sourced, not run

# include the demo common settings and functions
. $MY_DIR/../../scripts/demo-common.sh

QEMU_DIR=host/${HOST_ARCH}/qemu-i2c
QEMU=$IMAGES/$QEMU_DIR/bin/qemu-system-aarch64

XEN=target/aarch64/xen-ffa
KERNEL=target/aarch64/linux-virtio-msg-Image
