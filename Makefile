#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Copyright (C) 2018 Wes Hampson. All Rights Reserved.                         #
#                                                                              #
# This is free software: you can redistribute it and/or modify                 #
# it under the terms of version 2 of the GNU General Public License            #
# as published by the Free Software Foundation.                                #
#                                                                              #
# See LICENSE in the top-level directory for a copy of the license.            #
# You may also visit <https://www.gnu.org/licenses/gpl-2.0.txt>.               #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#-------------------------------------------------------------------------------
#   File: Makefile
# Author: Wes Hampson
#   Desc: This Makefile compiles the bootloader and kernel image. Both binaries
#         are automatically written to a floppy disk image.
#         The kernel is provided only for demonstration. You should be able to
#         "slot-in" your own kernel with minimal modifications to the bootloader
#         (e.g. kernel base address).
#
# FLOPPY DISK INSTRUCTIONS:
#		  To write the disk image to a real floppy disk, execute the following
#         command as root. Beware that this overwrites the ENTIRE floppy disk,
# 		  so be sure to back it up!
#	          $ dd if=floppy.img of=/dev/fd0 bs=512
#
#         The above command takes time and always re-writes the filesystem. If
#		  you want to update only the bootloader and keep the filesystem intact,
#         run the following command as root.
#		      $ dd if=bootldr of=/dev/floppy bs=512 conv=notrunc
#
#		  If you want to update the kernel image, simply mount the disk and copy
#         it over like you would any other file.
#             $ mount /dev/fd0 /mnt
#             $ cp kernel /mnt
#             $ umount /mnt
#
#         Happy booting! :)
#-------------------------------------------------------------------------------

# Common compiler/assembler options
GCC_WARNINGS    := -Wall -Wextra -Wpedantic

# Compiler/assembler/linker setup
AS              := gcc
AFLAGS          := $(GCC_WARNINGS) -D__ASM -g -m32
CC              := gcc
CFLAGS          := $(GCC_WARNINGS) -g -Og -m32 -ffreestanding -nostdinc \
                   -fno-unwind-tables -fno-asynchronous-unwind-tables   \
                   -fno-stack-protector -fno-pic
LD              := ld
LFLAGS          :=

# Source files
BOOT_SRC        := boot.S stage2.S a20.S i8042.S    # boot.S MUST be first
KERN_SRC        := kernel.c

# Object files
BOOT_OBJ        := $(BOOT_SRC:.S=_asm.o)
BOOT_OBJ        := $(BOOT_OBJ:.c=.o)
KERN_OBJ        := $(KERN_SRC:.S=_asm.o)
KERN_OBJ        := $(KERN_SRC:.c=.o)

# Linker scripts
BOOT_LDSCRIPT   := boot.ld
KERN_LDSCRIPT   := kernel.ld

# Target binaries
BOOT_TARGET     := bootldr
KERN_TARGET     := kernel

# Disk image
DISKIMG         := floppy.img


.PHONY: all check_img img clean

all: check_img bootldr kernel

check_img:
	@test -s $(DISKIMG) || {                                    \
		echo "$(DISKIMG) not found!";                           \
		echo "Run \`make img\` to create a blank disk image.";  \
		exit 1;                                                 \
	}

clean:
	$(RM) *.o
	$(RM) *.elf
	$(RM) $(BOOT_TARGET)
	$(RM) $(KERN_TARGET)

img:
	@dd if=/dev/zero of=$(DISKIMG) bs=512 count=2880
	@mke2fs $(DISKIMG)

$(BOOT_TARGET): $(BOOT_TARGET).elf
	objcopy -O binary $< $@
	@dd if=$@ of=$(DISKIMG) bs=512 count=2 conv=notrunc

$(BOOT_TARGET).elf: $(BOOT_OBJ)
	$(LD) $(LFLAGS) -T boot.ld -o $@ $^

$(KERN_TARGET): $(KERN_TARGET).elf
	objcopy -O binary $< $@
	sudo ./copy_kernel.sh

$(KERN_TARGET).elf: $(KERN_OBJ)
	$(LD) $(LFLAGS) -T kernel.ld -o $@ $^

%_asm.o: %.S
	$(AS) $(AFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
