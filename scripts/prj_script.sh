#!/bin/bash

MY_DIR=$(cd $(dirname $0); pwd)

# exit on error
set -e

admin_setup() {
	dpkg --add-architecture arm64
	apt-get update -qq
	# for xen (basic) and kernel build
	apt-get install -yqq build-essential git git-lfs bison flex wget curl pv \
	    bc libssl-dev libncurses-dev kmod python3 python3-setuptools iasl
	# for cross-build
	apt-get install -yqq gcc-aarch64-linux-gnu uuid-dev:arm64 libzstd-dev:arm64 \
	    libncurses-dev:arm64 libyajl-dev:arm64 zlib1g-dev:arm64 \
	    libfdt-dev:arm64 libpython3-dev:arm64 gdb-multiarch
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
	apt-get install -yqq tmux tcpdump device-tree-compiler nano net-tools
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
		all|clean*)
			(build_${item})
			;;
		uio_ivshmem_test|devmem2)
			$MY_DIR/build/util $item
			;;
		xen_vhost_frontend|vhost_device)
			$MY_DIR/build/rust $item
			;;
		*)
			if [ -e $MY_DIR/build/$item ]; then
				$MY_DIR/build/$item
			else
				FIRST_PART=${item%%_*}
				if [ -e $MY_DIR/build/$FIRST_ITEM ]; then
					$MY_DIR/build/$FIRST_PART $item
				else
					echo "Unknown build item $item"
					exit 2
				fi
			fi
			;;
		esac
	done
	echo "****** Done"
}

build_all() {
	for item in rust util xen qemu linux u_boot zephyr disk; do
		$MY_DIR/build/$item
	done
}

build_clean() {
	rm -rf build
	for d in xen-orko xen-upstream xen-virtio-msg; do
		if [ -d src/$d ]; then
			(cd src/$d; git clean -fdX)
		fi
	done
}

build_clean_src() {
	rm -rf src
	build_clean
}

build_clean_src_all() {
	build_clean_src
	rm -rf src-ref
}

CMD=${1//-/_}; shift

case $CMD in
admin_setup|prj_setup|prj_build)
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
