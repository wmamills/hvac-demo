#!/bin/bash

ARG1=${1:-KVM}; shift
ARG2=${1:-$ARG1}; shift

MODE=$ARG2
NAME=demo2b-B

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

echo "Waiting for qemu1 to start first (so it gets VMID 0)"
sleep 5

if [ "$MODE" == "U_BOOT" ]; then
    echo booti 0x42000000 - 0x44000000
    echo booti 0x47000000 - 0x44000000
fi

OPT_MODE_NAME="QEMU_$MODE[@]"

${QEMU} \
	"${QEMU_BASE[@]}" \
	"${!OPT_MODE_NAME}" \
	-machine memory-backend=vm1_mem \
	-netdev type=user,id=net0,hostfwd=tcp::2224-:22,hostfwd=tcp::2225-10.0.2.16:22 \
	-device ivshmem-plain,memdev=vm0_mem \
	"$@"
