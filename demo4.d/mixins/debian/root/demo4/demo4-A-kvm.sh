#/bin/bash

MY_DIR=$(dirname $0)

set -e

. $MY_DIR/demo4-common.sh

mark_not_ready
install_common
install_qemu_deps

# we need xen because qemu needs the library even though it won't use it
install_xen xen-virtio-msg qemu-msg
vfio_setup

mark_ready
$MY_DIR/guest-qemu-run-msg.sh 0x01

# stop for debug
#bash
