# HVAC Demo(s) TODO file

* Add demo for ivshmem-flat
* Add demo for kernel using ivshmem directly (no qemu proxy)
* Add test mode to multi-qemu
    * record return code from each qemu instance and the host process
    * add timeout for the qemu's to exit, kill and declare failure in timeout
    * parse logs to detect pass/fail
* add Makefile at top for easy understanding
    X break build_* functions out of prj_script.sh into scripts/build/*
    * Makefile will check dependencies and then run the scripts
* enable images, saved-images and maybe-fetch
* build a container
  * w/ everything to run demos
  * can rebuild everything but will download and clone stuff
  * can work w/ mounted user /prj or not
* make container run work on arm64
* make build run on arm64
* fix kernel oops in xen for virtio-pci devices (is not fatal but is ugly)
* forward ports from host to container
