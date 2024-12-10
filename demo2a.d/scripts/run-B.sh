#/bin/bash

# include the common variable settings
ME_ABS=$(readlink -f $0)
MY_DIR=$(dirname $ME_ABS)
. $MY_DIR/common-vars.sh

echo "wait for device model to start"
sleep 2

${QEMU} \
     -M virt -m 2G -cpu cortex-a72 \
     -object memory-backend-file,id=mem,size=2G,mem-path=./qemu-ram,share=on \
     -machine memory-backend=mem \
     -serial mon:stdio -display none \
     -kernel ${IMAGES}/${KERNEL} \
     -initrd ${BUILD}/${ROOTFS} \
     -append "console=ttyAMA0 autorun=./demo2a.sh" \
     -chardev socket,id=chr0,path=linux-user.socket \
     -device virtio-msg-proxy-driver-pci,virtio-id=0x1 \
     -device virtio-msg-bus-linux-user,name=linux-user,chardev=chr0
