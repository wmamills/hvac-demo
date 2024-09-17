# do the autorun script if it exits and we are on the main terminal
if [ -x ~/autorun.sh ]; then
    MY_TTY=$(tty)
    if [ $MY_TTY == "/dev/hvc0" -o $MY_TTY == "/dev/ttyAMA0" ]; then
        ~/autorun.sh
    fi
fi
