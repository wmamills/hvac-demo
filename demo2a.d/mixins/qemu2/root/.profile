# do the autorun script if it exits and we are on the main terminal
if [ -x ~/autorun.sh -a $(tty) == "/dev/ttyAMA0" ]; then
    ~/autorun.sh
fi
