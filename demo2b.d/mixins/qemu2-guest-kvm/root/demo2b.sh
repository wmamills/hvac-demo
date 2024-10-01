#/bin/sh

# error out on any non-zero return status
set -e

# this script is short, echo each step
set -x

ifconfig -a

# eth0 is the default one setup by qemu virt machine,
# we want to test eth1 which is the virtio-msg one
ifconfig eth1 up

# The virtio-msg device model running in qemu1 is using qemu user mode
# networking, that uses a subnet of 10.0.2.* and qemu's built in server is
# at 10.0.2.2

# assign ourselves an address that is not reserved and not in the dhcp range
ifconfig eth1 inet 10.0.2.10

# ping the qemu built in dhcp/tftp server (on the foreign host)
ping -c 3 10.0.2.2

# won't get here if any of the above failed
echo "***** TEST PASSED, eth1 setup and ping worked"
