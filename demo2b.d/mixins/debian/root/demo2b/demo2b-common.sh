# to be included not executed

set -e

install_common() {
	if [ -e ~/.done/install-common.done ]; then
		return 0
	fi

	echo "Installing basic packages ..."
	chmod +x ./devmem2
	apt-get update -qq
	apt-get install -qqy procps nano

	mkdir -p ~/.done
	touch ~/.done/install-common.done
}

install_qemu_deps() {
	if [ -e ~/.done/qemu-install.done ]; then
		return 0
	fi

	echo "Installing packages for qemu ..."
	apt-get install -qqy libfdt1 libpixman-1-0 libslirp0 $BASIC_PACKAGES

	echo "Installing packages done"
	mkdir -p ~/.done
	touch ~/.done/qemu-install.done
}

install_xen() {
	XEN_NAME=$1
	QEMU_NAME=$2

	if [ -e ~/.done/${XEN_NAME}-install.done ]; then
		return 0
	fi

	echo "Installing packages for xen ..."
	apt-get install -qqy libyajl2 zlib1g libfdt1 libncurses5 \
		libzstd1 libuuid1
	apt-get install ./${XEN_NAME}.deb

	# use /opt/qemu-xen as /opt/qemu
	ln -fs -T $QEMU_NAME /opt/qemu

	dd if=/dev/zero of=~/dummy.img bs=1M count=5

	touch ~/.done/${XEN_NAME}-install.done
}

vfio_setup() {
	# this needs to run once per boot
	# /run is volatile and does not persist from boot to boot
	if [ -e /run/vfio-setup.done ]; then
		return 0
	fi

	echo "Per boot vfio setup ..."
	echo 1 >/sys/module/vfio/parameters/enable_unsafe_noiommu_mode

	# needed for Xen
	echo 1 >/sys/module/vfio_iommu_type1/parameters/allow_unsafe_interrupts

	# now tell the kernel to let vfio-pci handle the ivshmem pci cards
	echo 1af4 1110 >/sys/bus/pci/drivers/vfio-pci/new_id

	touch /run/vfio-setup.done
}

xen_startup() {
	# This needs to run once per dom0 boot
	# /run is volatile and does not persist from boot to boot
	if [ -e /run/xen_startup.done ]; then
		return 0
	fi

	# start the xen daemons
	/etc/init.d/xencommons start

	touch /run/xen_startup.done
}

# use the first word of the last 16 bytes of the shared 1M memory
# anything not READY is not ready, the memory will start as 0s
READY=0x42
NOT_READY=0x24
READY_ADDR=0x804003FFF0

mark_ready() {
	chmod +x ./devmem2
	./devmem2 $READY_ADDR w $READY
}

mark_not_ready() {
	chmod +x ./devmem2
	./devmem2 $READY_ADDR w $NOT_READY
}

read_ready() {
	./devmem2 $READY_ADDR w | tail -n 1 | sed -e 's/^.*: //'
}

wait_ready() {
	TIMEOUT=${1:-300}
	for  i in $(seq $TIMEOUT); do
		VAL=$(read_ready)
		if [  "$VAL" == "$READY" ]; then
			true
			return
		elif [  "$VAL" == "$NOT_READY" ]; then
			echo -n "*"
		else
			echo -n "."
		fi
		sleep 1
	done
	false
}

wait_ready_seq() {
	echo "Wait for other qemu to be ready"
	wait_ready
	echo; echo "Now wait a bit more"
	sleep 5
	echo; echo "OK"
}