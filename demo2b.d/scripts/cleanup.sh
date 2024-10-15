#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

# cleam up the memory files
rm -f ./qemu-xen-vm?-ram

kill $(cat shm.pid)
rm -f shm.pid
rm -f shm.sock

if [ -r $LOGS/net.pcap ]; then
    tcpdump -r $LOGS/net.pcap
fi
grep "^\*\*\*\*\* TEST" $LOGS/device-side-log.txt
grep "^\*\*\*\*\* TEST" $LOGS/driver-side-log.txt
