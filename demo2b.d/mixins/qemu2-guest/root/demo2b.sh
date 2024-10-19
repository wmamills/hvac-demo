#/bin/sh

# error out on any non-zero return status
set -e

# this script is short, echo each step
set -x

ifconfig -a

# In xen domU, eth0 is the only nic and the one we want
ifconfig eth0 up

# The virtio-msg device model running in qemu1 is using qemu user mode
# networking, that uses a subnet of 10.0.2.* and qemu's built in server is
# at 10.0.2.2

# assign ourselves an address that is not reserved and not in the dhcp range
ifconfig eth0 inet 10.0.2.10

# ping the qemu built in dhcp/tftp server (on the foreign host)
ping -c 3 10.0.2.2

# won't get here if any of the above failed
echo "***** TEST PASSED, eth0 setup and ping worked"
