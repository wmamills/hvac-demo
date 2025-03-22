# Notes on Yocto SDK cross build

## Xen hypervisor only build

As the hypervisor does not contain user space code, any cross compiler
can be used.  You can use one installed from your distro, one downloaded from
Arm ltd, or use one from the Yocto sdk.

### Debian'ish cross compiler

```
sudo apt install build-essential gcc-aarch64-linux-gnu
make -j 10 xen CROSS_COMPILE=aarch64-linux-gnu- XEN_TARGET_ARCH=arm64
```

### Yocto SDK

Install a Yocto SDK. See the section below for details.

```
make -j 10 xen CROSS_COMPILE=aarch64-poky-linux- XEN_TARGET_ARCH=arm64
```

## Xen hypervisor & tool stack build

Building the Xen tool stack means building code for your target distro's
userspace.  This requires you to match the libraries and C ABI of your target
distro.  This means you need to use a full SDK with all the libraries needed
and with compiler options set to match the ABI used in your distro.

### Build a Yocto SDK

You need to build an SDK for your desired version of Yocto and for an image
that includes all the needed libraries.  It is helpful to also have an image
with all the libraries installed.

Your SDK will need extra python packages on the host side.  You will need lines
like this in your local.conf

```
# example image customization
EXTRA_IMAGE_FEATURES = "debug-tweaks"
IMAGE_INSTALL:append = " qemu openssh devmem2"

# sdk extra python packages for host side
# perhaps not all of these are needed but these are the ones avialable in the
# sysroot of the yocto build of xen-tools
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-setuptools"
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-build"
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-dev"
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-flit-core"
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-iniparse"
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-installer"
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-packaging"
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-wheel"
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-six"
TOOLCHAIN_HOST_TASK:append = " nativesdk-python3-pyproject-hooks"
```

Then build with something like:

```
bitbake xen-image-minimal
bitbake -c populate_sdk xen-image-minimal
```

### Install the Yocto SDK

Install the SDK as normal.  I use ~/opt as the default base for install but you
may use /opt if you have the needed permissions.  I also add a suffix for the
architecture for the sdk.

### Build the modified version of Xen

```
# source the SDK setup script
. ~/opt/yoxen/2024.02.10/arm64/environment-setup-armv8a-poky-linux

# Make a script version of $CC and place it in the path first
# xen make does not honor preset CC, instead it sets it to ${CROSS_PREFIX}gcc
# It does honor CFLAGS CROSS_PREFIX and LDFLAGS
ORIG_CC="$CC"
ORIG_CFLAGS="$CFLAGS"
ORIG_LDFLAGS="$LDFLAGS"
CC_ARGS=$(echo "$CC" | cut -d " " -f2-)
CC=$(echo "$CC" | cut -d " " -f1)
CC_FULL=$(which $CC)
mkdir -p build/yocto-sdk/bin
echo '#!/bin/sh' >build/yocto-sdk/bin/$CC
echo "$CC_FULL $CC_ARGS \"\$@\"" >>build/yocto-sdk/bin/$CC
chmod +x build/yocto-sdk/bin/$CC
PATH=$PWD/build/yocto-sdk/bin:$PATH

# The yocto SDK defines LDFLAGS that are NOT compatible with the LD it defines
# The LDFLAGS assume you are using gcc as a frontend to the link process but
# then it should define LD as aarch64-poky-linux-gcc or == CC
# DUMB!
unset LDFLAGS

cd src/xen-my-fork

# start clean
git clean -fdx

XEN_TARGET_ARCH=arm64 ./configure \
	--libdir=/usr/lib \
	--build=x86_64-unknown-linux-gnu --host=aarch64-poky-linux \
	--disable-docs --disable-golang --disable-ocamltools \
	--with-system-qemu=/opt/qemu/bin/qemu-system-i386

make -j 10 dist CROSS_COMPILE=aarch64-poky-linux- XEN_TARGET_ARCH=arm64

```

The dist directory in you xen source tree will have the files for your target
system and a script to install them.

## Other test targets

Test the sdk with various packages with various build systems.

simple Makefile:	i2c-tools tcf-agent lua
autotools: 		mtd rsync opkg mc xz
cmake:			apt rpm json-c nghttp2 libsdl2 expat
meson:			lighttpd dtc weston kmscube

