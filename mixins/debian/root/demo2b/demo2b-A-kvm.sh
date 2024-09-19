#/bin/sh

MY_DIR=$(dirname $0)

set -e

. $MY_DIR/demo2b-common.sh

mark_not_ready
install_common
install_qemu_deps
vfio_setup

mark_ready
$MY_DIR/guest-qemu-run-msg.sh 0x01

# stop for debug
#bash
