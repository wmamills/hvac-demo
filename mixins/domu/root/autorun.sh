#!/bin/sh

get_cmdline_arg() {
    PARAM=$1
    DEF_VALUE=$2

    if grep -q $PARAM /proc/cmdline; then
        VALUE=$(sed -e "s#^.*$PARAM=\\([^[:space:]]*\\).*\$#\\1#" /proc/cmdline)
        if [ -n $VALUE ]; then
            echo $VALUE
            return
        fi
    fi
    echo $DEF_VALUE
}

delay() {
	DELAY=$1
	for i in $(seq $DELAY -1 0); do
		echo -ne "$i \r"
		sleep 1
	done
}

AUTORUN=$(get_cmdline_arg autorun "")
AUTORUN_DELAY=$(get_cmdline_arg autorun_delay 5)

echo "/proc/cmdline: $(cat /proc/cmdline)"
echo "AUTORUN=$AUTORUN AUTORUN_DELAY=$AUTORUN_DELAY"

if [ -z "$AUTORUN" ]; then
    exit
fi

echo "To stop autorun, hit ctrl-c in the next $AUTORUN_DELAY seconds"
delay $AUTORUN_DELAY

"$AUTORUN"

echo "To stop poweroff, hit ctrl-c in the next $AUTORUN_DELAY seconds"
delay $AUTORUN_DELAY

echo "busybox poweroff"
poweroff
