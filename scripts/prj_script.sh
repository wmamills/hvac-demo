#!/bin/bash

THIS_SCRIPT=$0
NAME=hvac-demo

# This is a poorman's dockit function
# do distro setup like dockit would before admin_setup
distro_setup() {
	if [ -e /root/distro_setup.done ]; then
		return
	fi

	apt-get -qq update
	apt-get install -qqy sudo
	if id $MY_UID >/dev/null 2>&1; then
		OLD_USER=$(id -nu $MY_UID)
		echo "Removing user $OLD_USER, as it conflicts with user $MY_USER $MY_UID:$MY_GID"
		userdel $OLD_USER
	fi
	groupadd --gid $MY_GID $MY_USER
	useradd  --uid $MY_UID --gid $MY_GID --shell /bin/bash -mN $MY_USER
	groupadd --system sudo_np
	usermod -a -G sudo_np $MY_USER
	mkdir -p /etc/sudoers.d/
	echo "%sudo_np ALL=(ALL:ALL) NOPASSWD:ALL" >/etc/sudoers.d/sudo_np

	echo "done" >/root/distro_setup.done
}

# part of poorman's dockit
# This is suppose to be better than "su"
userjmp() {
    setpriv --reuid=$MY_UID --regid=$MY_GID --init-groups --reset-env "$@"
}

do_once() {
	if [ ! -e ~/$1.done ]; then
		"$@"
		echo "done" >~/$1.done
	fi
}

# part of poorman's dockit
container_main() {
	if [ "$EUID" -ne 0 ]; then
		echo "Error: container-main must be run as root"
		exit 2
	fi
	if [ ! -d /prj ]; then
		echo "Error: project directory not mounted at /prj"
		exit 2
	fi

	cd /prj
	MY_UID=$(stat --format="%u" /prj)
	MY_GID=$(stat --format="%g" /prj)
	MY_USER="me"

	do_once distro_setup
	do_once admin_setup
	userjmp $THIS_SCRIPT do_once prj_setup

	CMD=$1; shift
	case $CMD in
	build)
		userjmp $THIS_SCRIPT prj_build "$@"
		;;
	shell)
		userjmp /bin/bash -l
		;;
	*)
		echo "unknown command $CMD"
		exit 2
	esac
}

