#!/bin/bash

set -e
#set -x

ME=$0
MY_NAME=$(basename $ME)

UBUNTU_VER=24.04

# Saved image name
NAME=hvac-demo
UPSTREAM_URL=https://github.com/wmamills/${NAME}.git
PERSONAL_URL=https://github.com/wmamills/${NAME}.git

DOCKER_HUB_ACCOUNT=wmills

ARCH_LIST="x86_64 aarch64"
CONTAINER_LIST="hvac-demo"
SAVE_PATH=build/docker-images
REMOTE_BASE=remote-build-jobs

# in Gigabytes
DISK_SIZE="60"
MEM_SIZE="16"

JOB_NAME1=${NAME}-docker-build
JOB_DATE=$(date +%Y-%m-%d-%H%M%S)
JOB_NAME=${JOB_NAME1}-${JOB_DATE}
REMOTE_DIR=$REMOTE_BASE/$JOB_NAME

# arguments to pass to sub-jobs
ARGS=""

PUSH=false
PULL=false
STOP=false
LOAD=false
SAVE=false
BUILD=true
MANIFEST=false
REMOTE_JOB=false
LITE_BUILD=false

set_bool() {
    case $1 in
    ""|"yes"|"true"|y*|Y*|t*|T*)
        echo "true"
        ;;
    "no"|"false"|n*|N*|f*|F*)
        echo "false"
        ;;
    *)
        echo "Unknown bool setting $1" >&2
        exit 2
        ;;
    esac
}

for i in "$@"; do
    VAL=${i#*=}
    # if there is no =, VAL will be the whole name
    if [ "$VAL" == "$i" ]; then
        VAL=""
    fi
    case $i in
    # these 5 are always passed in ARGS
    BRANCH=*)
        BRANCH=$VAL
        ;;
    URL=*)
        URL=$VAL
        ;;
    VER=*)
        VER=$VAL
        ;;
    TAG=*)
        TAG=$VAL
        ;;
    JOB_NAME=*)
        JOB_NAME="$VAL"
        REMOTE_DIR=$REMOTE_BASE/$JOB_NAME
        ;;

    # expand ARGS for the rest
    DEST_TAG=*)
        DEST_TAG=$VAL
        ARGS="$ARGS $i"
        ;;
    REMOTE_BASE=*)
        REMOTE_BASE="$VAL"
        REMOTE_DIR=$REMOTE_BASE/$JOB_NAME
        ARGS="$ARGS $i"
        ;;
    push*)
        PUSH=$(set_bool $VAL)
        ARGS="$ARGS $i"
        : ${SAVE:=false}
        ;;
    save*)
        SAVE=$(set_bool $VAL)
        ARGS="$ARGS $i"
        ;;
    pull*)
        PULL=$(set_bool $VAL)
        ARGS="$ARGS $i"
        ;;
    load*)
        LOAD=$(set_bool $VAL)
        ARGS="$ARGS $i"
        ;;
    manifest*)
        MANIFEST=$(set_bool $VAL)
        ARGS="$ARGS $i"
        ;;
    build*)
        BUILD=$(set_bool $VAL)
        ARGS="$ARGS $i"
        ;;
    remote-job*)
        REMOTE_JOB=$(set_bool $VAL)
        ARGS="$ARGS $i"
        ;;
    stop*)
        STOP=$(set_bool $VAL)
        ARGS="$ARGS $i"
        ;;
    lite-build*)
        LITE_BUILD=$(set_bool $VAL)
        ARGS="$ARGS $i"
        ;;
    esac
done

# if we have no tag at the top level command line,
# use current date and pass it along
if [ -z "$TAG" ]; then
    TAG=$(date +%Y-%m-%d)
fi

# top level only
if [ -e $(dirname $ME)/../.git ]; then
    CURRENT_BRANCH=$(git symbolic-ref HEAD)
    CURRENT_BRANCH=${CURRENT_BRANCH#refs/heads/}
else
    CURRENT_BRANCH=none
fi

# set defaults based on current branch
case $CURRENT_BRANCH in
wam-*|wip-*)
    : ${BRANCH:=$CURRENT_BRANCH}
    : ${URL:=$PERSONAL_URL}
    ;;
"none")
    : ${BRANCH:=main}
    : ${URL:=$UPSTREAM_URL}
    ;;
*)
    : ${BRANCH:=$CURRENT_BRANCH}
    : ${URL:=$UPSTREAM_URL}
    ;;
esac

