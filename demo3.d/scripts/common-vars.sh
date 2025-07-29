# to be sourced, not run

# include the demo common settings and functions
. $MY_DIR/../../scripts/demo-common.sh

QEMU_DIR=host/${HOST_ARCH}/qemu-ivshmem-flat
QEMU=$IMAGES/$QEMU_DIR/bin/qemu-system-aarch64
IVSHMEM_SERVER=$IMAGES/$QEMU_DIR/bin/ivshmem-server

ZEPHYR1="zephyr/zephyr-mps2-m3-uio.elf"

KERNEL2=target/aarch64/linux-virtio-msg-amp-v1-Image
DISK2=${NAME}-disk.qcow2
