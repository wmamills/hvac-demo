# to be sourced, not run

# turn on command tracing if the DEBUG environment is set
if [ -n "$DEBUG" ]; then
	set -x
fi

# if we are run by multi-qemu these should be set already
# if not set some defaults
: ${TEST_DIR:=$(cd $MY_DIR/.. ; pwd)}
: ${BASE_DIR:=$(cd $MY_DIR/../.. ; pwd)}}
: ${LOGS:=$BASE_DIR/logs}
: ${TMPDIR:=.}
: ${IMAGES:=$BASE_DIR/images}
: ${BUILD:=$BASE_DIR/build}

FETCH=$BASE_DIR/scripts/maybe-fetch
CHK_BUILD=check_build_disk
HOST_ARCH=$(uname -m )

declare -A DISK_TARGETS

# debian_base disk is requiered for all debian based demos
DISK_TARGETS[disk.qcow2]=disk_debian

error() {
	echo "ERROR: " "$@"
	exit 2
}

check_build_disk() {
	for f in $@; do
		if [ ! -e ${BUILD}/${f} ]; then
			BUILD_TARGET=${DISK_TARGETS[$f]}
			if [ -z $BUILD_TARGET ]; then
				error "Build target for file $f not defined"
			fi

			if ! $BASE_DIR/Build $BUILD_TARGET; then
				error "Failed to build $BUILD_TARGET"
			fi

			if [ ! -e ${BUILD}/${f} ]; then
				error "build of $BUILD_TARGET ok but $f not found"
			fi
		fi
	done
}

copy_debian_disk() {
	check_build_disk disk.qcow2
	for NAME in $@; do
		if [ ! -e ${BUILD}/${NAME}-disk.qcow2 ]; then
			echo "make a copy of the debian disk image for $NAME"
			cp ${BUILD}/disk.qcow2 $BUILD/${NAME}-disk.qcow2
		fi
	done
}

common_cleanup() {
	# clean up the memory files
	rm -f ./qemu-xen-vm?-ram ./qemu-vm?-ram ./qemu-ram* || true
	rm -f ./qemu-xen-vm?-ram ./qemu-vm?-ram || true

	# kill and cleanup any shared memory server
	for f in shm*.pid; do
		if [ -e $f ]; then
			kill $(cat shm.pid) || true
			rm -f shm.pid || true
		fi
	done
	rm -f shm*.sock || true
}

print_results() {
	if [ -r $LOGS/net.pcap ]; then
		tcpdump -r $LOGS/net.pcap
	fi

	for NAME in "$@"; do
		if [ -r $LOGS/$NAME-log.txt ]; then
			grep "^\*\*\*\*\* TEST" $LOGS/$NAME-log.txt || true
		else
			echo "No log for $NAME"
		fi
	done
}
