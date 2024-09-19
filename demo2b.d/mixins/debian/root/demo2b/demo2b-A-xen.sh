#/bin/bash

MY_DIR=$(dirname $0)

set -e

. $MY_DIR/demo2b-common.sh

mark_not_ready
install_common
install_qemu_deps
install_xen xen-virtio-msg qemu-msg
vfio_setup
xen_startup

# should only show Domain-0
xl list

mark_ready
$MY_DIR/guest-qemu-run-msg.sh 0x01

# stop for debug
#bash

