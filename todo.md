# HVAC Demo(s) TODO file

* Fix demo2b with Xen on B side 
    * fix qemu-virtio-msg build w/ xen enabled
    * figure out what is going on w/ qemu start in target
* Add demo for ivshmem-flat
* Document how to use with dockit
* Move all git cloned source to source/ directory
    * when adding a worktree, fixup the link so it works outside of container also
	/prj/ -> ../
* Add test mode to multi-qemu
    * record return code from each qemu instance and the host process
    * add timeout for the qemu's to exit, kill and declare failure in timeout
    * parse logs to detect pass/fail
* fixup demo1 so it looks like others
    * create demo1.d/
    * move unique mixins here
    * move qemu command line to scripts/
    * run with multi-qemu (even though just one)
* add clean, clean-src, and clean-src-all
    * clean: clean all built items
    * clean-src: also remove the cloned sources xen, qemu-*, etc
    * clean-src-all: also remove the reference repos like qemu.git
* add Makefile at top for easy understanding
    * break build_* functions out of prj_script.sh into scripts/build/*
    * Makefile will check dependencies and then run the scripts
* enable images, saved-images and maybe-fetch
* build a container
  * w/ everything to run demos
  * can rebuild everything but will download and clone stuff
  * can work w/ mounted user /prj or not
* make container run work on arm64
* make build run on arm64
