# demo-amp-zephyr: Cortex-M MCU with ivshmem-flat and Linux uio

**This demo is a work in progress.**  It currently shows the low level AMP
basics that will be used but does not yet implement virtio-msg-amp.

This demo shows how to do shared memory and bi-directional interrupts between
a MCU platform and Linux using two QEMU instances.
It is one way to simulate an AMP SOC using QEMU.
It also more directly simulates how a PCIe card with a Cortex-M on it would
look to the software of both sides.

This demo uses a QEMU with a new type of ivshmem called ivshmem-flat.
Normal ivshmem appears as a PCI/PCIe card to the target system.
This is great for Cortex-A and x86 but not viable for MCU like targets such as
Cortex-M (or R).  The ivshmem-flat work adds a non-pci mode to ivshmem.
This device maps the "BAR0" registers and the "BAR2" shared memory at addresses
specified by command line parameters.  The interrupt is attached to the IRQ
specified by an object model string.  (Note: The BAR1 registers are never
required as those specify MSI parameters and MSI is not used in ivshmem-flat.)

On the other side, Linux is used.  This Linux branch has a uio driver for PCI 
ivshmem.  The Linux userspace has a test program that uses uio to communicate
with the Cortex-M.  There are multiple way this demo could have been constructed
such as using vfio or perhaps the generic PCI uio driver.  However since
demo-amp-dual-linux uses a ivshmem pci driver for virtio-msg, this demo tests
some of the low level facilities for that using an existing kernel pci driver.

### Demo software layers

```
Cortex-M Side:
* QEMU system model of Arm's MPS2 M3 system with added ivshmem-flat.
  Provides shared memory, IRQ and doorbell registers
  MPS2 application note number: AN385
  * Zephyr w/ uio-test app

Cortex-A Side:
* QEMU system model of arm64.
  Uses standard ivshmem (PCI based)
  * Kernel + ivshmem uio driver
    * Debian rootfs
      * uio-ivshmem-test program
```
