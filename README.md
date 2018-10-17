# ext2-bootloader
An ext2-compatible bootloader for i386 PCs.

## Overview
### Features
  * Compatible with 1.44 MB (3.5 in) floppy disks
  * Can load 32-bit kernels up to 268 KiB in size
  * Kernel loaded at a well-known address below 1 MiB

#### Upon entry to the kernel
  * CPU is running in 32-bit Protected Mode
  * GDT loaded at a well-known address
      * All 4 GiB of address space accessible from ring 0
  * Interrupts disabled via the PICs

### Memory Map
The following is the memory layout upon entry to the kernel.

                | Free memory           |  Free to use
        100000  +-----------------------+
                | Reserved for hardware |  Use with caution
        0A0000  +-----------------------+
                | Reserved for BIOS     |  Do not use (BIOS EBDA)
        09FC00  +-----------------------+
                | Kernel                |  Kernel code and data
        010000  +-----------------------+
                | GDT                   |  Global Descriptor Table
        00A000  +-----------------------+
                | Bootloader            |  <-- Bootsector entry point at 0x7C00
        001000  +-----------------------+
                | Reserved for BIOS     |  Do not use
        000400  +-----------------------+
                | Real Mode IVT         |  Do not use
        000000  +-----------------------+

## Building
Run `make bootldr`, or simply `make`, to build the bootloader. This will
produce a 1 KiB binary which can be written to the boot block of an
ext2-formatted disk (see Floppy Disk Instructions below).

Run `make kernel` to build the sample kernel. This kernel image can be copied to
the disk like any other file.

Run `make img` to produce a floppy disk image with the bootloader and sample
kernel pre-installed.

Run `make floppy` to write the floppy disk image to a real floppy disk. **Beware
that this will overwrite the entire disk.**

### Floppy Disk Instructions
Writing the entire disk image to a floppy disk takes time and destroys the
existing file system on the disk. Follow these steps to manually inject the
bootloader and kernel image.

To write the bootloader, run the following:

        $ dd if=bootldr of=/dev/fd0 bs=512 conv=notrunc

To write the kernel image, run the following:

        $ mount /dev/fd0 /mnt
        $ cp kernel /mnt
        $ umount /mnt

## Running with QEMU
Run the following command to boot the disk image with QEMU.

        $ qemu-system-i386 -drive if=floppy,file=floppy.img

## Running on Real Hardware
To use this bootloader on real hardware, follow the floppy disk instructions
above, then boot the system from the floppy disk.

**Happy booting! :-)**
