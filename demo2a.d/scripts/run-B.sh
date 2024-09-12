#/bin/bash

./build/qemu-msg-install/bin/qemu-system-aarch64 \
     -M virt -m 2G -cpu cortex-a72 \
     -object memory-backend-file,id=mem,size=2G,mem-path=./qemu-ram,share=on \
     -machine memory-backend=mem \
     -serial mon:stdio -display none \
     -kernel ./build/Image \
     -initrd ./build/disk/virtio_msg_rootfs.cpio.gz \
     -append "console=ttyAMA0" \
     -chardev socket,id=chr0,path=linux-user.socket \
     -device virtio-msg-proxy-driver-pci,virtio-id=0x1 \
     -device virtio-msg-bus-linux-user,name=linux-user,chardev=chr0

#     -object memory-backend-file,id=mem,size=2G,mem-path=/dev/shm/qemu-ram,share=on \
#     -machine memory-backend=mem \


