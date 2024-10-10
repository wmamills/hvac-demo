#/bin/bash

MY_DIR=$(dirname $0)

set -e

fail() {
	echo "***** TEST FAILED, " "$@"
}

chmod +x uio_ivshmem_test || fail "can't make uio_ivshmem_test executable"

test -c /dev/uio0 || fail no uio0 device
test -e /sys/class/uio/uio0/maps/map0/name || fail no sysfs for map0
test -e /sys/class/uio/uio0/maps/map1/name || fail no sysfs for map1
cat /sys/class/uio/uio0/maps/map*/name

for i in $(seq 1 3); do
	./uio_ivshmem_test /dev/uio0 0 || fail ivshmem_test failed
done

echo "***** TEST PASSED, uio ivshmem test passed"