ARGS="URL=$URL BRANCH=$BRANCH VER=$VER TAG=$TAG $ARGS JOB_NAME=$JOB_NAME"
echo "$@"

admin_setup() {
    echo "########## Admin setup (for user=$1)"
    apt-get update
    apt-get install -y git git-lfs docker.io make
    if [ -n "$1" ]; then
        adduser $1 docker
    fi
}

docker_arch() {
    case "$1" in
    aarch64)
        echo "arm64"
        ;;
    x86_64)
        echo "amd64"
        ;;
    *)
        echo "unknown"
        ;;
    esac
}

dead_code1() {
            docker tag $DOCKER_HUB_ACCOUNT/${c}:${OLD_TAG}-${DOCKER_ARCH} \
                $DOCKER_HUB_ACCOUNT/${c}:${TAG}-${DOCKER_ARCH}
}

image_exists() {
    docker image inspect $1 >/dev/null 2>&1
}

image_ops_output() {
    if $PUSH; then
        echo "########## Push"
        for a_host in $ARCH_LIST; do
            a=$(docker_arch $a_host)
            for c in $CONTAINER_LIST; do
                IMAGE_NAME=$DOCKER_HUB_ACCOUNT/${c}:${TAG}-${a}
                if image_exists $IMAGE_NAME; then
                    echo "push $IMAGE_NAME"
                    docker push $IMAGE_NAME
                else
                    echo "skip $IMAGE_NAME, no image found"
                fi
            done
        done
    fi

    if $SAVE; then
        echo "########## Save"
        mkdir -p $ORIG_PWD/$SAVE_PATH/$DOCKER_ARCH
        for a_host in $ARCH_LIST; do
            a=$(docker_arch $a_host)
            for c in $CONTAINER_LIST; do
                IMAGE_NAME=$DOCKER_HUB_ACCOUNT/${c}:${TAG}-${a}
                TARFILE=$ORIG_PWD/$SAVE_PATH/$a/${c}-${TAG}-${a}.tar.gz
                if image_exists $IMAGE_NAME; then
                    echo "save $IMAGE_NAME to $(basename $TARFILE)"
                    mkdir -p $(dirname $TARFILE)
                    docker image save $IMAGE_NAME | gzip >$TARFILE
                else
                    echo "skip $IMAGE_NAME, no image found"
                fi
            done
        done
    fi
}

image_ops_input() {
    if $PULL; then
        echo "########## Pull"
        for a_host in $ARCH_LIST; do
            a=$(docker_arch $a_host)
            for c in $CONTAINER_LIST; do
                IMAGE_NAME=$DOCKER_HUB_ACCOUNT/${c}:${TAG}-${a}
                docker pull $IMAGE_NAME
            done
        done
    elif $LOAD; then
        echo "########## Load"
        for a_host in $ARCH_LIST; do
            a=$(docker_arch $a_host)
            for c in $CONTAINER_LIST; do
                TARFILE=$ORIG_PWD/$SAVE_PATH/$a/${c}-${TAG}-${a}.tar.gz
                if [ -r "$TARFILE" ]; then
                    echo "load $(basename $TARFILE)"
                    zcat $TARFILE | docker image load
                else
                    echo "skip $(basename $TARFILE), file not found"
                fi
            done
        done
    else
        echo "Assume images are already present on the hub"
    fi
}

image_ops() {
    image_ops_input
    image_ops_output
}

do_clone() {
    # images for current arch
    echo "########## Clone URL=$URL BRANCH=$BRANCH VER=$VER"
    rm -rf ./$NAME
    git clone $URL $NAME
    cd $NAME
    if [ -n "$BRANCH" ]; then
        git checkout $BRANCH
    fi
    if [ -n "$VER" ]; then
        git fetch $VER
        git reset --hard $VER
    fi
}

# build one container image for the local machine arch
# normal flow is below remote only steps in []
#   [cd to job dir]
#   [clone correct repo branch and commit/tag]
#   save info for Dockerfile
#   do docker image build
#   save image on build machine
#   [transfer saved image from build machine to initiating machine]
# if the build machine has push credentials you can push instead of save
# For testing you can run w/o save and the image will be left on the build
# machine, this is fine for local builds or persistent machines.  It is not
# very useful for ec2 machines w/o stop also.
build_one() {
    ORIG_PWD=$PWD
    ARCH=$(uname -m)
    DOCKER_ARCH=$(docker_arch $ARCH)

    # this is build one, only do the current arch
    ARCHES="$ARCH"

    if $REMOTE_JOB; then
        do_clone
    fi

    cat >scripts/.container-build-vars <<EOF
URL=$URL
BRANCH=$BRANCH
VER=$VER
LITE_BUILD=$LITE_BUILD
EOF

    echo "########## Build TAG=$TAG DOCKER_ARCH=$DOCKER_ARCH"

    git log -n 1 --oneline

    for c in $CONTAINER_LIST; do
        (cd scripts; docker build -t $DOCKER_HUB_ACCOUNT/${c}:build-one \
            -f Dockerfile.${c} .)
        docker tag $DOCKER_HUB_ACCOUNT/${c}:build-one \
            $DOCKER_HUB_ACCOUNT/${c}:${TAG}-${DOCKER_ARCH}
    done

    image_ops_output
}

