#!/bin/sh

vif=$1

if [ -z ${vif} ]; then
	vif="eth3"
fi

set -x
insmod /usr/share/virtio-msg-demo/virtio_msg_amp.ko
insmod /usr/share/virtio-msg-demo/virtio_msg_sapphire.ko

brctl addbr br0
brctl addif br0 eth1
brctl addif br0 ${vif}
ip link set up dev eth1
ip link set up dev ${vif}

echo "iface br0 inet dhcp" >>/etc/network/interfaces
ifup br0
