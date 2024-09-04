#!/bin/bash

admin_setup() {
	dpkg --add-architecture arm64
	apt-get update -qq
	# for xen (basic) and kernel build
	apt-get install -yqq build-essential git bison flex wget curl \
            bc libssl-dev libncurses-dev kmod python3 python3-setuptools iasl
	# for cross-build
        apt-get install -yqq gcc-aarch64-linux-gnu uuid-dev:arm64 libzstd-dev \
            libncurses-dev:arm64 libyajl-dev:arm64 zlib1g-dev:arm64 \
            libfdt-dev:arm64 libpython3-dev:arm64
	# qemu build support
	apt-get install -yqq python3-pip python3-venv ninja-build libglib2.0 \
	    libpixman-1-dev libslirp-dev
}

prj_setup() {
	# install rustup/cargo/rustc, latest version, no prompts
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	. ~/.cargo/env
	rustup target add aarch64-unknown-linux-gnu
	echo -e '[target.aarch64-unknown-linux-gnu]\nlinker = "aarch64-linux-gnu-gcc"' >>~/.cargo/config.toml
}

prj_build() {
	build_xen
	build_xen_vhost_frontend
	build_vhost_device
	build_linux
	build_qemu
	echo "****** Done"
}

build_xen() {
	echo "****** Build xen"
	cd xen
	git clean -fdX
	./configure --libdir=/usr/lib --build=x86_64-unknown-linux-gnu --host=aarch64-linux-gnu \
		--disable-docs --disable-golang --disable-ocamltools \
		--with-system-qemu=/root/qemu/build/i386-softmmu/qemu-system-i386
	make -j9 debball CROSS_COMPILE=aarch64-linux-gnu- XEN_TARGET_ARCH=arm64
	cd ..
}

build_rust() {
	build_xen_vhost_frontend
	build_vhost_device
}

build_xen_vhost_frontend() {
	echo "****** Build xen-vhost-frontend"
	cd xen-vhost-frontend
	. ~/.cargo/env
	cargo build --release --all-features --target aarch64-unknown-linux-gnu
	cd ..
}

build_vhost_device() {
	echo "****** Build vhost-device"
	cd vhost-device
	# ~/.cargo/env is still active
	cargo build --bin vhost-device-i2c --release --all-features --target aarch64-unknown-linux-gnu
	cd ..
}

build_linux() {
	echo "****** Build Linux"
	if [ ! -d linux ]; then
		git clone git://git.kernel.org/pub/scm/linux/kernel/git/vireshk/linux.git
		cd linux
		git checkout virtio/msg
		#git reset --hard 1e5e683a3d1aa8b584f279edd144b4b1d5aad45c
	else
		cd linux
	fi
	mkdir -p ../build/linux
	export ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-
	export KBUILD_OUTPUT="$(cd ../build/linux; pwd)"
	export INSTALL_PATH_BASE=${KBUILD_OUTPUT}-install
	export INSTALL_PATH=$INSTALL_PATH_BASE/boot
	export INSTALL_DTBS_PATH=$INSTALL_PATH/dtb
	export INSTALL_MOD_PATH=$INSTALL_PATH_BASE

	make defconfig
	make -j10 Image modules dtbs

	rm -rf ../build/linux-install
	mkdir -p ../build/linux-install/boot
	mkdir -p ../build/linux-install/lib/modules
	KREL=$(make --no-print-directory kernelrelease)
	fakeroot make INSTALL_MOD_STRIP=1 install modules_install
	fakeroot make dtbs_install || true
	#fakeroot make firmware_install || true
	(cd $INSTALL_PATH_BASE; mkdir -p lib/firmware; mv modules-$KREL.tar.gz modules-$KREL.tar.gz.old >/dev/null 2>&1 || true; fakeroot tar czvf modules-$KREL.tar.gz lib/modules/$KREL lib/firmware)
	cd ..
}

build_qemu() {
	echo "****** Build qemu"
	if [ ! -d qemu ]; then
		git clone https://github.com/vireshk/qemu
		cd qemu
		git reset --hard b7890a2c3d6949e8f462bb3630d5b48ecae8239f
		cd ..
	fi
	mkdir -p build/qemu
	mkdir -p build/qemu-install
	cd build/qemu
	../../qemu/configure \
		--target-list="aarch64-softmmu" \
		--prefix="$(cd ../qemu-install; pwd)" \
		--enable-fdt --enable-slirp --enable-strip \
		--disable-docs \
		--disable-gtk --disable-opengl --disable-sdl \
		--disable-dbus-display --disable-virglrenderer \
		--disable-vte --disable-brlapi \
		--disable-alsa --disable-jack --disable-oss --disable-pa
	make -j10
	make install
	cd ../..
}

CMD=${1/-/_}; shift

case $CMD in
admin_setup|prj_setup|prj_build)
	$CMD "$@"
	;;
build_*)
	$CMD "$@"
	;;
*)
	echo "Unknown prj_script command $1"
	exit 2
	;;
esac
