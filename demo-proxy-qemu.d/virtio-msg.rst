..

VirtIO-MSG
==========

Virtio-msg is a new message based virtio transport (as opposed to memory
access based ones). It is comparable to virtio-ccw and to some extent
vhost-user.

QEMU has an implementation of the virtio-msg transport aswell as an
implementation of a proxy that translates between existing transport
(e.g virtio-mmio/pci) and virtio-msg.

At a high level the virtio-msg spec is split into the message transport and
the lower level message bus. Different implementations of msg busses are
expected, e.g FF-A, direct hw (vfio?), Linux user-space, Xen and others.

Currently we have a PoC of a Linux userspace bus that allows communication
between QEMU's running on the same host. We also have a vfio based bus
driver that works over two ivshmem devices in separate QEMU instances.

The msg-bus abstraction is implemented here:
  hw/virtio/virtio-msg-bus.c

The linux-user message-bus implementation here:
  hw/virtio/virtio-msg-bus-linux-user.c
  include/hw/virtio/spsc_queue.h

The ivshmem message-bus implementation here:
  hw/virtio/virtio-msg-bus-ivshmem.c
  include/hw/virtio/spsc_queue.h

The virtio-msg protocol packetizer/decoder here:
  include/hw/virtio/virtio-msg-prot.h

The transport:
  hw/virtio/virtio-msg.c

The proxy device that translates from mmio/pci to msg:
  hw/virtio/virtio-msg-proxy-driver.c

The virtio-msg backend machine:
  hw/virtio/virtio-msg-machine.c

Running Virtio-MSG with the Linux-user msg-bus using two QEMU instances
-----------------------------------------------------------------------

To run this example you first need to run the virtio-msg machine and
secondly then the virt machine with Linux.

Running the virtio-msg backends machine:

Before running the virtio-msg machine with the backends, we need to
remove any existing queue's.

.. code-block:: bash

   rm -fr queue-linux-user-d* && \
   qemu-system-aarch64 -M x-virtio-msg -m 2G -cpu cortex-a72 \
        -object memory-backend-file,id=mem,size=2G,mem-path=/dev/shm/qemu-ram,share=on \
        -machine memory-backend=mem \
        -chardev socket,id=chr0,path=linux-user.socket,server=on,wait=false \
        -serial mon:stdio -display none \
        -device virtio-msg-bus-linux-user,name=linux-user,chardev=chr0,memdev=mem,mem-offset=0x40000000 \
        -device virtio-net-device,netdev=net0,iommu_platform=on \
        -netdev user,id=net0 \
        -object filter-dump,id=f0,netdev=net0,file=net.pcap


Running a Linux guest on the virt machine:

.. code-block:: bash

   qemu-system-aarch64 -M virt -m 2G -cpu cortex-a72 \
        -object memory-backend-file,id=mem,size=2G,mem-path=/dev/shm/qemu-ram,share=on \
        -machine memory-backend=mem \
        -chardev socket,id=chr0,path=linux-user.socket \
        -serial mon:stdio -display none \
        -kernel Image \
        -initrd core-image-minimal-qemuarm64.rootfs.cpio.gz \
        -append "rdinit=/sbin/init console=ttyAMA0 lpj=100" \
        -device virtio-msg-proxy-driver-pci,virtio-id=0x1 \
        -device virtio-msg-bus-linux-user,name=linux-user,chardev=chr0


To use virtio-mmio, replace the -device virtio-msg-proxy-driver-pci with:

.. code-block:: bash

   -device virtio-msg-proxy-driver,iommu_platform=on,virtio-id=0x1      \
   -global virtio-mmio.force-legacy=false                               \


Running Virtio-MSG over the IVSHMEM msg-bus using two QEMU instances
--------------------------------------------------------------------

We'll run two outer QEMU instances that emulate our HW. These will
use a memory backend of shared files for the machine system memory.
In addition to that, the same memory backend will be used for
IVSHMEM devices on each QEMU instance. This will allow both
instances to access all of each others system memory via the IVSHMEM
devices BAR.

