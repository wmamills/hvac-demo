# Demo1: Early virtio-msg kernel prototype

This work is a stepping stone toward other forms of virtio-msg. It leverages
work done in prior projects to unblock the kernel work on the common
virtio-msg transport layer.

The focus of this work is the guest kernel running in DomU. The use of Xen and
the rust based device model here are expediences to get something working
quickly and are reused from the prior Orko project.

Please keep in mind the following caveats for this demo at this stage:

* The virtio-msg-bus level here is not intended for real implementations as it
has no advantage over virtio-mmio. 

* This bus implementation relies on any response being available immediately
after sending, which is only possible in a trap and emulate environment 

* It also assumes that the driver side kernel can put buffers anywhere it
chooses to and uses Guest PA in virtqueues.

These items will be addressed in later work.

### Demo1 software layers

```
* QEMU system model of arm64.
  has i2c based rtc on virtio-i2c over virtio-mmio
  * Xen hypervisor
    * Dom0: Kernel + Debian rootfs on disk
      has i2c bus with rtc configured but unbound
      * vhost-device-i2c
        bridges vhost-i2c to kernel's i2c bus
      * xen-vhost-frontend
        converts xen io-req requests to standard vhost interface
      * xl tool stack
        creates the domu and connects its console to xen console
    * DomU: Kernel + minimal initrd
        implements virtio-i2c over virtio-msg-mmio
        binds kernel rtc driver to i2c rtc on virtio-msg
        * hwclock
          tests rtc
```
