# ext2-bootloader
An ext2-compatible bootloader for i386 PCs.

**Note: Only supports 1.44 MB floppies (3.5in).**

This bootloader does the following:
  * Searches the disk for a kernel image by name
  * Loads the image at a known address below 1 MiB
  * Drops into a 32-bit kernel in Protected Mode
      * GDT loaded at a well-known address
      * inode table loaded at a well-known address
      * Interrupts disabled on the PICs
      * Access to all 4 GiB of address space

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

Or, more simply, run `./copy_kernel.sh`.


**Happy booting! :-)**