#/bin/bash

MY_DIR=$(dirname $0)

set -e

fail() {
	echo "***** TEST FAILED, " "$@"
	exit 2
}

one_test() {
	NUM=$1

	modprobe virtio_msg_ivshmem \
		|| fail "can't install module virtio-msg-ivshmem (test $NUM)"

	# wait for things to happen
	sleep 1

	rmmod virtio_msg_ivshmem \
		|| fail "can't remove module virtio-msg-ivshmem (test $NUM)"

	# this is destructive but busybox dmesg does not have the fancy options
	dmesg -c >dmesg-test-$NUM.log

	grep "virtio_msg_ivshmem .* IRQ fired" \
		dmesg-test-$NUM.log  >/dev/null || \
		fail "IRQ did not fire (test $NUM)"
	grep "virtio_msg_ivshmem .* Data ok." \
		dmesg-test-$NUM.log  >/dev/null || \
		fail "Data check did not pass (test $NUM)"
	grep "virtio_msg_ivshmem .* probe successful" \
		dmesg-test-$NUM.log  >/dev/null || \
		fail "module probe did not work (test $NUM)"
	grep "virtio_msg_ivshmem .* device removed" \
		dmesg-test-$NUM.log  >/dev/null || \
		fail "device was not removed (test $NUM)"
}

# save the boot log as the tests will read and clear dmesg
dmesg -c >dmesg-boot.log

for i in $(seq 3); do
	one_test $i
	sleep 2
done

# if we get here, we have passed
echo "***** TEST PASSED, virtio-msg-ivshmem module test passed"
