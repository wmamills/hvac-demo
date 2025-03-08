#!/bin/sh
#
# Derived from autostart.sh
#

# Check the existance of the base address before passing the remaining
# arguments to devmem
# Usage: devmem_checkfirst BASEADDRESS [remaining args to devmem]
# eg: devmem_checkfirst 0x20110000000 0x20110000008 32 0x077f0280

devmem_checkfirst () {
        shift && devmem2 ${@}
	return 0
}

write_qdma_translation_regs() {
    echo "Setting QDMA bridge address translation"
    devmem2 0xfcea2460 w 0x0
    devmem2 0xfcea2464 w 0x0
    devmem2 0xfcea2468 w 0x0
    devmem2 0xfcea246C w 0x0
    devmem2 0xfcea2470 w 0xC2000000
    devmem2 0xfcea2474 w 0x0
}

dump_qdma_translation_regs() {
    devmem2 0xfcea2460 w
    devmem2 0xfcea2464 w
    devmem2 0xfcea2468 w
    devmem2 0xfcea246C w
    devmem2 0xfcea2470 w
    devmem2 0xfcea2474 w
}

monitor_flr() {
    FLR_GPIO_ADDR="0x20100010000"
    FLR_GPIO_ASSERTED="0x00000001"
#    FLR_GPIO_ADDR="0xfcea2470"
#    FLR_GPIO_ASSERTED="0x00000000"


    echo "Monitoring for FLR..."
    while true; do
        v=$(devmem_checkfirst ${FLR_GPIO_ADDR} ${FLR_GPIO_ADDR} w | cut -f 7 -s -d\  )
	sleep 1
	v=$(echo -n $v)
	echo -n $v | hexdump -C
	echo -n $FLR_GPIO_ASSERTED | hexdump -C
        if [ "X${v}" == "X${FLR_GPIO_ASSERTED}" ]; then
            echo "FLR asserted... current state of QDMA BDF registers:"
            dump_qdma_translation_regs
            echo "Re-writing BDF registers... the state is now:"
            write_qdma_translation_regs
            devmem_checkfirst ${FLR_GPIO_ADDR} ${FLR_GPIO_ADDR} w 0x1
            devmem_checkfirst ${FLR_GPIO_ADDR} ${FLR_GPIO_ADDR} w 0x0
            sleep 1
            dump_qdma_translation_regs
	else
	    echo "Not triggered"
        fi
    done
}

write_qdma_translation_regs

monitor_flr &
