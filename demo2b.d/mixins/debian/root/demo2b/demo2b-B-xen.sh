#/bin/bash

MY_DIR=$(dirname $0)

set -e

. $MY_DIR/demo2b-common.sh

install_common
install_qemu_deps
install_xen xen-virtio-msg qemu-msg
vfio_setup
xen_startup
dummy_disk

# should only show Domain-0
xl list

wait_ready_seq

echo "THIS IS NOT WORKING YET; hit enter to go on anyway"; read

# now start the quest
xl create -c $MY_DIR/guest-virtio-msg.cfg

echo "start subshell to stop the poweroff until it is working"
bash
