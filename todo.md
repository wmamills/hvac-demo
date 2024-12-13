# HVAC Demo(s) TODO file

* Error out if not on debian-12
    (we require debian-12 to build target content so error out if not)
* Make demos build disk images if not present
* Make disk images less painful to build
    * debian: build per demo 2nd disk instead of throwing everything in one
    * debian: now that base debian disk is more generic, boot it at build time
      and save the result
    * switch to make-target-images instead of guestfish
* Make demo start failures easier to debug
    * print log if any pane returns an error rc
    * add easy option to enable -x in scripts (other than edit)
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
* build a container
  * w/ everything to run demos
  * can rebuild everything but will download and clone stuff
  * can work w/ mounted user /prj or not
* bundle a copy of dockit into the project
* make container run work on arm64
* make build run on arm64
* make demos work w/o container if distro has needed things
  * build host qemu's on old enough distro and save result
  * add an easy way to install needed packages
* fix kernel oops in xen for virtio-pci devices (is not fatal but is ugly)
* forward ports from host to container
