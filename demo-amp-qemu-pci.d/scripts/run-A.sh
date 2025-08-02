#!/bin/bash

NAME=demo-amp-qemu-pci
SHORT_NAME=demo-driver

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

${QEMU} \
	-machine virt,gic_version=3 \
	-machine virtualization=true \
	-cpu cortex-a57 -machine type=virt -m 1G -smp 2 \
	-nographic \
	-gdb tcp::2102,server,nowait \
	-device virtio-msg-amp-pci \
	-device virtio-net-device,netdev=net0,bus=/gpex-pcihost/pcie.0/virtio-msg-amp-pci/vmsg.0/virtio-msg/virtio-msg-proxy-bus.0 \
	-netdev type=user,id=net0,hostfwd=tcp::2224-:22,hostfwd=tcp::2225-10.0.2.16:22 \
	-kernel "${IMAGES}/${KERNEL1}" \
	-initrd "${BUILD}/${INITRD1}" \
	-append "root=$ROOT console=ttyAMA0 earlycon autorun=./demo-amp-qemu-pci/demo.sh"
