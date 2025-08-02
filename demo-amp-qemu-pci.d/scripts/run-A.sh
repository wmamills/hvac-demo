#!/bin/bash

NAME=demo-amp-qemu-pci
SHORT_NAME=demo-driver

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

${QEMU} \
	-machine q35 \
	-cpu max \
	-m 1G -smp 2 \
	-serial mon:stdio \
	-nographic -display none \
	-device virtio-msg-amp-pci \
	-device virtio-net-device,netdev=n1,bus=/q35-pcihost/pcie.0/virtio-msg-amp-pci/vmsg.0/virtio-msg/virtio-msg-proxy-bus.0 \
	-netdev type=user,id=n1 \
	-kernel "${IMAGES}/${KERNEL1}" \
	-initrd "${BUILD}/${INITRD1}" \
	-append "rdinit=/sbin/init console=ttyS0,115200,8n1 acpi=debug autorun=./demo-amp-qemu-pci/demo.sh"
