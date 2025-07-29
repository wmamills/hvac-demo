# Demo-loopback: virtio-msg loopback

This work shows virtio-msg-loopback.  This bus implementation allows a device
model to run in user space of the kernel that consumes the device.  In this way
it acts similar to fuse filesystems, cuse character devices, or loopback block
devices except that it allows any virtio device to be used.

This demo implements an I2C controller in user space using rustvmm components.
That bus has one I2C device that is a realtime clock.  The rtc device is
implemented by bridging the request to a real I2C rtc device attached to QEMU.

The virtio-msg-loopback bus driver requires a reserved memory area to use for
all virtqueues and buffers.  In this demo a 4MB area is used.

When the virtio-msg-loopback driver completes probe, the virtio-msg-loopback
bus will exist but no virtio devices will exist yet.  The bus driver will create
/dev/virtio-msg-lb device node that will be used for bus control and for memory
mapping of the reserved memory area.

The bus driver will also create /dev/virtio-msg-0 which is the standard device
side interface for the device model to send and receive messages to and from
the bus.

The lb-vhost-device-i2c process will create a socket for the device frontend
and connect to the real rtc device.  The lb-vhost-frontend process will use the
/dev/virtio-msg-{lb,0} device nodes and wait for the virtio device to be
created.  Finally the virtio-msg-loopback utility will perform an IOCTL on the 
/dev/virtio-msg-lb device to create the virtio-i2c device.

This demo is based on [this write up](https://linaro.atlassian.net/wiki/spaces/HVAC/pages/30104092673/2025-06+kernel+prototype+with+Virtio+Message+Loopback).

### Demo-loopback software layers

```
* QEMU system model of arm64.
  has i2c based rtc on a fsl,imx1-i2c controller as a platform device
  * Kernel + Debian rootfs on disk
      has i2c bus with rtc configured but unbound
      has reserved memory region
      has virtio-msg-loopback bus
      will create virtio-msg-i2c device when asked
        implements virtio-i2c over virtio-msg-loopback
        binds kernel rtc driver to i2c rtc on virtio-i2c
    * lb-vhost-device-i2c
        bridges vhost-i2c to kernel's i2c bus
        communicates to vhost-frontend via socket inode
    * lb-vhost-frontend
        converts FFA indirect messages to standard vhost interface
        uses memmap on /dev/virtio-msg-lb for reserved memory access
        uses read & write on /dev/virtio-msg-0 to tx/rx messages to bus
    * virtio-msg-loopback
        does IOCTL on /dev/virtio-msg-lb to create virtio-i2c device
    * hwclock
        tests rtc1

NOTE: /dev/rtc1 is the virtio-msg based rtc device
      /dev/rtc0 is the base rtc device in QEMU's virt machine
```
