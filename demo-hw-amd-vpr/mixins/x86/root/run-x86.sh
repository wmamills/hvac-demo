#!/bin/sh

vif=$1

KVER=$(uname -r)

set -x
insmod /lib/modules/$KVER/kernel/drivers/virtio/virtio_msg.ko
insmod /lib/modules/$KVER/kernel/drivers/virtio/virtio_msg_amp.ko
insmod /lib/modules/$KVER/kernel/drivers/virtio/virtio_msg_sapphire.ko

# sleep longer than arm side
sleep 5

if [ -z ${vif} ]; then
    vif="eth3"
    for eth_if in eth2 eth3; do
        DRIVER=$(readlink /sys/class/net/${eth_if}/device/driver)
        case $DRIVER in
        */virtio_net)
            vif=${eth_if}
            break
            ;;
        esac
    done
fi


ifconfig ${vif} up
ifconfig ${vif} inet 192.168.160.1
ping -c 3 192.168.160.2
