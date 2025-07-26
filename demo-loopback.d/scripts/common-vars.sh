# to be sourced, not run

# include the demo common settings and functions
. $MY_DIR/../../scripts/demo-common.sh

QEMU_DIR=host/${HOST_ARCH}/qemu-i2c
QEMU=$IMAGES/$QEMU_DIR/bin/qemu-system-aarch64

KERNEL=target/aarch64/linux-virtio-msg-lb-Image

QEMU_BASE=(
  -machine virt,virtualization=on,gic-version=3
  -cpu cortex-a57 -serial mon:stdio
  -device virtio-net-pci,netdev=net0 -netdev user,id=net0,hostfwd=tcp::8022-:22
  -drive file=${BUILD}/demo-loopback-disk.qcow2,id=hd0,if=none,format=qcow2
  -device virtio-scsi-pci -device scsi-hd,drive=hd0
  -display none -m 8192 -smp 8
  -kernel ${IMAGES}/${KERNEL}
  -append "earlycon root=/dev/sda2 autorun=./demo-loopback/demo.sh"
  -device ds1338,address=0x20
)
