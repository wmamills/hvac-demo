#!/bin/bash

# normally the demo exits via qemu2 exiting via powerdown (or host shell exit)
# when either of those happen, the qemu1 pane is killed
# this does not give run-A.sh to cleanup the memory files so we do it here
rm -f ./queue-linux-user-d*
rm -f ./qemu-ram

tcpdump -r $LOGS/net.pcap
grep "^\*\*\*\*\* TEST" $LOGS/driver-side-log.txt
