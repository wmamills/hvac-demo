# do the autorun script if it exists and we are on the main terminal
# note: /dev/console is normally write only
#    so you won't be able to stop the countdown
if [ -x ~/autorun.sh ]; then
	MY_TTY=$(tty)
	case $MY_TTY in
	"/dev/hvc0"|"/dev/ttyAMA0"|"/dev/console")
		~/autorun.sh
		;;
	*)
		true
		;;
	esac
fi
