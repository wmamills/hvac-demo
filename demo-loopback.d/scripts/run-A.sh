#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

${QEMU} \
  -machine virt,virtualization=on,gic-version=3 -cpu cortex-a57 -serial mon:stdio \
  -device virtio-net-pci,netdev=net0 -netdev user,id=net0,hostfwd=tcp::8022-:22 \
  -drive file=${BUILD}/demo-loopback-disk.qcow2,id=hd0,if=none,format=qcow2 \
  -device virtio-scsi-pci -device scsi-hd,drive=hd0 \
  -display none -m 1280 -smp 3 \
  -kernel ${IMAGES}/${KERNEL} \
  -append "earlycon root=/dev/sda2 autorun=./demo-loopback/demo.sh" \
  -device ds1338,address=0x20
