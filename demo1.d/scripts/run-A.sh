#!/bin/bash

# if we are run by multi-qemu these should be set already
# if not set some defaults
: ${TEST_DIR:=$(cd $MY_DIR/.. ; pwd)}
: ${BASE_DIR:=$(cd $MY_DIR/../.. ; pwd)}}
: ${LOGS:=$BASE_DIR/logs}
: ${TMPDIR:=.}
: ${IMAGES:=$BASE_DIR/build}

if [ ! -e ${IMAGES}/demo1-disk.qcow2 ]; then
	cp ${IMAGES}/disk.qcow2 ${IMAGES}/demo1-disk.qcow2
fi

BOOTARGS="root=/dev/sda2 console=hvc0 earlyprintk=xen autorun=./demo1/demo1.sh"

${IMAGES}/qemu-i2c-install/bin/qemu-system-aarch64 \
  -machine virt,virtualization=on -cpu cortex-a57 -serial mon:stdio \
  -device virtio-net-pci,netdev=net0 -netdev user,id=net0,hostfwd=tcp::8022-:22 \
  -drive file=${IMAGES}/demo1-disk.qcow2,id=hd0,if=none,format=qcow2 \
  -device virtio-scsi-pci -device scsi-hd,drive=hd0 \
  -display none -m 8192 -smp 8 -kernel ${IMAGES}/xen-upstream \
  -append "dom0_mem=5G,max:5G dom0_max_vcpus=7 loglvl=all guest_loglvl=all" \
  -device guest-loader,addr=0x49000000,kernel=${IMAGES}/linux-upstream-Image,bootargs="$BOOTARGS" \
  -device ds1338,address=0x20