# build a manifest
# the images added to a manifest need to be on the docker hub
# they do not need to be local
# normal sequences here would be:
#     load form local images, push images, build and push manifest
# An alternate sequences would be
#     push local images (loaded or built etc), build and push manifest
#     assume docker hub has images, build and push manifest
# And for testing would be
#     assume docker hub has images, build manifest and keep local
# There really is no need for pull or save to be used for this flow
build_manifest() {
    # load push as directed
    image_ops

    : ${DEST_TAG:=$TAG}

    echo "########## Manifest TAG=$TAG DEST_TAG=$DEST_TAG"
    for c in $CONTAINER_LIST; do
        AMENDS=""
        for a_host in $ARCH_LIST; do
            a=$(docker_arch $a_host)
            AMENDS="$AMENDS $DOCKER_HUB_ACCOUNT/${c}:${TAG}-${a}"
        done

        MANIFEST_NAME=$DOCKER_HUB_ACCOUNT/${c}:${DEST_TAG}
        docker manifest rm $MANIFEST_NAME >/dev/null 2>&1 || true
        docker manifest create $MANIFEST_NAME $AMENDS
        if $PUSH; then
            docker manifest push   $DOCKER_HUB_ACCOUNT/${c}:${DEST_TAG}
        fi
    done
}

# Build one arch image set: ! MANIFEST ! LOAD ! PULL, then either SAVE or PUSH
# LOAD MANIFEST opt PUSH
# PULL MANIFEST opt PUSH
prj_build() {
    ARCH=$(uname -m)
    DOCKER_ARCH=$(docker_arch $ARCH)

    if $REMOTE_JOB; then
        mkdir -p $REMOTE_DIR
        cd $REMOTE_DIR
    fi

    ORIG_PWD=$PWD

    if $MANIFEST; then
        build_manifest
    elif $BUILD; then
        build_one
    else
        image_ops
    fi
}

help() {
    echo "./$MY_NAME <build-method> <method-args> <build-args>"
    echo "where build-method and method args are one of:"
    echo "    ec2-all               build for x86_64 and arm64 and push a manifest"
    echo "or one of these lower level commands"
    echo "    admin_setup <user>    do machine level setup for build on build host"
    echo "    prj_build             do project level build"
    echo "    here-sudo             do local build"
    echo "    here-sudo-only        do admin setup locally"
    echo "    multipass             use multipass locally for a clean build"
    echo "    ssh-sudo <remote>     do a remote build"
    echo "    ssh <remote>          do a remote build (assuming admin setup done)"
    echo "    ec2-x86_64            do a build on x86_64 ec2 machine"
    echo "    ec2-arm64             do a build on arm64 ec2 machine"
    echo "    local-manifest        build and push a manifest from saved images"
    echo "    promote               promote TAG to latest"
    echo "    image-ops             Do only load/pull and or save/push"
    echo "and where build-args are zero or more of:"
    echo "    URL=<url>         git repo url"
    echo "                      default $UPSTREAM_URL"
    echo "    BRANCH=main       git branch, default main"
    echo "    VER=<ver>         git commit or tag"
    echo ""
    echo "    TAG=YYYY-MM-DD    tag for docker containers"
    echo "                      default is today's date on top level host"
    echo "    push              push built containers to docker.io hub"
    echo "    save              save container images on top level host"
    echo "                      default if push not specified"
    echo "    manifest          create and push manifest to docker.io"
    echo "    load              load and push saved images for the manifest"
    echo "    pull              pull container from docker.io hub instead of building"
    echo ""
    echo "    stop              stop build machines instead of destroying"
}

ec2_finish() {
    if $STOP; then
        ec2 $1 stop
    else
        ec2 $1 destroy
    fi
}

