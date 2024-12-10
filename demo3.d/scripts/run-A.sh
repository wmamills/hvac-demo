#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

#set -x

IVFLAT_IRQ=x-irq-qompath='/machine/armv7m/nvic/unnamed-gpio-in[0]'
IVFLAT_SIZE="ivshmem-maxsize=4194304"
IVFLAT_ADDR="x-bus-address-iomem=0x400ff000,x-bus-address-shmem=0x40100000"

${QEMU} \
	-cpu cortex-m3 -machine mps2-an385 \
	-nographic -net none \
	-chardev stdio,id=con,mux=on -serial chardev:con \
	-mon chardev=con,mode=readline \
	-chardev socket,path=shm.sock,id=ivsh \
	-device ivshmem-flat,$IVFLAT_IRQ,chardev=ivsh,$IVFLAT_ADDR \
	-kernel ${IMAGES}/${ZEPHYR1}
