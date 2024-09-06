#/bin/sh

set -e 

# start the xen daemons
/etc/init.d/xencommons start

# should only show Domain-0
xl list

# inform i2c controller of device but don't bind a driver
echo ds1338 0x20 > /sys/bus/i2c/devices/i2c-0/new_device
echo 0-0020 > /sys/bus/i2c/devices/0-0020/driver/unbind

# start the i2c backend
./vhost-device-i2c -s /root/i2c.sock -c 1 -l "90c0000.i2c:32" &
./xen-vhost-frontend --socket-path /root/ &

# now start the quest
xl create -c domu.conf
