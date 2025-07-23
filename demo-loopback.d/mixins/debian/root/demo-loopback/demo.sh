#/bin/sh

MY_DIR=$(dirname $0)

set -e

test -c /dev/i2c-0

$MY_DIR/install.sh

# once per boot
# /run is volatile and does not persist from boot to boot
if [ ! -e /run/demo-loopback-setup.done ]; then
	# inform i2c controller of device but don't bind a driver
	echo ds1338 0x20 > /sys/bus/i2c/devices/i2c-0/new_device
	echo 0-0020 > /sys/bus/i2c/devices/0-0020/driver/unbind

	touch /run/demo-loopback-setup.done
fi

# start the i2c backend
RUST_BACKTRACE=full ./lb-vhost-device-i2c -s /root/i2c.sock -c 1 -l "90c0000.i2c:32" &
RUST_BACKTRACE=full ./lb-vhost-frontend --socket-path /root/ &

# create the I2C device using the loopback utility
./virtio-msg-loopback

sleep 2

# Create a device on the new I2C bus
echo ds1338 0x20 > /sys/bus/i2c/devices/i2c-1/new_device

if [ ! -e /dev/rtc1 ]; then
	echo "***** TEST FAILED, no /dev/rtc1"
fi

if ! hwclock; then
	echo "***** TEST FAILED, can't run hwclock"
else
	echo "***** TEST PASSED, hwclock worked"
fi

# kill all jobs of this shell (hopefully just the two backend processes)
kill $(jobs -p)
