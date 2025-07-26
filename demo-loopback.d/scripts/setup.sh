#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

$FETCH --image $QEMU_DIR $KERNEL
copy_debian_disk demo-loopback

# Create DTB to use
# Get the dtb for the configuration we are going to use
${QEMU} \
	"${QEMU_BASE[@]}" \
	-machine dumpdtb=$MY_DIR/qemu.dtb

# get the source for debug
dtc -I dtb -O dts -o $MY_DIR/qemu.dts $MY_DIR/qemu.dtb

# poorman's overlay
# adapted from https://docs.u-boot.org/en/latest/develop/devicetree/dt_qemu.html
cat  $MY_DIR/qemu.dts $MY_DIR/reserved-memory.dts >$MY_DIR/merged.dts
dtc -o $MY_DIR/merged.dtb $MY_DIR/merged.dts
