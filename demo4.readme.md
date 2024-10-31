# Demo4: Dual QEMU with direct kernel virtio-msg

This demo has QEMU and Linux kernel with virtio-msg implemented.

Please keep in mind the following caveats for these demos at this stage:

* The shared memory layout of the virtio-msg-bus level here is a prototype and
is likely to change

* The virtio-msg-amp driver is an early prototype

* QEMU and the virtio-msg-amp driver only support one virtio device per bus
right now but that will be corrected soon.

* The demos assume that the driver side kernel can put buffers anywhere it
chooses to and uses Guest PA in virtqueues.  This is possible because the whole
memory of the driver side is shared to the device side via QEMU magic.

In the future we will support a mode where all virtqueus and buffers will be
constrained to a single shared memory segment.

## Description

This demo runs target software on both sides and uses multiple IVSHMEM instances
to connect the two sides in a simulated PCIe connection.

Both the device and and the drier side run on QEMU system models.  They are
both current emulating machines with armv8-A 64 bit CPUs with pci busses.

The target software on the device side is running QEMU in userspace running in
virtio-msg only mode.  This mode has no vCPUs and only provides the virtio-msg
based devices.  The device side see two IVSHMEM PCI devices.
It access the IVSHMEM PCI devices use generic PCI VFIO.

The first IVSHMEM instance has 4M shared memory and bi-directional interrupts.

The second IVSHMEM instance gives access to the other sides "DDR" memory.  This
is currently set to 1G to allow testing on smaller host machines but has been
tested at 4G in size as well.

The driver side system model only has one IVSHMEM corresponding to the first
IVSHSMEM of the device side.

The target software on the driver side is running a Linux kernel with prototype
virtio-msg-amp drivers.  The kernel connects the IVSHMEM PCI card to the 
virtio-msg-ivshmem driver and that driver creates the rest of the kernel stack
for the specific virtio-device discovered.  User space on the driver side only
does the modprobe and tests the device that shows up.

**Note: IVSHMEM2 will be made optional in future work.**

When the kernel side is taught how to constrain its memory usage to only the
shared memory area, then IVSHMEM2 will not be needed.
IVSHMEM1 will be made larger for most use cases in this mode.

### Demo4 Software Layers

```
Device Side:
* QEMU system model of arm64.
  disk drive, pci nic
  Has IVSHMEM1 w/ 4M, IRQ, and doorbell registers
	virtio-msg FIFO in shmem
	Driver side notifies via IRQ
	We notify driver via doorbell
  Has IVSHMEM2 w/ 1G mapped to Drivers side system DDR memory
  * Upstream Kernel and Debian rootfs on disk
    * QEMU as device model
      bridges virtio-net from virtio-msg to real nic card
      ( or bridges virtio-rng from virtio-msg to /dev/random )
      Accesses IVSHMEM1&2 using vfio
      Uses IVSHMEM1 for virtio-msg messages and notifications
      Uses IVSHMEM2 for target memory access

Driver Side:
* QEMU system model of arm64.
  Has pci nic (not used in demo)
  Has IVSHMEM w/ 4M, IRQ, and doorbell registers
	virtio-msg FIFO in shmem
	Device side notifies via IRQ
	We notify device via doorbell
  Has 1GB system DDR mapped to memory file
  * Kernel + minimal initramfs rootfs
    Kernel driver stack: 
	virtio-msg-ivshmem
	virtio-msg-amp
	virtio-msg
	virtio
	virtio-net | virtio-rng
    * User space demo script to test virtio-net or virtio-rng
```