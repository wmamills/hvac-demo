#!/bin/sh

QEMU=${HOME}/src/c/qemu/build-qemu/qemu-system-aarch64
#QEMU=${HOME}/xilinx/build-qemu/qemu-system-aarch64
XEN=hyp/xen/xen/xen
#XEN=yocto/yoxen/build/tmp/deploy/images/qemuarm64/xen-qemuarm64
#KERNEL=yocto/yoxen/build/tmp/deploy/images/qemuarm64/Image
KERNEL=/home/edgar/src/c/linux/linux/arch/arm64/boot/Image
UBOOT=u-boot/u-boot.bin
DTB=dts/xen.dtb
ROOTFS=yocto/yoxen/build/tmp/deploy/images/qemuarm64/core-image-minimal-qemuarm64.rootfs.cpio.gz

echo booti 0x42000000 - 0x44000000
echo booti 0x47000000 - 0x44000000

set -x

${QEMU} -machine virt,gic_version=3,iommu=smmuv3 \
	-machine virtualization=true \
	-object memory-backend-file,id=vm0_mem,size=4G,mem-path=/dev/shm/qemu-xen-vm0-ram,share=on \
	-object memory-backend-file,id=vm1_mem,size=4G,mem-path=/dev/shm/qemu-xen-vm1-ram,share=on \
	-machine memory-backend=vm1_mem \
	-cpu cortex-a57 -machine type=virt -m 4G -smp 2 \
	-bios ${UBOOT} \
	-device loader,file=${XEN},force-raw=on,addr=0x42000000 \
	-device loader,file=${KERNEL},addr=0x47000000 \
	-device loader,file=${DTB},addr=0x44000000 \
	-device loader,file=${ROOTFS},force-raw=on,addr=0x50000000 \
	-device loader,file=${KERNEL},addr=0x60000000 \
	-device loader,file=${ROOTFS},force-raw=on,addr=0x70000000 \
	-nographic -no-reboot \
	-device virtio-net-pci,netdev=net0,romfile="" \
	-netdev type=user,id=net0,hostfwd=tcp::2224-:22,hostfwd=tcp::2225-10.0.2.16:22 \
	-device ivshmem-doorbell,vectors=2,chardev=ivsh \
	-chardev socket,path=shmpath,id=ivsh \
	-device ivshmem-plain,memdev=vm0_mem \
	$*

#	-device ivshmem-doorbell,memdev=hostmem \
#	-object memory-backend-file,size=1M,share=on,mem-path=/dev/shm/ivshmem,id=hostmem \

#	-device virtio-net-device,netdev=net0 \
#	-device virtio-net-pci,netdev=net0,romfile="" \
#	-device loader,file=${ROOTFS},addr=0x50000000 \
#	-device loader,file=${KERNEL},addr=0x60000000 \
#	-device loader,file=${ROOTFS},addr=0x70000000 \

# Coverage
# -d nochain -etrace elog -etrace-flags exec -accel tcg,thread=single

#	-bios ${UBOOT} \
#	-device loader,file=${XEN},force-raw=on,addr=0x42000000 \
#	-device loader,file=${KERNEL},addr=0x47000000 \
#	-device loader,file=${DTB},addr=0x44000000 \

#	-kernel ${KERNEL} \
#	-initrd ${ROOTFS} \
#	-append "rdinit=/sbin/init console=ttyAMA0,115200n8 earlyprintk=serial,ttyAMA0" \

#	-d int,guest_errors,exec -D log \
#
