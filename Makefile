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
#------------------------------------------------------------------------------#

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
BOOT_SRC        := boot.S stage2.S          # boot.S MUST be first
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