admin_setup() {
	dpkg --add-architecture arm64
	apt-get update -qq
	# for xen (basic) and kernel build
	apt-get install -yqq build-essential git bison flex wget curl \
	    bc libssl-dev libncurses-dev kmod python3 python3-setuptools iasl
	# for cross-build
	apt-get install -yqq gcc-aarch64-linux-gnu uuid-dev:arm64 libzstd-dev:arm64 \
	    libncurses-dev:arm64 libyajl-dev:arm64 zlib1g-dev:arm64 \
	    libfdt-dev:arm64 libpython3-dev:arm64
	# qemu build support
	apt-get install -yqq python3-pip python3-venv ninja-build libglib2.0-dev \
	    libpixman-1-dev libslirp-dev
	# qemu cross compile support
	apt-get install -yqq pkg-config:arm64 libglib2.0-dev:arm64 \
	    libpixman-1-dev:arm64 libslirp-dev:arm64

	# guestfish support, it also needs a readable kernel in /boot
	apt-get install -yqq --no-install-recommends \
		guestfish linux-image-amd64 guestfs-tools
	chmod +r /boot/*

	# for demos and because we are not savages forced to use vi
	apt-get install -yqq tmux tcpdump device-tree-compiler nano
}

prj_setup() {
	# install rustup/cargo/rustc, latest version, no prompts
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	. ~/.cargo/env
	rustup target add aarch64-unknown-linux-gnu
	echo -e '[target.aarch64-unknown-linux-gnu]\nlinker = "aarch64-linux-gnu-gcc"' >>~/.cargo/config.toml
}

prj_build() {
	items=("$@")
	if [ -z "${items[0]}" ]; then
		items=( "all" )
	fi

	for item in "${items[@]}"; do
		item=${item//-/_}
		case $item in
		demo*)
			(./$item)
			;;
		*)
			(build_${item})
			;;
		esac
	done
	echo "****** Done"
}

build_all() {
	(build_xen)
	(build_xen_vhost_frontend)
	(build_vhost_device)
	(build_linux)
	(build_qemu)
	(build_qemu_cross)
	(build_devmem2)
	(build_u_boot)
	(build_disk)
}

# Common part of qemu builds
# Argumenets
# * name
# ENV
# * URL
# * COMMIT
# * BRANCH
# * EXTRA_CONFIG
xen_common() {
	NAME=$1

	mkdir -p build

	if [ ! -d xen.git ]; then
		git clone --bare https://github.com/xen-project/xen.git
	fi
	if [ ! -d $NAME ]; then
		cd xen.git
		git remote rm $NAME >/dev/null 2>&1 || true
		git remote add $NAME $URL
		git fetch $NAME
		git worktree prune
		if [ -n "$BRANCH" ]; then
			git worktree add ../$NAME $NAME/$BRANCH
		elif [ -n "$TAG" ]; then
			git worktree add ../$NAME $TAG
		else
			echo "for $NAME, must define BRANCH or TAG"
		fi
		cd ../$NAME
		if [ -n "$COMMIT" ]; then
			git reset --hard $COMMIT
		fi
		if [ -n "$EXTRA_CONFIG" ]; then
			CF=xen/arch/arm/configs/arm64_defconfig
			echo -e "$EXTRA_CONFIG" >>$CF
		fi
	else
		cd $NAME
	fi

	git clean -fdX
	./configure --libdir=/usr/lib \
	    --build=x86_64-unknown-linux-gnu --host=aarch64-linux-gnu \
	    --disable-docs --disable-golang --disable-ocamltools \
	    --with-system-qemu=/opt/qemu/bin/qemu-system-i386
	make -j9 debball CROSS_COMPILE=aarch64-linux-gnu- XEN_TARGET_ARCH=arm64

	# symlink for run command
	ln -fs ../$NAME/dist/install/boot/xen ../build/$NAME

	# symlink to deb package for install
	XEN_DEB=$(cd dist; ls -1 xen-*.deb)
	ln -fs ../$NAME/dist/$XEN_DEB ../build/$NAME.deb
}

build_xen_upstream() {
	URL=https://github.com/xen-project/xen.git
	TAG=RELEASE-4.19.0
	BRANCH=""
	COMMIT=""
	EXTRA_CONFIG=""\
"CONFIG_IOREQ_SERVER=y\n"\
"CONFIG_EXPERT=y\n"\
"CONFIG_TESTS=y\n"
	xen_common xen-upstream
}

build_xen_virtio_msg() {
	URL=https://github.com/edgarigl/xen.git
	BRANCH=edgar/virtio-msg
	COMMIT=""
	EXTRA_CONFIG=""
	xen_common xen-virtio-msg
}

build_xen_orko() {
	URL=https://github.com/vireshk/xen
	BRANCH=master
	COMMIT="35f3afc42910c7cc6d7cd7083eb0bbdc7b4da406"
	EXTRA_CONFIG=""
	xen_common xen-orko
}

# fallback target to build all xen versions
build_xen() {
	(build_xen_upstream)
	(build_xen_virtio_msg)
	(build_xen_orko)
}

build_rust() {
	(build_xen_vhost_frontend)
	(build_vhost_device)
}

build_xen_vhost_frontend() {
	echo "****** Build xen-vhost-frontend"
	mkdir -p build
	if [ ! -d xen-vhost-frontend ]; then
		git clone https://github.com/vireshk/xen-vhost-frontend
		cd xen-vhost-frontend
		git checkout virtio-msg
		#git reset --hard de22910cf2d8ff088d7d560b73d93f9121c832cf

		# Xen 4.19 support pending in PR #1
		# https://github.com/mathieupoirier/xen-sys/pull/1
		# https://github.com/epilys/xen-sys/commits/feature/add-domctl-interface-version-features/
		sed -i -e 's#'\
'{ git = "https://github.com/mathieupoirier/xen-sys" }#'\
'{ git = "https://github.com/epilys/xen-sys.git", rev = "e711d67ff3a77df88a92f1f1b45bfd6ec59b3190" }#'\
		    Cargo.toml
	else
		cd xen-vhost-frontend
	fi
	. ~/.cargo/env
	cargo build --release --all-features \
		--target aarch64-unknown-linux-gnu
	ln -fs ../xen-vhost-frontend/target/aarch64-unknown-linux-gnu/release/xen-vhost-frontend ../build/
}

build_vhost_device() {
	echo "****** Build vhost-device"
	mkdir -p build
	if [ ! -d vhost-device ]; then
		git clone https://github.com/rust-vmm/vhost-device
		cd vhost-device
		#git reset --hard 079d9024be604135ca2016e2bc63e55c013bea39
	else
		cd vhost-device
	fi
	. ~/.cargo/env
	cargo build --bin vhost-device-i2c --release --all-features \
		--target aarch64-unknown-linux-gnu
	ln -fs ../vhost-device/target/aarch64-unknown-linux-gnu/release/vhost-device-i2c ../build/
}

build_linux() {
	echo "****** Build Linux"
	if [ ! -d linux ]; then
		git clone git://git.kernel.org/pub/scm/linux/kernel/git/vireshk/linux.git
		cd linux
		git checkout virtio/msg
		#git reset --hard 1e5e683a3d1aa8b584f279edd144b4b1d5aad45c
		cp ../mixins/linux/virtio-msg.config arch/arm64/configs
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

	make defconfig virtio-msg.config
	make -j10 Image modules dtbs

	rm -rf ../build/linux-install
	mkdir -p ../build/linux-install/boot
	mkdir -p ../build/linux-install/lib/modules
	KREL=$(make --no-print-directory kernelrelease)
	fakeroot make INSTALL_MOD_STRIP=1 install modules_install
	fakeroot make dtbs_install || true
	#fakeroot make firmware_install || true
	(cd $INSTALL_PATH_BASE;
	  mkdir -p lib/firmware;
	  mv modules-$KREL.tar.gz modules-$KREL.tar.gz.old >/dev/null 2>&1 || true;
	  fakeroot tar czvf modules-$KREL.tar.gz lib/modules/$KREL lib/firmware)

	# symlink for run command
	LINUX=$(cd ../build/linux-install/boot; ls -1 vmlinuz-*)
	echo "Symlinking to $LINUX"
	ln -fs  linux-install/boot/$LINUX ../build/Image
}

build_u_boot() {
	echo "****** Build U-boot (EL2)"
	if [ ! -d u-boot ]; then
		git clone https://github.com/u-boot/u-boot.git
		cd u-boot
		git checkout v2024.07
	else
		cd u-boot
	fi
	mkdir -p ../build/u-boot-el2
	export ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-
	export KBUILD_OUTPUT="$(cd ../build/u-boot-el2; pwd)"

	make qemu_arm64_defconfig
	make -j10

	# symlink for run command
	ln -fs  u-boot-el2/u-boot.bin ../build/u-boot-el2.bin
}

build_devmem2() {
	echo "****** Build devmem2 for arm64"
	if [ ! -d devmem2 ]; then
		git clone https://github.com/radii/devmem2.git
		cd devmem2
	else
		cd devmem2
	fi
	mkdir -p ../build/
	aarch64-linux-gnu-gcc devmem2.c -o ../build/devmem2
}

# all native build qemus
build_qemu() {
	(build_qemu_i2c)
	(build_qemu_msg)
	(build_qemu_ivshmem_flat)
}

# all cross build qemus
build_qemu_cross() {
	(build_qemu_xen_arm64)
	(build_qemu_msg_arm64)
}

# build all qemus
build_qemu_all() {
	(build_qemu)
	(build_qemu_cross)
}

# Common part of qemu builds
# Argumenets
# * name
# ENV
# * URL
# * COMMIT
# * BRANCH
# * EXTRA_CONFIG
# * TARGETS
qemu_common() {
	NAME=$1

	if [ ! -d qemu.git ]; then
		git clone --bare https://github.com/qemu/qemu.git
	fi
	if [ ! -d $NAME ]; then
		cd qemu.git
		git remote rm $NAME || true
		git remote add $NAME $URL
		git fetch $NAME
		git worktree prune
		if [ -n "$BRANCH" ]; then
			git worktree add ../$NAME $NAME/$BRANCH
		elif [ -n "$TAG" ]; then
			git worktree add ../$NAME $TAG
		else
			echo "for $NAME, must define BRANCH or TAG"
		fi
		cd ../$NAME
		if [ -n "$COMMIT" ]; then
			git reset --hard $COMMIT
		fi
		cd ..
	fi
	mkdir -p build/$NAME
	mkdir -p build/$NAME-install
	cd build/$NAME
	../../$NAME/configure \
		$EXTRA_CONFIG \
		--target-list="$TARGETS" \
		--prefix="$(cd ../$NAME-install; pwd)" \
		--enable-fdt --enable-slirp --enable-strip \
		--disable-docs \
		--disable-gtk --disable-opengl --disable-sdl \
		--disable-dbus-display --disable-virglrenderer \
		--disable-vte --disable-brlapi \
		--disable-alsa --disable-jack --disable-oss --disable-pa
	make -j10
	make install
}

build_qemu_i2c() {
	echo "****** Build qemu w/ virtio-i2c (host side for system emulation)"
	URL=https://github.com/vireshk/qemu
	COMMIT=b7890a2c3d6949e8f462bb3630d5b48ecae8239f
	BRANCH=master
	TARGETS="aarch64-softmmu"
	EXTRA_CONFIG=""
	qemu_common qemu-i2c
}

qemu_common_cross() {
	NAME=$1

	# first remove any existing version in case it has changed
	# also do this if we don't want any xen support
	# we pass --disable-xen in this case but just to make sure ...
	sudo apt-get purge -y xen-upstream:arm64 || true

	if [ -n "$XEN_DEB" ]; then
		if [ -f build/$XEN_DEB ]; then
			# we install the arm64 deb file to get the arm64 libraries
			sudo apt-get install -y ./build/$XEN_DEB
		else
			echo "Build $XEN_DEB first"
			exit 2
		fi
	fi

	qemu_common $NAME

	# make a tar file for easy install
	fakeroot tar cvzf ../$NAME.tar.gz -C ../${NAME}-install .
}

build_qemu_xen_arm64() {
	echo "****** Build qemu xen arm64 (target side for device model)"
	XEN_DEB=xen-upstream.deb

	# use upstream from tag
	URL=https://github.com/qemu/qemu.git
	COMMIT=""
	BRANCH=""
	TAG="v8.0.0"

	# but we need different config
	TARGETS="aarch64-softmmu,i386-softmmu"
	EXTRA_CONFIG="--cross-prefix=aarch64-linux-gnu- --enable-xen"
	qemu_common_cross qemu-xen-arm64
}

build_qemu_msg_arm64() {
	echo "****** Build qemu virtio-msg arm64 (target side)"
	XEN_DEB=""

	# use the same as virtio-msg
	URL=https://github.com/edgarigl/qemu.git
	COMMIT="84777d3bf17e4d2229593291398f095e3073b9cb"
	BRANCH="edgar/virtio-msg"

	# but we need different config
	TARGETS="aarch64-softmmu"
	EXTRA_CONFIG="--cross-prefix=aarch64-linux-gnu- --disable-xen"
	qemu_common_cross qemu-msg-arm64
}

build_qemu_msg() {
	echo "****** Build qemu w/ virtio-msg (host side for system emulation)"
	URL=https://github.com/edgarigl/qemu.git
	COMMIT="84777d3bf17e4d2229593291398f095e3073b9cb"
	BRANCH="edgar/virtio-msg"
	TARGETS="aarch64-softmmu"
	EXTRA_CONFIG=""
	qemu_common qemu-msg
}

build_qemu_ivshmem_flat() {
	echo "****** Build qemu w/ ivshmem-flat (host side for system emulation)"
	URL=https://github.com/gromero/qemu.git
	COMMIT=""
	BRANCH="ivshmem_rebased_on_v9_0_2"
	TARGETS="aarch64-softmmu"
	EXTRA_CONFIG=""
	qemu_common qemu-ivshmem-flat
}

disk_common_buildroot() {
	ORIG_CPIO=virtio_msg_rootfs.cpio
	URL_CPIO_BASE=http://people.linaro.org/~manos.pitsidianakis
	if [ ! -r build/disk/$ORIG_CPIO ]; then
		echo "****** Fetch original buildroot rootfs cpio image"
		mkdir -p build/disk
		(cd build/disk; wget $URL_CPIO_BASE/$ORIG_CPIO)
		# source is not compressed for some reason
		gzip <build/disk/$ORIG_CPIO >build/disk/$ORIG_CPIO.gz
	fi
}

disk_common_debian() {
	# make sure we have a copy of the upstream disk image
	ORIG_DISK=debian-12-nocloud-arm64.qcow2
	URL_BASE=https://cloud.debian.org/images/cloud/bookworm/latest
	if [ ! -r build/disk/$ORIG_DISK ]; then
		echo "****** Fetch original debian disk image"
		mkdir -p build/disk
		(cd build/disk; wget $URL_BASE/$ORIG_DISK)
	fi

	# now make a copy of the template and expand it
	BIG_DISK=debian-12-arm64-big.qcow2
	if [ ! -r build/disk/$BIG_DISK ]; then
		# side effect /dev/sda15 -> /dev/sda1 & /dev/sda1 -> /dev/sda2
		echo "****** resize debian disk image"
		qemu-img create -f qcow2 build/disk/debian-12-arm64-big.qcow2 10G
		virt-resize --expand /dev/sda1 \
			build/disk/$ORIG_DISK \
			build/disk/debian-12-arm64-big.qcow2
	fi
}

buildroot_mixins_common() {
	NAME=$1; shift
	disk_common_buildroot

	echo "****** Create composite cpio.gz image for $NAME"

	# our mixins for minimal & composite initrd cpio
	TOP=$PWD
	rm -rf build/mixins/$NAME || true
	mkdir -p build/mixins/$NAME
	for DIR in mixins/minimal "$@"; do
		cp -a $DIR/. build/mixins/$NAME
	done
	(cd build/mixins/$NAME; find . | fakeroot cpio -H newc -o 2>/dev/null |
		gzip >$TOP/build/mixins-$NAME.cpio.gz)

	# build the composite even if not everyone will use it
	cat build/disk/$ORIG_CPIO.gz \
		build/mixins-$NAME.cpio.gz \
		>build/$NAME-rootfs.cpio.gz
}

debian_mixins_common() {
	NAME=$1; shift

	echo "****** Create $NAME-mixins.tar.gz"
	TOP=$PWD
	rm -rf build/mixins/$NAME || true
	mkdir -p build/mixins/$NAME
	for DIR in mixins/debian "$@"; do
		cp -a $DIR/. build/mixins/$NAME
	done

	# our mixins for debian
	fakeroot tar czf build/mixins-$NAME.tar.gz -C build/mixins/$NAME .
}

build_disk_demo1_guest() {
	buildroot_mixins_common demo1 demo1.d/mixins/qemu1-guest
}

build_disk_demo2a() {
	buildroot_mixins_common demo2a demo2a.d/mixins/qemu2
}

build_disk_demo2b() {
	buildroot_mixins_common demo2b-kvm demo2b.d/mixins/qemu2-guest{,-kvm}
	buildroot_mixins_common demo2b-xen demo2b.d/mixins/qemu2-guest
}

build_disk_debian_mixins() {
	debian_mixins_common debian \
		demo1.d/mixins/debian \
		demo2b.d/mixins/debian

}

build_disk_debian() {
	disk_common_debian
	disk_common_buildroot
	(build_disk_demo1_guest)
	(build_disk_demo2b)
	(build_disk_debian_mixins)

	echo "****** Modify a disk image copy for debian based demos"
	rm -f build/demo*-disk.qcow2
	rm -f build/disk.qcow2

	# now make a copy of the (expanded) template
	cp build/disk/$BIG_DISK build/disk.qcow2

	# collect the stuff we need to add
	MODULES_TAR=$(ls -1 build/linux-install/modules-*.tar.gz)
	guestfish --rw -a build/disk.qcow2 <<EOF
run
mount /dev/sda2 /
mkdir /opt/qemu-xen
mkdir /opt/qemu-msg
tar-in $MODULES_TAR / compress:gzip
tar-in build/qemu-xen-arm64.tar.gz /opt/qemu-xen compress:gzip
tar-in build/qemu-msg-arm64.tar.gz /opt/qemu-msg compress:gzip
tar-in build/mixins-debian.tar.gz / compress:gzip
upload build/vhost-device-i2c /root/vhost-device-i2c
upload build/xen-vhost-frontend /root/xen-vhost-frontend
upload build/xen-upstream.deb /root/xen-upstream.deb
upload build/xen-virtio-msg.deb /root/xen-virt-msg.deb
upload build/devmem2 /root/devmem2
upload build/demo1-rootfs.cpio.gz  /root/demo1-rootfs.cpio.gz
upload build/demo2b-kvm-rootfs.cpio.gz /root/demo2b-kvm-rootfs.cpio.gz
upload build/demo2b-xen-rootfs.cpio.gz /root/demo2b-xen-rootfs.cpio.gz
upload build/Image /root/Image
EOF
}

build_disk() {
	(build_disk_debian)
	(build_disk_demo2a)
}

CMD=${1//-/_}; shift

case $CMD in
admin_setup|prj_setup|prj_build|container_main|do_once)
	$CMD "$@"
	;;
build_*)
	($CMD "$@")
	;;
*)
	echo "Unknown prj_script command $CMD"
	exit 2
	;;
esac