# multipass and ssh-sudo use two invocations of the remote
# the admin_setup step will add the user to the docker group but it won't be
# active until the next login so we exit the remote and come back in for the
# prj_build
case $1 in
"admin_setup")
    # already root, just do the admin setup
    shift
    admin_setup "$@"
    ;;
"prj_build")
    # admin_setup was done somehow, just run the prj_build
    shift
    prj_build $ARGS
    ;;
"here-sudo")
    # local build, use sudo to do admin-setup and then do prj_build
    shift
    sudo $ME admin_setup $USER $ARGS
    prj_build $ARGS
    ;;
"here-sudo-only")
    # local build, use sudo to do admin-setup only
    shift
    sudo $ME admin_setup $USER $ARGS
    ;;
"multipass")
    # use multipass on the local machine to get a clean install of the distro
    # is always the same arch as the host
    shift
    multipass launch -n $JOB_NAME -c 10 -d ${DISK_SIZE}G -m ${MEM_SIZE}G $UBUNTU_VER
    multipass transfer $0 $JOB_NAME:.
    multipass exec $JOB_NAME -- ./$MY_NAME here-sudo-only $ARGS
    multipass exec $JOB_NAME -- ./$MY_NAME prj_build remote-job $ARGS
    # multipass always matches host
    TARGET_ARCH=$(uname -m)
    TARGET_DOCKER_ARCH=$(docker_arch $TARGET_ARCH)
    if $SAVE; then
        echo "### transfer saved files"
        mkdir -p $SAVE_PATH/$TARGET_DOCKER_ARCH
        multipass transfer -r $JOB_NAME:$REMOTE_DIR/$SAVE_PATH/$TARGET_DOCKER_ARCH/. \
            $SAVE_PATH/$TARGET_DOCKER_ARCH/.
    fi
    if $STOP; then
        multipass stop $JOB_NAME
    else
        multipass delete --purge $JOB_NAME
    fi
    ;;
"ssh-sudo"|"ssh")
    # save defaults to true if not pushing
    MODE=$1
    REMOTE_SSH=$2
    shift 2
    ssh $REMOTE_SSH mkdir -p $REMOTE_DIR
    scp $ME $REMOTE_SSH:$REMOTE_DIR
    case $MODE in
    ssh-sudo)
        ssh $REMOTE_SSH $REMOTE_DIR/$MY_NAME here-sudo-only $ARGS
        ;;
    esac
    ssh $REMOTE_SSH $REMOTE_DIR/$MY_NAME prj_build remote-job $ARGS
    if $SAVE; then
        echo "### transfer saved files"
        TARGET_ARCH=$(ssh $REMOTE_SSH uname -m)
        TARGET_DOCKER_ARCH=$(docker_arch $TARGET_ARCH)
        mkdir -p $SAVE_PATH/$TARGET_DOCKER_ARCH
        scp "$REMOTE_SSH:$REMOTE_DIR/$SAVE_PATH/$TARGET_DOCKER_ARCH/*" \
            $SAVE_PATH/$TARGET_DOCKER_ARCH/.
    fi
    ;;
"ec2-x86_64"|"ec2-x86")
    JOB_NAME=${JOB_NAME1}-x86_64
    shift
    ec2 aws-$JOB_NAME run --inst m7i.2xlarge  --os-disk $DISK_SIZE --distro ubuntu-$UBUNTU_VER
    $ME ssh-sudo aws-$JOB_NAME $ARGS
    ec2_finish aws-$JOB_NAME
    ;;
"ec2-arm64"|"ec2-arm")
    JOB_NAME=${JOB_NAME1}-aarch64
    shift
    ec2 aws-$JOB_NAME run --inst m7g.2xlarge  --os-disk $DISK_SIZE --distro ubuntu-$UBUNTU_VER
    $ME ssh-sudo aws-$JOB_NAME $ARGS
    ec2_finish aws-$JOB_NAME
    ;;
"ec2-all")
    # build on both arch and push and then build manifest
    shift
    $ME ec2-arm64  $ARGS save
    $ME ec2-x86_64 $ARGS save
    $ME local-manifest $ARGS load push
    ;;
"local-manifest")
    # used saved images, push and then build & push manifest
    shift
    $ME prj_build manifest $ARGS
    ;;
"promote")
    # use the TAG version to create a new manifest
    shift
    $ME prj_build DEST_TAG=latest manifest $ARGS
    ;;
"image-ops")
    # do whatever the args say
    shift
    $ME prj_build build=no $ARGS
    ;;
""|help)
    help
    ;;
*)
    echo "Don't understand argument $1"
    ;;
esac
