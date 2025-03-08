#!/bin/sh

set -x

qemu-system-aarch64 -M x-virtio-msg -m 2G \
        -serial null -display none \
	-daemonize \
        -device virtio-msg-bus-vek280-hexcam,dev=/dev/uio0,spsc-base=0xa210000 \
        -device virtio-net-device,mq=on,netdev=net0,iommu_platform=on \
        -netdev tap,id=net0,ifname=tap0,script=no,downscript=no

# Wait for bridge to come up
sleep 3

# Bring up xenbr0 together with tap0
ifup xenbr0
