# demo-proxy-qemu : QEMU with virtio-msg-proxy

This demo has QEMU with virtio-msg implemented.  QEMU also has a 
virtio-msg-proxy that functions as a bridge between existing transports like 
virtio-mmio and virtio-msg.  These demos use enhanced QEMU with existing 
upstream kernels that are unaware of virtio-msg.

Please keep in mind the following caveats for these demos at this stage:

* The shared memory layout of the virtio-msg-bus level here is a prototype and
is likely to change

* The demos assume that the driver side kernel can put buffers anywhere it
chooses to and uses Guest PA in virtqueues.  This is possible because the whole
memory of the driver side is shared to the device side via QEMU magic.

In the future we will support a mode where all virtqueus and buffers will be
constrained to a single shared memory segment.

This demo runs target software on both sides and uses multiple IVSHMEM instances
to connect the two sides.

The first IVSHMEM instance has 1M shared memory and bi-directional interrupts.

The second IVSHMEM instance gives access to the other sides "DDR" memory.  This
is currently set to 1G to allow testing on smaller host machines but has been
tested at 4G in size as well.  The Driver side does not really need the second 
instance as it does not need access to the device side memory but it is present
only to keep things symmetrical.

**Note: IVSHMEM2 will be made optional in future work.**

When the kernel side is taught how to constrain its memory usage to only the
shared memory area, then IVSHMEM2 will not be needed.
IVSHMEM1 will be made larger for most use cases in this mode.

This demo can be run in a number of combinations.  The device side can run the
Linux kernel directly or can run Xen with Linux running as Dom0.  The driver
side can run the guest kernel using KVM or as a DomU under Xen.  In practice
the choice on each side is independent but we will show direct/kvm and xen/xen
for illustration.

### demo-proxy-qemu using direct and kvm (default)

```
Device Side:
* QEMU system model of arm64.
  Has two IVSHMEM devices, disk drive, pci nic
  * Upstream Kernel and Debian rootfs on disk
    * QEMU as device model
      bridges virtio-net from virtio-msg to real nic card
      Accesses IVSHMEM1&2 using vfio
      Uses IVSHMEM1 for virtio-msg messages and notifications
      Uses IVSHMEM2 for target memory access

Driver Side:
* QEMU system model of arm64.
  Has two IVSHMEM devices, disk drive, pci nic (not used in demo)
  * Kernel + Debian rootfs on disk
    * QEMU + KVM 
      This QEMU exposes eth1 as virtio-mmio and bridges to ivshmem
      (eth0 is always exposed by QEMU virt machine, no used in demo)
      * Kernel + minimal initrd
        configures and tests the bridged ethernet (eth1)
```

### demo-proxy-qemu-xen using Xen on both sides

```
Device Side:
* QEMU system model of arm64.
  Has two IVSHMEM devices, disk drive, pci nic
  * Xen hypervisor
    * Dom0: Upstream Kernel and Debian rootfs on disk
      * QEMU as device model
        bridges virtio-net from virtio-msg to real nic card
        Accesses IVSHMEM1&2 using vfio
        Uses IVSHMEM1 for virtio-msg messages and notifications
        Uses IVSHMEM2 for target memory access

Driver Side:
* QEMU system model of arm64.
  Has two IVSHMEM devices, disk drive, pci nic (not used in demo)
  * Xen hypervisor
    * Dom0: Kernel + Debian rootfs on disk
      * QEMU as device model
        This QEMU exposes eth0 as virtio-mmio and bridges to ivshmem
    * DomU: Kernel + minimal initrd
        configures and tests the bridged ethernet (eth0)
```
