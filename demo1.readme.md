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

The current version of rustc at the time this page was written was 1.80.1
