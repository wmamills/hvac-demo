#/bin/bash

MY_DIR=$(dirname $0)

set -e

fail() {
	echo "***** TEST FAILED, " "$@"
	exit 2
}

modprobe virtio-msg-ivshmem || fail "can't install module virtio-msg-ivshmem"

dmesg | grep "virtio_msg_ivshmem .* IRQ fired" >/dev/null || \
	fail "IRQ did not fire"
dmesg | grep "virtio_msg_ivshmem .* Data ok." >/dev/null || \
	fail "Data check did not pass"
dmesg | grep "virtio_msg_ivshmem .* probe successful" >/dev/null || \
	fail "module probe did not work"

# if we get here, we have passed
echo "***** TEST PASSED, virtio-msg-ivshmem module test passed"
