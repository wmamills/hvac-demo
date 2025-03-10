#!/bin/sh

get_cmdline_arg() {
	PARAM=$1
	DEF_VALUE=$2

	# sed, like perl, is a write only language
	# first we grep for the param= to make sure it is there as the sed line
	# won't work if it is not
	# then the sed line uses # as the s command delimiter
	# ^.* matches from the start of line until the PARAM= part
	# $PARM= matches the parameter name and the equal sign
	# \\ is needed for each \ as we have used double quotes to get $PARAM
	# \( and later \) make a group of the value part
	# [^[:space:]])* is the value match part that is group 1
	#    it matches any number of characters up to the next whitespace
	# .*$ matches anything till the end of string
	# \$ is needed because of the double quotes
	# The replacement says
	#    replace everything we matched (the whole line)
	#    with group 1 (the VALUE)
	if grep -q "$PARAM=" /proc/cmdline; then
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
AUTOPOWEROFF=$(get_cmdline_arg autopoweroff "yes")
AUTORUN_TTY=$(get_cmdline_arg autorun_tty "")
PRIME_CONSOLE=$(cat /proc/consoles | cut -d" " -f 1 | head -n 1)

MY_TTY=$(tty)
MY_TTY=${MY_TTY#/dev/}

if [ -n "$AUTORUN_TTY" ]; then
	if [ "$MY_TTY" != $AUTORUN_TTY ]; then
		exit 0
	fi
else
	if [ "$MY_TTY" != $PRIME_CONSOLE ]; then
		exit 0
	fi
fi

echo "/proc/cmdline: $(cat /proc/cmdline)"
echo "MY_TTY=$MY_TTY AUTORUN_TTY=$AUTORUN_TTY PRIME_CONSOLE=$PRIME_CONSOLE"
echo "AUTORUN=$AUTORUN AUTORUN_DELAY=$AUTORUN_DELAY AUTOPOWEROFF=$AUTOPOWEROFF"

if [ -z "$AUTORUN" ]; then
	exit
fi

if [ -x "$AUTORUN" ]; then
    echo "To stop autorun, hit ctrl-c in the next $AUTORUN_DELAY seconds"
    delay $AUTORUN_DELAY

    "$AUTORUN"
else
    echo "$AUTORUN does not exist or is not executable"
    # for debug, uncomment the below, for CI leave commented
    # exit
    AUTORUN_DELAY=30
fi

case $AUTOPOWEROFF in
on|ON|yes|YES|y|Y|"")
	true
	;;
off|OFF|no|NO|n|N)
	exit
	;;
0*|1*|2*|3*|4*|5*|6*|7*|8*|9*|0*)
	AUTORUN_DELAY=$(( $AUTOPOWEROFF + 0 ))
	;;
esac

echo "To stop poweroff, hit ctrl-c in the next $AUTORUN_DELAY seconds"
delay $AUTORUN_DELAY

echo "minimal poweroff"
poweroff
