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
#   Desc: This Makefile compiles the bootloader and kernel image. Both files can
#         also be injected into a floppy disk image using this Makefile.
#         The kernel is provided only for demonstration. You should be able to
#         "slot-in" your own kernel with minimal modifications to the bootloader
#         (e.g. kernel base address).
#-------------------------------------------------------------------------------

# Common compiler/assembler options
GCC_WARNINGS    := -Wall -Wextra -Wpedantic

# Compiler/assembler/linker setup
AS              := gcc
AFLAGS          := $(GCC_WARNINGS) -D__ASM -g -m32
CC              := gcc
CFLAGS          := $(GCC_WARNINGS) -g -Og -m32 -std=c99 -ffreestanding         \
                   -nostdinc -fno-pic -fno-stack-protector -fno-unwind-tables  \
                   -fno-asynchronous-unwind-tables
LD              := ld
LFLAGS          :=

# Source files
BOOT_SRC        := boot.S stage2.S a20.S    # boot.S MUST be first
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

# Misc.
DISKIMG         := floppy.img
FLOPPYDEV       := /dev/fd0
MOUNTDIR        := /tmp/fdimg0
SHUTUP          := /dev/null 2>&1

.PHONY: all img floppy clean

all: $(BOOT_TARGET)

img: $(BOOT_TARGET) $(KERN_TARGET)
	@test -s $(DISKIMG) || {                                            \
		echo ">> Creating floppy image...";                             \
		dd if=/dev/zero of=$(DISKIMG) bs=512 count=2880 > $(SHUTUP);    \
		mke2fs $(DISKIMG) > $(SHUTUP);                                  \
	}
	@echo ">> Copying bootloader..."
	@dd if=$(BOOT_TARGET) of=$(DISKIMG) bs=512 conv=notrunc > $(SHUTUP)
	@echo ">> Copying kernel image..."
	@{                                                                  \
		sudo mkdir $(MOUNTDIR);                                         \
		sudo mount $(DISKIMG) $(MOUNTDIR);                              \
		sudo cp $(KERN_TARGET) $(MOUNTDIR);                             \
		sudo umount $(MOUNTDIR);                                        \
		sudo rm -rf $(MOUNTDIR);                                        \
	}

floppy: img
	@echo "Writing floppy disk..."
	@sudo dd if=$(DISKIMG) of=$(FLOPPYDEV) bs=512

clean:
	$(RM) *.o
	$(RM) *.elf
	$(RM) $(BOOT_TARGET)
	$(RM) $(KERN_TARGET)

$(BOOT_TARGET): $(BOOT_TARGET).elf
	objcopy -O binary $< $@

$(BOOT_TARGET).elf: $(BOOT_OBJ)
	$(LD) $(LFLAGS) -T boot.ld -o $@ $^

$(KERN_TARGET): $(KERN_TARGET).elf
	objcopy -O binary $< $@

$(KERN_TARGET).elf: $(KERN_OBJ)
	$(LD) $(LFLAGS) -T kernel.ld -o $@ $^

%_asm.o: %.S
	$(AS) $(AFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
