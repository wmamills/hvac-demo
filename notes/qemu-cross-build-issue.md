# Notes on the QEMU cross build issue

I cross build for arm64 on Debian 12 x86_66 (amd64).
I had issues with cross building any QEMU v9+ with xen enabled.
The problem can be demonstrated with Xen upstream 4.19.0 and QEMU v9.0.0 so we 
will focus on that combination.

I cross build xen 4.19 for arm64 and then install it.  I then cross build QEMU
with --enable-xen and get the errors described down below.

## Workaround 1

This issue goes away if you use QEMU 8.x.  (Tested 8.0.0)

This is not a real solution for us but is very strange.  Something in QEMU has
changed in 9.x that shows this conflict between xen and kernel that has been
there for years.

## Workaround 2

When enabling xen, disable kvm.  This makes the problem go away.
This is what I have implemented.

```
EXTRA_CONFIG="--cross-prefix=aarch64-linux-gnu- --enable-xen --disable-kvm"
```

## Workaround 3

Disable -werror in the QEMU build.

The qemu config line can take a --disable-werror option to do this.
I have not tested this yet.

## Question 1

Why do we not see this in QEMU v8.0?

## Question 2

Why do we not see this in Yocto builds?

## Error messages

A sample of the error messages look like this:

```
/usr/local/include/xen/arch-arm.h:395: error: "PSR_MODE_EL3t" redefined [-Werror]
  395 | #define PSR_MODE_EL3t 0x0cU
      | 
/usr/aarch64-linux-gnu/include/asm/ptrace.h:37: note: this is the location of the previous definition
   37 | #define PSR_MODE_EL3t   0x0000000c
      | 
```

The complete list (from grep -e '#define') is:

```
  394 | #define PSR_MODE_EL3h 0x0dU
   38 | #define PSR_MODE_EL3h   0x0000000d
  395 | #define PSR_MODE_EL3t 0x0cU
   37 | #define PSR_MODE_EL3t   0x0000000c
  396 | #define PSR_MODE_EL2h 0x09U
   36 | #define PSR_MODE_EL2h   0x00000009
  397 | #define PSR_MODE_EL2t 0x08U
   35 | #define PSR_MODE_EL2t   0x00000008
  398 | #define PSR_MODE_EL1h 0x05U
   34 | #define PSR_MODE_EL1h   0x00000005
  399 | #define PSR_MODE_EL1t 0x04U
   33 | #define PSR_MODE_EL1t   0x00000004
  400 | #define PSR_MODE_EL0t 0x00U
   32 | #define PSR_MODE_EL0t   0x00000000
  394 | #define PSR_MODE_EL3h 0x0dU
   38 | #define PSR_MODE_EL3h   0x0000000d
  395 | #define PSR_MODE_EL3t 0x0cU
   37 | #define PSR_MODE_EL3t   0x0000000c
  396 | #define PSR_MODE_EL2h 0x09U
   36 | #define PSR_MODE_EL2h   0x00000009
  397 | #define PSR_MODE_EL2t 0x08U
   35 | #define PSR_MODE_EL2t   0x00000008
  398 | #define PSR_MODE_EL1h 0x05U
   34 | #define PSR_MODE_EL1h   0x00000005
  399 | #define PSR_MODE_EL1t 0x04U
   33 | #define PSR_MODE_EL1t   0x00000004
  400 | #define PSR_MODE_EL0t 0x00U
   32 | #define PSR_MODE_EL0t   0x00000000
```

You can see that the effective result is the same in all cases but the form
and type of the constant has been changed.

/usr/local/include/xen/arch-arm.h of course comes from the xen package I had
built and installed.  The 0x??U form comes from here.  The form is the same for
xen 4.18 as well.

/usr/aarch64-linux-gnu/include/asm/ptrace.h comes from the package
linux-libc-dev-arm64 which in debian 12 comes from Linux kernel 6.1.
The constant has the same form in 6.11 and 5.1 so it is not the kernel that is
changing.
