# Notes on Yocto SDK cross build

## Xen hypervisor only build
As the hypervisor does not contain user space code, any cross compiler
can be used.  You can use one installed from your distro, one downloaded from
Arm ltd, or use one from the Yocto sdk.

### Debian'ish cross compiler
sudo apt install build-essential gcc-aarch64-linux-gnu
make -j 10 xen CROSS_COMPILE=aarch64-linux-gnu- XEN_TARGET_ARCH=arm64

### Yocto SDK
make -j 10 xen CROSS_COMPILE=aarch64-poky-linux- XEN_TARGET_ARCH=arm64

## Xen hypervisor & tool stack build

Building the Xen tool stack means building code for your target distro's 
userspace.  This means you need to match the libraries and C ABI of your target
distro.  This means you need to use a full SDK with all the libraries needed
and with compiler options set to match the ABI used in your distro.

### Build a Yocto SDK

You need to build an SDK for your desired version of Yocto and for an image
that includes all the needed libraries.  It is helpful to also have an image
with all the libraries install.

bitbake xen-image-minimal
bitbake -c populate_sdk xen-image-minimal

### Install the Yocto SDK

### Build the modified version of Xen

```
# source the SDK setup script
. ~/opt/yoxen/2024.02.10/arm64/environment-setup-cortexa57-poky-linux

# move all args from CC to CFLAGS, 
# xen make does not honor preset CC, instead it sets it to ${CROSS_PREFIX}gcc
# It does honor CFLAGS CROSS_PREFIX and LDFLAGS
ORIG_CC="$CC"
ORIG_CFLAGS="$CFLAGS"
ORIG_LDFLAGS="$LDFLAGS"
CC_CFLAGS=$(echo "$CC" | cut -d " " -f2-)
CC=$(echo "$CC" | cut -d " " -f1)
CFLAGS="$CC_CFLAGS $ORIG_CFLAGS"

# The yocto SDK defines LDFLAGS that are NOT compatible with the LD it defines
# The LDFLAGS assume you are using gcc as a frontend to the link process but 
# then it should define LD as aarch64-poky-linux-gcc or == CC
# DUMB!
LDFLAGS=""

XEN_TARGET_ARCH=arm64 ./configure \
	--libdir=/usr/lib \
	--build=x86_64-unknown-linux-gnu --host=aarch64-poky-linux \
	--disable-docs --disable-golang --disable-ocamltools \
	--with-system-qemu=/opt/qemu/bin/qemu-system-i386


```

## Other test targets

Test the sdk with various packages with various build systems.

simple Makefile:	i2c-tools tcf-agent lua
autotools: 		mtd rsync opkg mc xz
cmake:			apt rpm json-c nghttp2 libsdl2 expat
meson:			lighttpd dtc weston kmscube

