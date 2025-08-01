#!/bin/bash

ARG1=${1:-KVM}; shift
ARG2=${1:-$ARG1}; shift

MODE=$ARG1
NAME=demo-qemu-proxy-A
SHORT_NAME=demo-A

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

if [ "$MODE" == "U_BOOT" ]; then
    echo booti 0x42000000 - 0x44000000
    echo booti 0x47000000 - 0x44000000
fi

OPT_MODE_NAME="QEMU_$MODE[@]"

${QEMU} \
	"${QEMU_BASE[@]}" \
	"${!OPT_MODE_NAME}" \
	-machine memory-backend=vm0_mem \
	-netdev type=user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::2223-10.0.2.16:22 \
	-device ivshmem-plain,memdev=vm1_mem \
	"$@"
