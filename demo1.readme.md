# Demo1: virtio-msg kernel prototype with FFA

This work shows virtio-msg running over the Arm FFA interface.
It uses FFA indirect messages from DomU to Dom0.

It is currently using Xen page grants for Dom0 to access DomU's memory.  This
is a valid choice and should be maintained long term.

When Xen can handle FFA memory sharing APIs, this demo can be updated to use
them as an alternative to the page grants.
This will make this mode more like the virtio-msg-ffa planned for use with
TEEs in secure world.

This demo is based on [this write up](https://linaro.atlassian.net/wiki/spaces/HVAC/pages/29657792513/2024-11+kernel+prototype+with+FFA).

### Demo1 software layers

```
* QEMU system model of arm64.
  has i2c based rtc on a fsl,imx1-i2c controller as a platform device
  * Xen hypervisor w/ FFA for VM to VM
    * Dom0: Kernel + Debian rootfs on disk
      has i2c bus with rtc configured but unbound
      * vhost-device-i2c
        bridges vhost-i2c to kernel's i2c bus
      * xen-vhost-frontend
        converts FFA indirect messages to standard vhost interface
	uses Xen page grants to access domu memory
      * xl tool stack
        creates the domu and connects its console to xen console
    * DomU: Kernel + minimal initrd
        implements virtio-i2c over virtio-msg-ffa
        binds kernel rtc driver to i2c rtc on virtio-msg
        * hwclock
          tests rtc
```
