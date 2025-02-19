# This file is sourced not executed

# exit on error
set -e

# Common part of cloning via a reference git
# Argumenets
# * upstream reference name
# * upstream reference url
# * name of this worktree
# ENV
# * URL
# * COMMIT
# * BRANCH
# returns
#	true for a new clone
#	false otherwise
worktree_common() {
	local REF_NAME=$1
	local REF_URL=$2
	local FULLNAME=$3
	local NAME=$(basename $FULLNAME)
	local ORIG_DIR=$PWD

	if [ ! -d src-ref/$REF_NAME.git ]; then
		mkdir -p src-ref
		(cd src-ref; git clone --bare $REF_URL $REF_NAME.git)
	fi
	if [ ! -e src/$FULLNAME/.git ]; then
		mkdir -p src/$FULLNAME
		cd src-ref/$REF_NAME.git
		git remote rm $NAME >/dev/null 2>&1 || true
		git remote add $NAME $URL
		git fetch $NAME
		git worktree prune
		if [ -n "$BRANCH" ]; then
			git worktree add ../../src/$FULLNAME $NAME/$BRANCH
		elif [ -n "$TAG" ]; then
			# make sure we have the tag
			git fetch $NAME +refs/tags/$TAG:refs/tags/$TAG
			git worktree add ../../src/$FULLNAME $TAG
		else
			echo "for $NAME, must define BRANCH or TAG"
		fi
		cd ../../src/$FULLNAME
		sed -i -e 's#^gitdir: /prj/#gitdir: ../../#' .git
		if [ -n "$COMMIT" ]; then
			git reset --hard $COMMIT
		fi
		if [ -n "$PATCH" ]; then
			git apply $PATCH
		fi
		cd $ORIG_DIR
		true
	else
		false
	fi
}

main() {
	BASE_DIR=$(cd $MY_DIR/../.. ; pwd)
	FETCH=$BASE_DIR/scripts/maybe-fetch

	# The demos will call the build from their own test dir so make sure
	# we start in the base dir
	cd $BASE_DIR

	# are we in build mode or fetch mode?
	MODE=fetch

	case $1 in
	--fetch)
		MODE=fetch
		shift
		;;
	--build)
		MODE=build
		shift
		;;
	--*)
		echo "Bad option $1"
		exit 2
		;;
	esac

	SCRIPT=$(basename $0)
	CMD=${1//-/_}
	if [ -z "$CMD" ]; then
		build_${SCRIPT}
	else
		build_${CMD}
	fi
}