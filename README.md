# ext2-bootloader
A bootloader for i386 PCs that supports ext2 disks.

## Overview
### Features
  * Compatible with 1.44 MB floppy disks
  * Supports 32-bit kernels up to 268 KiB in size
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
First, we need to make an ext2 floppy image. This only needs to be done once.

        $ make img

Now, build the bootloader and sample kernel.

        $ make

You can also build the kernel and bootloader separately.

        $ make bootldr
        $ make kernel

## QEMU Instructions
Run the following command to boot the disk image with QEMU.

        $ qemu-system-i386 -drive if=floppy,file=floppy.img

## Floppy Disk Instructions
1) To write the disk image to a real floppy disk, execute the following command
as `root`. Beware that this overwrites the **ENTIRE** floppy disk, so be sure
to back it up!

        $ dd if=floppy.img of=/dev/fd0 bs=512

2) The above command takes time and always re-writes the filesystem. If you
want to update only the bootloader and keep the filesystem intact, run the
following command as `root`.

        $ dd if=bootldr of=/dev/floppy bs=512 conv=notrunc

3) If you want to update the kernel image, simply mount the disk and copy it
over like you would any other file.

        $ mount /dev/fd0 /mnt
        $ cp kernel /mnt
        $ umount /mnt


**Happy booting! :-)**
