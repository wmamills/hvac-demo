#!/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

#set -x

QEMU=$IMAGES/qemu-ivshmem-flat-install/bin/qemu-system-aarch64
ZEPHYR=$IMAGES/zephyr_qemu_an385_ivshmem.elf

IVFLAT_IRQ=x-irq-qompath='/machine/armv7m/nvic/unnamed-gpio-in[0]'
IVFLAT_SIZE=ivfshmem-maxsize=4194304

while true; do
	sleep 3600
done
exit

$QEMU \
	-cpu cortex-m3 -machine mps2-an385 \
	-nographic -net none \
	-chardev stdio,id=con,mux=on -serial chardev:con \
	-mon chardev=con,mode=readline \
	-chardev socket,path=shm.sock,id=ivsh \
	-device ivshmem-flat,$IVFLAT_IRQ,chardev=ivsh,$IVFLAT_SIZE \
	-kernel $ZEPHYR
