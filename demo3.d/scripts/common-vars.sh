# to be sourced, not run

# if we are run by multi-qemu these should be set already
# if not set some defaults
: ${TEST_DIR:=$(cd $MY_DIR/.. ; pwd)}
: ${BASE_DIR:=$(cd $MY_DIR/../.. ; pwd)}}
: ${LOGS:=$BASE_DIR/logs}
: ${TMPDIR:=.}
: ${IMAGES:=$BASE_DIR/images}
: ${BUILD:=$BASE_DIR/build}

FETCH=$BASE_DIR/scripts/maybe-fetch
HOST_ARCH=$(uname -m )

QEMU_DIR=host/${HOST_ARCH}/qemu-ivshmem-flat
QEMU=$IMAGES/$QEMU_DIR/bin/qemu-system-aarch64
IVSHMEM_SERVER=$IMAGES/$QEMU_DIR/bin/ivshmem-server

ZEPHYR1="zephyr/zephyr-mps2-m3-uio.elf"

KERNEL2=target/aarch64/linux-virtio-msg-Image
DISK2=${NAME}-disk.qcow2
