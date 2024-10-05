# HVAC Demo(s)

This is the home repo for HVAC demos.
HVAC stands for Heterogeneous VirtIO for Automotive Computing.
HVAC is a Linaro project to support virtio-msg on AMP systems.
You can find out more about the HVAC project at the [HVAC home page](https://linaro.atlassian.net/wiki/spaces/HVAC/overview).

Currently there are a few demos here but there will be more over time.

| Name       | Description                                               |
|------------|-----------------------------------------------------------|
| [demo1](demo1.readme.md)  | Early virtio-msg kernel prototype          |
| [demo2](demo2.readme.md)  | QEMU with virtio-msg-proxy                 |
| demo2a     | dual QEMU with Linux user-space connection                |
| demo2b     | dual QEMU machines connected via two ivshmem pcie devices |
| demo2b-xen | as demo2b but uses Xen on both sides as well              |

Upcoming demos:

| Name       | Description                                               |
|------------|-----------------------------------------------------------|
| demo3      | dual QEMU using ivshmem-flat and uio                      |
| demo4      | dual QEMU with direct kernel virtio-msg                   |

We will also add the capability to run the demos without building everything
yourself and we will have a container image ready to run or rebuild everything.

## Building the demos

Current this work assumes:

* You are using an x86_64 based build machine and are running Linux
(either directly or in a VM).

* You are building in Debian 12 (bookworm) directly or via a container as
described below

* The current version of rustc at the time this page was written was 1.81.0

Demos that use Xen or QEMU on the target uses a Debian 12 based rootfs so we
do all cross compilation for userspace on Debian 12 so the libraries match.

### Building on a Debian 12 machine

If you are already on a Debian 12 x86_64 machine, you can do the build and
run the demo directly.  However, please understand that many packages will be
added to your machine.  You may wish to follow the docker instructions below
if you do not want that.

To do setup, use:

```
./setup
```

The setup script will use sudo to do the admin_setup and then setup the current
user for rust development.  The admin_setup will install all the needed
packages. The `setup` step only need to be run once per machine.

To build everything use:

```
./Build all
```

The `Build` script can be run as many times as you wish.  The first build will
clone the sources you need.  If the source already exists when the build
happens, the source will be used as-is.

You can run individual builds steps by replacing `all` with the individual steps
to run.  See the section on build steps below for more information.

After building you can run the demos using commands like this:

```
./demo1
```

### Building in a Container

Make sure docker is installed and you can run it.

The following command will start the container:

```
docker run -it --name hvac-demo -v$PWD:/prj debian:12 \
    /prj/scripts/container-main
```

`container-main` will run the distro setup and create your user and give you sudo
access.  It will then run the admin_setup, switch to your user and run the
prj_setup.  After that it will give you a shell where you can follow the
instructions above for building.

To reuse a container after exit, use:
```
docker start hvac-demo
docker attach hvac-demo
```

When you exit the shell the container will stop again.

To delete the container use:

```
docker rm -f hvac-demo
```

### Building with dockit

[dockit](https://github.com/wmamills/cloudbuild) is a utility [Bill](https://github.com/wmamills)
uses to do persistent containers for development.  It is a work in progress but
Bill uses it often.

Clone that repo somewhere and create a symlink to the dockit file in your ~/bin
or ~/.local/bin directory and make sure that the one you used is in your path.
As with the other docker based methods you will need to
[install docker](Docker install cheat-sheat).

To build everything use this command:

```
dockit build
```

To do just one step use (xen as an example below):
```
dockit build xen
```

To run a demo script after building, use:
```
dockit icmd ./demo1
```

To get a shell in the container, use:
```
dockit shell
```

`dockit purge` will delete all containers for this project. Check 
`dockit help` for more options.

### Docker install cheat-sheet

There are lots of guides to installing docker on the internet.  However most
tell you to install the non-free docker-desktop or docker-engine.  If you are
already running Linux then you can (and should IMHO) use the open source docker
already packaged with your distro.

To install on Ubuntu do this:

```
sudo apt update
sudo apt install docker.io
sudo adduser $USER docker
```

Then logout and log back in in order to get the new group. You can check your
groups and docker access with these commands:

```
$ groups
$ docker ps
```

### Individual Build steps

The build action (prj_build function) does all required build steps by default.
However if individual build steps are listed on the command line, only those
build steps are done.

The build steps are any of `xen`, `rust`, `linux`, `qemu`, `qemu-cross`,
`u-boot`, `devmem2`and `disk`.  The `disk` build step assumes the other steps
have run. The `qemu-cross` step requires the xen and qemu steps to have been
run.

The build steps `clean`, `clean-src`, and `'clean-src-all` are supported.
The `clean` step removes the build/ directory and does a git clean in each
source repo that builds in-tree (currently only xen steps).
The `clean-src` step does everything that clean does but also removes the
cloned source directories but leaves the reference clones.
The `clean-src-all` step does everything that clean-src does but also removes
the reference clones, currently linux.git, qemu.git, and xen.git.

Due to the current state of demos, multiple versions of `linux`, `qemu`,
`qemu-cross`, and `xen` are built.  You can build the individual version by
finding the build function name in `prj_script.sh`.  Any function in that script
that starts with `build_` can be used as a build step.  The build step names
can use dashes or underscores as all dashed will be converted to underscores by
the script.

```
grep ^build_ scripts/prj_script.sh
```

Note: because the xen build is done in-tree, the build-xen step cleans all
ignored files before the build.  Files that are not ignored and modifies files
will not be cleaned. If you have an ignored file that you wish to keep,
stage it for a commit, even of you don't intent to commit it.

Demos can also be specified on the prj_build command line and the demo will
be run.  This will not work with dockit as noted in that section. Use the icmd
to run the demos with dockit (or just get a shell and run from there.)

## Running the demos

Look at the individual readmes for the demos to understand what they are
showing and the software layers involved.  This section will describe the demos
in general.

Each of the demos runs in tmux to get you access to:
* The host shell
* One or more target systems

You can use the mouse to select with window to give focus.

The demos are setup to automatically test themselves.
The targets systems will boot and then run a demo script specified on the
command line. The demo script will give a TEST PASS message if everything works.
Many errors are caught and will give a TEST FAIL message. Not all possible
errors are caught. After the demo script runs the autorun script will
powerdown the target.

Before the demo script runs and before the powerdown is given, a count down is
shown. If you press ctrl-c during that countdown you will get a shell and you
can instead run things manually.

Many demos have multiple layers of target systems, for example running a
kvm+qemu VM or peer DomU with-in the first target system.  In these cases the
second layer of target code will also have its own demo script, powerdown and
abortable count down.

After the complete demo runs (and tmux has exited) the logs will be searched
and any TEST PASSED or TEST FAILED messages will be printed.

### Known issues

Whenever virtio-pci devices are used at the QEMU level and xen is used, the
Linux kernel has oops when setting up the interrupts for this device.
This does not happen without Xen.  This error is not fatal, the demos still
work, but it is ugly.  I have switched to virtio-mmio to work around this issue
before but virtio-scsi-device is not supported and switching to
virtio-blk-device would change the root device name.
