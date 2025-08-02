# to be sourced, not run

# include the demo common settings and functions
. $MY_DIR/../../scripts/demo-common.sh

QEMU_DIR=host/${HOST_ARCH}/qemu-msg-v2
QEMU=$IMAGES/$QEMU_DIR/bin/qemu-system-aarch64

KERNEL1=target/aarch64/linux-virtio-msg-amp-v2-Image
INITRD1=demo-amp-qemu-pci-rootfs.cpio.gz

DISK_TARGETS[$INITRD1]=disk_demo_amp_qemu_pci
