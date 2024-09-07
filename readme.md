# HVAC Demo(s)

This is the home repo for HVAC demos.
HVAC stands for Heterogeneous VirtIO for Automotive Computing.
HVAC is a Linaro project to support virtio-msg on AMP systems.
You can find out more about the HVAC project at the [HVAC home page](https://linaro.atlassian.net/wiki/spaces/HVAC/overview).

Currently there is only one demo but there will be more over time.
We will also add the capability to run the demo without building everything
yourself and we will have a container image ready to run or rebuild everything.

## Early virtio-msg kernel prototype

This work is a stepping stone toward other forms of virtio-msg. It leverages
work done in prior projects to unblock the kernel work on the common
virtio-msg transport layer.

The focus of this work is the guest kernel running in DomU. The use of Xen and
the rust based device model here are expediences to get something working
quickly and are reused from the prior Orko project.

Please keep in mind the following caveats for this demo at this stage:

* The virtio-msg-bus level here is not intended for real implementations as it
has no advantage over virtio-mmio. 

* This bus implementation relies on any response being available immediately
after sending, which is only possible in a trap and emulate environment 

* It also assumes that the driver side kernel can put buffers anywhere it
chooses to and uses Guest PA in virtqueues.

These items will be addressed in later work.

Also please understand that this work assumes:

* You are using an x86_64 based build machine and are running Linux
(either directly or in a VM).

* You are building in Debian 12 (bookworm) directly or via a container as
described below

* The current version of rustc at the time this page was written was 1.80.1

This demo uses a Debian 12 based rootfs for Dom0 so we do all cross compilation
for userspace on Debian 12 so the libraries match.

### Building on a Debian 12 machine

If you are already on a Debian 12 x86_64 machine, you can do the build and
run the demo directly.  However, please understand that many packages will be
added to your machine.  You may wish to follow the docker instructions below
if you do not want that.

To build everything directly, use:

```
sudo ./scripts/prj_script.sh admin_setup
./scripts/prj_script.sh prj_setup
./scripts/prj_script.sh prj_build
```

The *_setup steps only need to be run once per machine.  The prj_build step can
be runs as many times as you wish.  The first build will clone the sources you
need.  If the source already exists when the build happens, the source will be
used as-is.

You can run individual builds steps by adding them to the prj_build command
line.  See the section on build steps below for more information.

After building you can run using:
./demo1

### Building in a Container

Make sure docker is installed and you can run it.

The following command will build everything and run it:

```
docker run -it --name hvac-demo -v$PWD:/prj debian:12 \
    /prj/scripts/prj_script.sh container-main build all demo1
```

container-main will run the distro setup and create your user and give you sudo
access.  It will then run the admin_setup, switch to your user and run the
prj_setup.  After that `build` will run steps `all` and `demo1`.
Instead of `build` you can use shell just to get a shell in the /prj directory
as yourself.

To reuse a container use:
```
docker start hvac-demo
docker attach hvac-demo
su me
```
Use exit twice to exit and stop the container.

To delete the container use:

```
docker rm -f hvac-demo
```

### Building with dockit

[dockit](https://github.com/wmamills/cloudbuild) is a utility [Bill](https://github.com/wmamills)
uses to do persistent containers for development.  It is a work in progress but
Bill uses it often.

Follow the instructions from the above repo to install dockit.

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

### Individual Build steps

The build action (prj_build function) does all required build steps by default.
However if individual build steps are listed on the command line, only those
build steps are done.

The build steps are any of `xen`, `rust`, `linux`, `qemu`, `qemu-cross`, and 
`disk`.  The `disk` build step assumes the others have run.  The `qemu-cross`
step requires the xen and qemu steps to have been run.

Note: because the xen build is done in-tree, the build-xen step cleans all
ignored files before the build.  Files that are not ignored will not be cleaned
nor will be modified files.  If you have an ignored file that you wish to keep
stage it for a commit, even of you don't intent to commit it.

Demos can also be specified on the prj_build command line and the demo will
be run.  `demo1` is the only demo currently.  This will not work with dockit
as noted in that section.  Use the icmd to run the demos with dockit (or just 
get a shell and run from there.)
