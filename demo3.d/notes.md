# Notes from HPP JIRA

## HPP-147: QEMU: Test new ivshmem-flat device with RPMsg

### HOST SIDE

Build and run Cortex-A FW `dual_qemu_ivshmem` example with Zephyr 3.4 from:
https://github.com/gromero/openamp-system-reference/commits/host_u

A PR is under review for the changes in this branch: 
https://github.com/OpenAMP/openamp-system-reference/pull/23

Checkout Zephyr upstream v3.4-branch `origin/v3.4-branch` and use it to build
the openamp-system-reference:

```
$ west build -p always -b qemu_cortex_a53 ~/host_u/examples/zephyr/dual_qemu_ivshmem/host -t run
```

It will print the mapped PCI shmem address that is used on the host side,
for instance: `shmem mapped at 0xafa00000, 4194304 byte(s)`.

### REMOTE SIDE

Build QEMU 'qemu-system-arm' binary from the following branch, which has the ivshmem-flat device supporting option 'shmem-addr': `https://github.com/gromero/qemu/tree/ivshmem`

Clone dual-qemu-ivshmem example for the remote side from:
`https://github.com/gromero/openamp-system-reference/tree/ivshmem_flat`

Build and run the example FW:

Set QEMU binary path in Zephyr to make Zephyr use the qemu-system-arm binary
that supports the ivshmem-flat device, for instance:

```
$ export QEMU_BIN_PATH=/home/gromero/git/qemu/build/
```

Adjust QEMU extra flags to pass the ivshmem options, including the shmem-addr
option, which must be the same as the one informed by the host side
(shmem mapped at 0xafa00000, 4194304 byte(s).). 
Hence, in this example: 0xafa00000

```
$ export QEMU_EXTRA_FLAGS="-chardev socket,path=/tmp/ivshmem_socket,id=ivshmem -ivshmem shmem-maxsize=4194304,shmem-addr=0xafa00000"
```

Finally, build and run the example. Make sure to define SHMEM_ADDR= so it
matches the address passed to QEMU via the shmem-addr option:

```
$ west build -p always -b qemu_cortex_m3 ~/remote/examples/zephyr/dual_qemu_ivshmem/remote -t run 
-DCMAKE_C_FLAGS="-DSHMEM_ADDR=0xafa00000"
```

## HPP-105: Kernel: provide access to ivshmem from user space

uio_ivshmem driver for Linux can be found in:
https://github.com/gromero/linux/commit/28f3f88ee261245a0fd47d5c9a0705369f141403

To experiment with it on Linux 6.6.0-rc1:

Clone branch:
https://github.com/gromero/linux/commits/uio_ivshmem

Grab .config from https://people.linaro.org/~gustavo.romero/ivshmem/arm64_uio_ivshmem.config :

If in an x86_64 machine, cross compile the kernel:

```
$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j 36
```

Install vmlinuz in some directory, for instance, in ~/linux:

```
$ export INSTALL_PATH=~/linux
$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j 36 install
```

Clone QEMU with ivshmem device for Cortex-M from this branch:
https://github.com/gromero/qemu/tree/ivshmem

And build it for arm and arm64, for instance:
```
$ mkdir build && cd build
$ ../configure --target-list=arm-softmmu,aarch64-softmmu
$ make -j 36
```

Download rootfs from:
```
$ wget https://people.linaro.org/~gustavo.romero/ivshmem/rootfs.qcow2
```

Note: user and password for this rootfs image is `root` and `abc123`

Build a zephyr.elf image for cortex-m3 from:
`https://github.com/gromero/zephyr/tree/uio_ivshmem`

with west:

```
$ west build -p always -b qemu_cortex_m3 samples/uio_ivshmem/
```

Start ivshmem-server in the host.

Then start a QEMU VM with Zephyr:

```
$./qemu-system-arm -cpu cortex-m3 -machine lm3s6965evb -nographic -net none -chardev stdio,id=con,mux=on -serial chardev:con -mon
chardev=con,mode=readline -chardev socket,path=/tmp/ivshmem_socket,id=ivshmem -ivshmem shmem-maxsize=4194304 -kernel ~/zephyr.elf
```

expect output like:

```
qemu-system-arm: warning: nic stellaris_enet.0 has no peer
Timer with period zero, disabling
```

## HPP-157: Make ivshmem-flat device available on the mps2-an385 machine

```
$ ./qemu-system-arm -cpu cortex-m3 -machine mps2-an385 -nographic -net none \
-chardev stdio,id=con,mux=on -serial chardev:con -mon chardev=con,mode=readline \
-chardev socket,path=/tmp/ivshmem_socket,id=ivf \
-device ivshmem-flat,x-irq-qompath='/machine/armv7m/nvic/unnamed-gpio-in[0]',chardev=ivf,shmem-maxsize=4194304 \
-kernel ~/zephyr_qemu_an385_ivshmem.elf
```
