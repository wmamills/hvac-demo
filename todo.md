# HVAC Demo(s) TODO file

* Make disk images less painful to build
    * debian: build per demo 2nd disk instead of throwing everything in one
    * debian: now that base debian disk is more generic, boot it at build time
      and save the result
    * switch to make-target-images instead of guestfish
* Add test mode to multi-qemu
    * record return code from each qemu instance and the host process
    * add timeout for the qemu's to exit, kill and declare failure in timeout
    * parse logs to detect pass/fail
* Add top level regression test
    1) Build all and test all demos
    2) save all locally to saved-images
    3) rm -rf images build src && rebuild container
    4) test all demos again from saved-images
* Build minimal rootfs
    ( right now we fetch the result but don't build it )
    * switch from buildroot to yocto? or support both?
* add Makefile at top for easy understanding
    X break build_* functions out of prj_script.sh into scripts/build/*
    * Makefile will check dependencies and then run the scripts
    * Add demo targets to Makefile that will build or fetch what is needed
    * Save dependencies for each saved-image so they can be checked
X build a container
  X w/ everything to run demos
  X can rebuild everything but will download and clone stuff
  * can work w/ mounted user /prj or not
X make container run work on arm64
X make build run on arm64
* make demos work w/o container if distro has needed things
  * build host qemu's on old enough distro and save result
  * add an easy way to install needed packages
* fix kernel oops in xen for virtio-pci devices (is not fatal but is ugly)
* forward ports from host to container
* fix tmux garbage print if exit right away?
  * from: https://github.com/speg03/dotfiles/pull/15/commits/64b463cf880aa66b2013ce7386724a7fcb34c91b
  * set -s escape-time 50
