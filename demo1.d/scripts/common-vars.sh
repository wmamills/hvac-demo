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

QEMU_DIR=host/${HOST_ARCH}/qemu-i2c
QEMU=$IMAGES/$QEMU_DIR/bin/qemu-system-aarch64

XEN=target/aarch64/xen-upstream
KERNEL=target/aarch64/linux-upstream-Image
