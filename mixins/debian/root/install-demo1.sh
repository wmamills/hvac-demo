#/bin/sh
# needed by xen xl tool stack and qemu-system-i386
set -e 

if [ -e install.done ]; then
	exit 0
fi

echo "Installing packages ..."
apt-get update -qq
apt-get install -qqy procps nano
apt-get install -qqy libyajl2 zlib1g libfdt1 libncurses5 libzstd1 libuuid1 \
    libpixman-1-0 libslirp0
apt-get install ./xen-upstream.deb

# use /opt/qemu-xen as /opt/qemu
ln -fs -T qemu-xen /opt/qemu

chmod +x vhost-device-* xen-vhost-frontend

echo "Installing packages done"
touch install.done
