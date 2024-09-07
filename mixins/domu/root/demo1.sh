#!/bin/sh

# create the new virtio i2c device
echo ds1338 0x20 > /sys/bus/i2c/devices/i2c-0/new_device

sleep 2

if [ ! -e /dev/rtc0 ]; then
	echo "***** TEST FAILED, no /dev/rtc0"
fi

if ! hwclock; then
	echo "***** TEST FAILED, can't run hwclock"
else
	echo "***** TEST PASSED, hwclock worked"
fi

echo "Hit Ctrl-C now to stop auto poweroff of this domu"
sleep 10

poweroff


