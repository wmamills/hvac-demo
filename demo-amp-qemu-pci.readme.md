# demo-amp-qemu-pci: virtio-msg-amp in kernel with device on PCIe card emulated by QEMU

This demo is the simplest and fastest for virtio-msg-amp.

* The driver side is the Linux kernel + minimal rootfs in initramfs
* The device side is a simple PCIe card emulated by QEMU
* QEMU also implements the device side software of virtio-msg-amp
* There is no device side cpu emulated, it is native to QEMU itself

Please keep in mind the following caveats for this demo at this stage:

* The shared memory layout of the virtio-msg-bus level here is a prototype and
is likely to change

* The virtio-msg-amp driver is an early prototype

* QEMU and the virtio-msg-amp driver only support one virtio device per bus
right now but that will be corrected soon.

## Emulated PCIe HW Description

The emulated PCIe card has:

* BAR0 with 2 doorbell MMRs.  Each doorbell MMR can send 8 Interrupts to the device
* 16 MSIX interrupts from PCIe card to host for device -> driver notifications
* BAR2 is a 4MB SRAM.  This SRAM is used for layout discovery and for the AMP
message queues.
* The PCIe card can access host memory.  The host memory is used for virtqueus and
buffers

QEMU also implements the functions of the software that would run on the PCIe
card.  This is done with native QEMU code; no vCPU is present.

## Demo Software Layers

```
* QEMU system model of arm64.
  disk drive, pci nic
  PCIe card for virtio-msg-amp
  * Kernel + minimal initramfs rootfs
    Kernel driver stack: 
	virtio-msg-amp-generic-pci
	virtio-msg-amp
	virtio-msg
	virtio
	virtio-net | virtio-rng
    * User space demo script to test virtio-net or virtio-rng
```