#/bin/bash

# assume we are being run from the base directory if not defined
: ${BASE_DIR:=.}
: ${LOGS:=.}
: ${TMPDIR:=.}

echo "wait for device model to start"
sleep 2

$BASE_DIR/build/qemu-msg-install/bin/qemu-system-aarch64 \
     -M virt -m 2G -cpu cortex-a72 \
     -object memory-backend-file,id=mem,size=2G,mem-path=./qemu-ram,share=on \
     -machine memory-backend=mem \
     -serial mon:stdio -display none \
     -kernel $BASE_DIR/build/Image \
     -initrd $BASE_DIR/build/disk/virtio_msg_rootfs.cpio.gz \
     -append "console=ttyAMA0" \
     -chardev socket,id=chr0,path=linux-user.socket \
     -device virtio-msg-proxy-driver-pci,virtio-id=0x1 \
     -device virtio-msg-bus-linux-user,name=linux-user,chardev=chr0
