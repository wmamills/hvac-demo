#/bin/sh

MY_DIR=$(dirname $0)

set -e

. $MY_DIR/demo2b-common.sh

install_common
install_qemu_deps
vfio_setup

echo "Wait for other qemu to be ready"
wait_ready
sleep 5
echo; echo "OK"

$MY_DIR/guest-qemu-run-virt.sh 0x00

# stop for debug
#bash

