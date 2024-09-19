# do the autorun script if it exits and we are on the main terminal
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
