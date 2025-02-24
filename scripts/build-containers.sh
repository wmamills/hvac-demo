#!/bin/bash

ME=$0
MY_NAME=$(basename $ME)

UBUNTU_VER=22.04

# Saved image name
NAME=openamp-docker

ARCH_LIST="x86_64 aarch64"

JOB_NAME1=openamp-docker-build
JOB_DATE=$(date +%Y-%m-%d-%H%M%S)
JOB_NAME=${JOB_NAME1}-${JOB_DATE}

# arguments to pass to sub-jobs
ARGS=""

PUSH=false
PULL=false
MANIFEST=false
STOP=false
LOAD=false

for i in "$@"; do
    VAL=${i#*=}
    case $i in
    BRANCH=*)
        BRANCH=$VAL
        ;;
    URL=*)
        URL=$VAL
        ;;
    VER=*)
        VER=$VER
        ;;
    TAG=*)
        TAG=$VAL
        ;;
    push)
        PUSH=true
        ARGS="$ARGS $i"
        : ${SAVE:=false}
        ;;
    save)
        SAVE=true
        ARGS="$ARGS $i"
        ;;
    pull)
        PULL=true
        ARGS="$ARGS $i"
        ;;
    load)
        LOAD=true
        ARGS="$ARGS $i"
        ;;
    manifest)
        MANIFEST=true
        ARGS="$ARGS $i"
        ;;
    stop)
        STOP=true
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
wam-*)
    : ${BRANCH:=$CURRENT_BRANCH}
    : ${URL:=https://github.com/wmamills/openamp-demo.git}
    ;;
"none")
    : ${BRANCH:=main}
    : ${URL:=https://github.com/openamp/openamp-demo.git}
    ;;
*)
    : ${BRANCH:=$CURRENT_BRANCH}
    : ${URL:=https://github.com/openamp/openamp-demo.git}
    ;;
esac

ARGS="URL=$URL BRANCH=$BRANCH VER=$VER TAG=$TAG $ARGS"
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

build_one() {
    # images for current arch
    echo "########## Build"
    rm -rf openamp-demo
    git clone $URL openamp-demo
    cd openamp-demo
    if [ -n "$BRANCH" ]; then
        git checkout $BRANCH
    fi
    if [ -n "$VER" ]; then
        git reset --hard $VER
    fi
    git log -n 1

    cd docker
    make
    for c in demo demo-lite; do
        docker tag openamp/${c} \
            openamp/${c}:${TAG}-${DOCKER_ARCH}
    done

    if $PUSH; then
        echo "########## Push"
        for c in demo demo-lite; do
            docker tag openamp/${c}:${OLD_TAG}-${DOCKER_ARCH} \
                openamp/${c}:${TAG}-${DOCKER_ARCH}
            docker push openamp/${c}:${TAG}-${DOCKER_ARCH}
        done
    fi

    if $SAVE; then
        echo "########## Save"
        mkdir -p $ORIG_PWD/out/docker
        for c in demo demo-lite; do
            echo "save ${c} image"
            docker image save openamp/${c}:${TAG}-${DOCKER_ARCH} |
                gzip >$ORIG_PWD/out/docker/${c}-${TAG}-${DOCKER_ARCH}.tar.gz
        done
    fi
}

# manifest, requires push so does not test it
build_manifest() {
    if $PULL; then
        echo "########## Pull"
        for a_host in $ARCH_LIST; do
            a=$(docker_arch $a_host)
            for c in demo demo-lite; do
                docker pull openamp/${c}:${TAG}-${a}
            done
        done
    elif $LOAD; then
        echo "########## Load"
        for i in saved-images/host/*/docker/*.tar.gz; do
            echo "load $(basename $i)"
            zcat $i | docker image load
        done

        # push images as they are needed for manifest command
        for a_host in $ARCH_LIST; do
            a=$(docker_arch $a_host)
            for c in demo demo-lite; do
                docker push openamp/${c}:${TAG}-${a}
            done
        done
    else
        echo "Assume images are already present on the hub"
    fi

    echo "########## Manifest"
    for c in demo demo-lite; do
        AMENDS=""
        for a_host in $ARCH_LIST; do
            a=$(docker_arch $a_host)
            AMENDS="$AMENDS --amend openamp/${c}:${TAG}-${a}"
        done

        docker manifest create openamp/${c}:${TAG} $AMENDS
        docker manifest push   openamp/${c}:${TAG}
    done
}

# Build one arch image set: ! MANIFEST ! LOAD ! PULL, then either SAVE or PUSH
# LOAD MANIFEST opt PUSH
# PULL MANIFEST opt PUSH
prj_build() {
    ORIG_PWD=$PWD
    ARCH=$(uname -m)
    DOCKER_ARCH=$(docker_arch $ARCH)
    rm -rf out
    mkdir -p out

    if $MANIFEST; then
        build_manifest
    else
        build_one
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
    echo "    ec2-x86_64            do a build on x86_64 ec2 machine"
    echo "    ec2-arm64             do a build on arm64 ec2 machine"
    echo "    local-manifest        build and push a manifest from saved-images"
    echo "and where build-args are zero or more of:"
    echo "    URL=<url>         git repo url"
    echo "                      default https://github.com/openamp/openamp-demo.git"
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
    multipass launch -n $JOB_NAME -c 10 -d 25G -m 16G $UBUNTU_VER
    multipass transfer $0 $JOB_NAME:.
    multipass exec $JOB_NAME -- ./$MY_NAME here-sudo-only $ARGS
    multipass exec $JOB_NAME -- ./$MY_NAME prj_build $ARGS
    # multipass always matches host
    TARGET_ARCH=$(uname -m)
    if $SAVE; then
        mkdir -p saved-images/host/$TARGET_ARCH/docker
        multipass transfer -r $JOB_NAME:out/docker saved-images/host/$TARGET_ARCH/.
    fi
    if $STOP; then
        multipass stop $JOB_NAME
    else
        multipass delete --purge $JOB_NAME
    fi
    ;;
"ssh-sudo")
    # save defaults to true if not pushing
    : ${SAVE:=true}
    REMOTE_SSH=$2
    shift 2
    scp $ME $REMOTE_SSH:.
    ssh $REMOTE_SSH ./$MY_NAME here-sudo-only $ARGS
    ssh $REMOTE_SSH ./$MY_NAME prj_build $ARGS
    if $SAVE; then
        TARGET_ARCH=$(ssh $REMOTE_SSH uname -m)
        mkdir -p saved-images/host/$TARGET_ARCH/docker
        scp "$REMOTE_SSH:out/docker/*" saved-images/host/$TARGET_ARCH/docker/.
    fi
    ;;
"ec2-x86_64"|"ec2-x86")
    JOB_NAME=${JOB_NAME1}-x86_64
    shift
    ec2 aws-$JOB_NAME run --inst m7i.2xlarge  --os-disk 25 --distro ubuntu-$UBUNTU_VER
    $ME ssh-sudo aws-$JOB_NAME $ARGS
    ec2_finish aws-$JOB_NAME
    ;;
"ec2-arm64"|"ec2-arm")
    JOB_NAME=${JOB_NAME1}-aarch64
    shift
    ec2 aws-$JOB_NAME run --inst m7g.2xlarge  --os-disk 25 --distro ubuntu-$UBUNTU_VER
    $ME ssh-sudo aws-$JOB_NAME $ARGS
    ec2_finish aws-$JOB_NAME
    ;;
"ec2-all")
    # build on both arch and push and then build manifest
    shift
    $ME ec2-arm64  $ARGS save
    $ME ec2-x86_64 $ARGS save
    $ME local-manifest $ARGS
    ;;
"local-manifest")
    SAVE=false
    # build on both arch and push and then build manifest
    shift
    $ME prj_build load manifest $ARGS
    ;;
"")
    help
    ;;
*)
    echo "Don't understand argument $1"
    ;;
esac
