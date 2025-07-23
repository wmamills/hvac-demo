#/bin/sh
set -e

if [ -e ~/.done/install-demo-loopback.done ]; then
	exit 0
fi

echo "Installing packages ..."
apt-get update -qq
apt-get install -qqy procps nano

chmod +x lb-vhost-device-* lb-vhost-frontend virtio-msg-loopback

echo "Installing packages done"
mkdir -p ~/.done
touch ~/.done/install-demo-loopback.done
