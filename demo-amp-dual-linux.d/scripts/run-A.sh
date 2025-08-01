#!/bin/bash

ARG1=${1:-DIRECT}; shift
ARG2=${1:-$ARG1}; shift

MODE=$ARG1
NAME=demo-amp-dual-linux-device
SHORT_NAME=demo-device

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

OPT_MODE_NAME="QEMU_$MODE[@]"

${QEMU} \
	"${QEMU_BASE[@]}" \
	"${!OPT_MODE_NAME}" \
	-machine memory-backend=vm0_mem \
	-gdb tcp::2101,server,nowait \
	-netdev type=user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::2223-10.0.2.16:22 \
	-device ivshmem-plain,memdev=vm1_mem \
	"$@"