I've tried 2 different setups, one runs virtio-msg between a driver
KVM guest and a Xen dom0 with the backends. The second setup is
between two Xen instances and their respective dom0s. In theory,
KVM to KVM and Xen DomU to DomU or any combination should work.


First, we need to start the ivshmem server. Here shmpath is the name
of a unix socket that we'll need to connect to later on.

.. code-block:: bash

   rm shmpath
   ivshmem-server -S shmpath -p pidfile -l 1M -n 1



I've added some example scripts in docs/devel/virtio-msg/scripts/.
run-A.sh and run-B.sh are used to run the outer QEMU's for system
A and B.

You'll need to change some paths in the script to match your environment.
QEMU points to your build of QEMU from the edgar/virtio-msg branch.
XEN points to your build of Xen from the edgar/virtio-msg branch.

https://github.com/edgarigl/xen/tree/edgar/virtio-msg

KERNEL points to a build of a Linux kernel (upstream)
UBOOT points to a build of U-boot from upstream
DTB points to a device-tree file for the QEMU virt machine.

To create the DTB, you can start by running the QEMU command-line from
below, remove the line that loads the non-existing DTB, and add
-machine dumpdtb=virt.dtb. Convert that to a dts and edit it to add
the appropriate nodes for Xen (xen,bootargs, dom0 image etc).
I've provided an example in docs/devel/virtio-msg/dts/

Run Xen or Linux/KVM on QEMU for ARM:

.. code-block:: bash

   run-A.sh

Once you get into U-boot, you can boot Xen by doing the following:

.. code-block:: bash

   booti 0x42000000 - 0x44000000


Or boot KVM by doing the following:

.. code-block:: bash

   booti 0x47000000 - 0x44000000


Once you've booted two instances of either Xen or KVM, we need to prep
the IVSHMEM PCIe devices to be used for notifications. You'll need to do
these steps on both machines.

Enable VFIO (including noiommu for Xen) for IVSHMEM:
.. code-block:: bash

    echo 1 >/sys/module/vfio/parameters/enable_unsafe_noiommu_mode
    echo 1af4 1110 >/sys/bus/pci/drivers/vfio-pci/new_id


Figure out the IVSHMEM VMID. Find the IVSHMEM device by running lspci -v,
it will be the IVSHMEM device with 3 BARs, e.g:

.. code-block:: bash

   lspci -v
   00:02.0 RAM memory: Red Hat, Inc. Inter-VM shared memory (rev 01)
        Subsystem: Red Hat, Inc. QEMU Virtual Machine
        Flags: fast devsel, IRQ 24, IOMMU group 1
        Memory at 10001000 (32-bit, non-prefetchable) [size=4K]
        Memory at 10002000 (32-bit, non-prefetchable) [size=4K]
        Memory at 8100000000 (64-bit, prefetchable) [size=1M]
        Capabilities: [40] MSI-X: Enable- Count=2 Masked-
        Kernel driver in use: vfio-pci


The VMID can be read from BAR0 offset 8:

.. code-block:: bash

    devmem2 0x10001008 w
    /dev/mem opened.
    Memory mapped at address 0xffff8b8ef000.
    Read at address  0x10001008 (0xffff8b8ef008): 0x0000002E


In our example, the VMID was 0x2E. Remember, you'll need to figure out the
VMID's for both outer QEMU machines.

To run the inner QEMU's with virtio-msg support, I've provided a couple of
examples in docs/devel/virtio-msg/scripts/. There's guest-qemu-run-msg.sh that
runs the device/backend side. You'll need to edit the script to match where your IVSHMEM devices ended up. The script takes the VMID of the other outer QEMU as an argument.

.. code-block:: bash

   ./guest-qemu-run-msg.sh 0x2e


To a guest in KVM, edit and run the guest-qemu-run-virt.sh script.
You'll need to update the remote-vmid property with the VMID of the QEMU machine running the backends.

.. code-block:: bash

   ./guest-qemu-run-virt.sh


You should now see Linux booting in the inner VM.

If you want to run a DomU in Xen instead of a KVM guest, I've provided an example guest-virtio-msg.cfg. You'll have to edit it for IVSHMEM device ID and remote-vmid.

.. code-block:: bash

   xl create -cd guest-virtio-msg.cfg

