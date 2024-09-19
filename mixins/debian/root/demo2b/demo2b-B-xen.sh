#/bin/sh

MY_DIR=$(dirname $0)

set -e

. $MY_DIR/demo2b-common.sh

install_common
install_qemu_deps
install_xen xen-upstream qemu-xen
vfio_setup
xen_startup

# should only show Domain-0
xl list

echo "Wait for other qemu to be ready"
wait_ready
sleep 5
echo; echo "OK"

echo "THIS IS NOT WORKING YET; hit enter to go on anyway"; read

# now start the quest
xl create -c $MY_DIR/guest-virtio-msg.cfg

# stop the poweroff until it is working
bash

