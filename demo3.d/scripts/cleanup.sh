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
grep "^\*\*\*\*\* TEST" $LOGS/cortex-m-log.txt
grep "^\*\*\*\*\* TEST" $LOGS/cortex-a-log.txt

# startup debug support
#echo "**** QEMU1 logs"
#cat $LOGS/qemu1-log.txt
#echo "**** QEMU2 logs"
#cat $LOGS/qemu2-log.txt
#echo ; echo "**** end QEMU logs"
