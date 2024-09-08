#!/bin/bash

START_TIME=5
STOP_TIME=10

delay() {
	DELAY=$1
	for i in $(seq $DELAY -1 0); do
		echo -ne "$i \r"
		sleep 1
	done
}

echo "To stop autorun, hit ctrl-c in the next $START_TIME seconds"
delay $START_TIME

./install.sh
./demo1.sh

echo "To stop poweroff, hit ctrl-c in the next $STOP_TIME seconds"
delay $STOP_TIME

poweroff
