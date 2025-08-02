# HVAC Demo(s)

This is the home repo for HVAC demos.
HVAC stands for Heterogeneous VirtIO for Automotive Computing.
HVAC is a Linaro project to support virtio-msg on AMP systems.
You can find out more about the HVAC project at the [HVAC home page](https://linaro.atlassian.net/wiki/spaces/HVAC/overview).

Currently there are a few demos here but there will be more over time.
These demos include virtio-msg for AMP systems and for other uses of
virtio-msg such as virtio-msg-ffa.


| Name       | Description                                               |
|------------|-----------------------------------------------------------|
| [demo-loopback](demo-loopback.readme.md) | virtio-msg-loopback demo    |
| [demo-xen-ffa](demo-xen-ffa.readme.md)   | virtio-msg-ffa demo with Xen |
| [demo-qemu-proxy](demo-qemu-proxy.readme.md) | QEMU with virtio-msg-proxy |
| [demo-amp-zephyr](demo-amp-zephyr.readme.md)  | dual QEMU using cortex-m Zephyr and Linux uio |
| [demo-amp-dual-linux](demo-amp-dual-linux.readme.md)  | dual QEMU with direct kernel virtio-msg    |

Upcoming additions or changes:

* Update demo-amp-zephyr to be Linux + Zephyr with virtio-msg
* Eliminate the requirement for Debian 12 if only running the demos
* Add option to use Yocto project rootfs for faster demo times

## Running the demos

Currently this work assumes:

* You are using an x86_64 or arm64 based build machine and are running Linux
(either directly or in a VM).

* You are running on Debian 12 (bookworm) directly or via a container as
described below

### Running the demo container image

A pre-built container image is available at: docker.io/wmills/hvac-demo.

It has been tested with podman and docker.

Make sure you install podman or docker and that you can run it.
See the "Podman install cheat-sheet" and "Docker install cheat-sheet" sections
below for install instructions.

To use podman:
```
podman run -it --rm docker.io/wmills/hvac-demo
```

To use docker:
```
docker run -it --rm docker.io/wmills/hvac-demo
```

Inside the container run any of the demos like:
```
./demo1
```

Building the demos in the container image is also possible but you would be
better to use the instructions below to create a container with a mounted
directory.

### Running or Building on your machine

When you clone the hvac-demo source, DO NOT clone sub-modules, the sub-modules
are handled by the demo and build scripts as needed.

Use:
```
git clone https://github.com/wmamills/hvac-demo.git
cd hvac-demo
```

Create a persistent container w/ the hvac-demo project mounted.

Make sure you install docker or podman and that you can run it.
See the Docker or Podman install cheat-sheet below for instructions.

(If you are already on a Debian 12, you may skip this step to run directly
on your machine. However, please understand that many packages will be
added to your machine.  You may wish to run in the container anyway.)

Use:
```
./container
```

Do setup for running the demos:

```
./setup run
```

The setup script will use sudo to do the admin_setup and then setup the current
user for rust development.  The admin_setup will install all the needed
packages to run the demos. The `setup run` step only needs to be run once
per machine.

You can run the demos using commands like this:

```
./demo1
```

The demo scripts will fetch any needed images from the save-images sub-module
and build the final disk images as needed.
You do not need to do anything to saved-images yourself.

See the "about the demos" section below for what to expect and the
demo specific readme to understand what the demo is doing and showing.

To rebuild everything instead of using saved-images:

```
./setup build
./Build all
```

The `Build` script can be run as many times as you wish.  The first build will
clone the sources you need.  If the source already exists when the build
happens, the source will be used as-is.

To build everything will take 30 to 60 minutes and use ~50GB of disk space.
Building everything again will take about 1/2 time.

You can run individual builds steps by replacing `all` with the individual steps
to run.  See the section on build steps below for more information.

If you ran a container you can exit with the `exit` command and the container
will stop.  You can reenter the container again with the `./container` command.

If you wish to remove the container use:

```
./container --delete
```

(You can also delete the container with the docker or podman commands,
whichever was used.)

### Podman install cheat-sheet

Podman is very easy to install for our use case.  If you have no reason to
prefer docker, we would suggest installing podman.

To install on Ubuntu 22.04 or later do this:

```
sudo apt update
sudo apt install podman
```

### Docker install cheat-sheet

There are lots of guides to installing docker on the internet.  However most
tell you to install the non-free docker-desktop or docker-engine.  If you are
already running Linux then you can (and should IMHO) use the open source docker
already packaged with your distro.

(If you have need of the docker-desktop or very latest version of docker for
other projects, that should work with this project just fine as well.)

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

The build action does all required build steps by default.
However if individual build steps are listed on the command line, only those
build steps are done.

The build steps are any of `xen`, `rust`, `linux`, `qemu`, `qemu-cross`,
`u-boot`, `devmem2`and `disk`.  The `disk` build step assumes the other steps
have run. The `qemu-cross` step requires the xen and qemu steps to have been
run.

The build steps `clean`, `clean-src`, and `'clean-src-all` are supported.
The `clean` step removes the build/ directory and does a git clean in each
source repo that builds in-tree (currently only the xen steps).
The `clean-src` step does everything that clean does but also removes the
cloned source directories but leaves the reference clones.
The `clean-src-all` step does everything that clean-src does but also removes
the reference clones, currently linux.git, qemu.git, and xen.git.

Due to the current state of the demos, multiple versions of `linux`, `qemu`,
`qemu-cross`, and `xen` are built.  You can build the individual version by
finding the build function name in `prj_script.sh` and in the builds scripts.
Any function in those scripts
that starts with `build_` can be used as a build step.  The build step names
can use dashes or underscores as all dashes will be converted to underscores by
the script.

```
grep ^build_ scripts/prj_script.sh scripts/build/*
```

Note: because the xen builds are done in-tree, the xen build steps clean all
ignored files before the build.  Files that are not ignored and files that
are modified will not be cleaned.  If you have an ignored file that you wish
to keep, stage it for a commit, even if you don't intend to commit it.

## About the demos

Look at the individual readme's for the demos to understand what they are
showing and the software layers involved.  This section will describe the demos
in general.

Each of the demos runs in tmux to get you access to:
* The host shell
* One or more target systems

You can use the mouse to select which window will have focus.

The demos are setup to automatically test themselves.
The target systems will boot and then run a demo script.
The demo script will give a TEST PASS message if everything works.
Many errors are caught and will give a TEST FAIL message. Not all possible
errors are caught. After the demo script runs, the autorun script will
powerdown the target.

Before the demo script runs and before the powerdown is given, a count down is
shown. If you press ctrl-c during that countdown you will get a shell and you
can instead run things manually.

Many demos have multiple layers of target systems, for example running a
kvm+qemu VM or peer DomU within the first target system.  In these cases, the
second layer of target code will also have its own demo script, powerdown, and
abortable count down.

After the complete demo runs (and tmux has exited) the logs will be searched
and any TEST PASSED or TEST FAILED messages will be printed.

### Known issues

Whenever virtio-scsci-pci devices are used at the QEMU system level and xen
is used, the
Linux kernel has an oops when setting up the interrupts for this device.
This does not happen without Xen.  This error is not fatal, the demos still
work, but it is ugly.  I have switched to virtio-mmio to work around this issue
before but a virtio-scsi-device is not supported in QEMU and switching to
virtio-blk-device would change the root device name.
