#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

# normally the demo exits via qemu2 exiting via powerdown (or host shell exit)
# when either of those happen, the qemu1 pane is killed
# this does not give run-A.sh to cleanup the memory files so we do it here
rm -f ./queue-linux-user-d*

common_cleanup
print_results driver-side
