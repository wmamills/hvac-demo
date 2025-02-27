#/bin/bash

MY_DIR=$(dirname $0)
ETH=eth1

set -e

fail() {
	echo "***** TEST FAILED, " "$@"
	exit 2
}

test_rng() {
	dd if=/dev/hwrng of=data.bin bs=512 count=1 || \
		fail "can't read hwrng"

	od -x data.bin
}

test_net() {
	ifconfig -a
	ifconfig $ETH up || \
		fail "can't bring $ETH up"
	ifconfig $ETH inet 10.0.2.15 || \
		fail "can't assign IP to $ETH"
	ping -c 3 10.0.2.2 || \
		fail "can't ping host via $ETH"
}

test_dev_type() {
	case $1 in
	"0x0001")
		test_net
		;;
	"0x0004")
		test_rng
		;;
	"")
		fail "virtio1 does not have a device type"
		;;
	*)
		fail "virtio1 has unknown device type $1"
		;;
	esac
}

one_test() {
	NUM=$1

	modprobe virtio_msg_ivshmem \
		|| fail "can't install module virtio-msg-ivshmem (test $NUM)"

	# wait for things to happen
	sleep 2

	# this is destructive but busybox dmesg does not have the fancy options
	dmesg -c >dmesg-test-$NUM-start.log

	grep "virtio_msg_ivshmem .* probe successful" \
		dmesg-test-$NUM-start.log  >/dev/null || \
		fail "module probe did not work (test $NUM)"

	#grep "virtio_msg_ivshmem .* IRQ fired" \
	#	dmesg-test-$NUM-start.log  >/dev/null || \
	#	fail "IRQ did not fire (test $NUM)"
	grep "virtio_msg_ivshmem .* RX MSG: " \
		dmesg-test-$NUM-start.log  >/dev/null || \
		fail "IRQ did not fire (test $NUM)"

	test -f /sys/bus/virtio/devices/virtio1/device || \
		fail "virtio1 not found"

	DEVICE=$(cat /sys/bus/virtio/devices/virtio1/device)
	test_dev_type $DEVICE

	# this is destructive but busybox dmesg does not have the fancy options
	dmesg -c >dmesg-test-$NUM-xfer.log

	rmmod virtio_msg_ivshmem \
		|| fail "can't remove module virtio-msg-ivshmem (test $NUM)"

	# this is destructive but busybox dmesg does not have the fancy options
	dmesg -c >dmesg-test-$NUM-end.log

	grep "virtio_msg_ivshmem .* device removed" \
		dmesg-test-$NUM-end.log  >/dev/null || \
		fail "device was not removed (test $NUM)"
}

# use the first word of the last 16 bytes of the shared 1M memory
# anything not READY is not ready, the memory will start as 0s
READY=0x42
NOT_READY=0x24
READY_ADDR=0x800003FFF0

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
	echo "OK"
}

# save the boot log as the tests will read and clear dmesg
dmesg -c >dmesg-boot.log

# wait for the other side to be ready
wait_ready_seq

for i in $(seq 3); do
	one_test $i
	sleep 2
done

# if we get here, we have passed
echo "***** TEST PASSED, virtio-msg-ivshmem module test passed"
