/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
 * Copyright (C) 2018 Wes Hampson. All Rights Reserved.                       *
 *                                                                            *
 * This is free software: you can redistribute it and/or modify               *
 * it under the terms of version 2 of the GNU General Public License          *
 * as published by the Free Software Foundation.                              *
 *                                                                            *
 * See LICENSE in the top-level directory for a copy of the license.          *
 * You may also visit <https://www.gnu.org/licenses/gpl-2.0.txt>.             *
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

/*-----------------------------------------------------------------------------
 *   File: boot.S
 * Author: Wes Hampson
 *   Desc: Stage 1 of the bootloader. Stage 1 is responsible for loading the
 *         kernel image into memory from the disk. It also contains some useful
 *         subroutines.
 *----------------------------------------------------------------------------*/

#include "boot.h"

.section .stage1, "ax", @progbits
.code16

##
# Bootloader entry point.
# Loads the second stage of the bootloader and the kernel image into memory.
##
.globl entry
entry:
    cld
    xorw        %ax, %ax
    movw        %ax, %ds
    movw        %ax, %es
    movw        %ax, %ss
    movw        $0x7C00, %bp
    movw        %bp, %sp
    ljmp        $0, $_check_boot_disk       # load %cs

_check_boot_disk:
    # ensure we booted from a floppy (since that's all we support)
    cmpb        $1, %dl
    ja          diskinval
    movb        %dl, d_diskno

_load_stage2:
    # load stage 2 of the bootloader into memory
    movw        $STAGE2_BASE, %di
    movw        $STAGE2_SECTOR, %ax
    movb        $STAGE2_SECTORS, %cl
    call        read_sectors

_load_super_block:
    # read the superblock into memory
    movw        $SUPER_BLOCK_BASE, %di
    movw        $SUPER_BLOCK_SECTOR, %ax
    movb        $SUPER_BLOCK_SECTORS, %cl
    call        read_sectors

    # check ext2 magic number to ensure the filesystem is valid (naive check)
    movw        $SUPER_BLOCK_BASE, %di
    cmpw        $EXT2_SUPER_MAGIC, S_MAGIC(%di)
    jne         badfs

    # ensure block size is 1024 bytes (since that's all we support)
    movb        S_LOG_BLOCK_SIZE(%di), %cl
    cmpb        $0, %cl
    ja          badfs

_load_group_desc:
    # load block group descriptor
    movw        $GROUP_DESC_BASE, %di
    movw        $GROUP_DESC_BLOCK, %ax
    movb        $GROUP_DESC_COUNT, %cl
    call        read_blocks

_load_inodes:
    # load the inode table into memory
    movw        BG_INODE_TABLE(%di), %ax    # first inode block index
    movw        $INODE_TABLE_BASE, %di
    movw        $INODE_BLOCKS, %cx
_load_inodes_loop:
    pushw       %ax
    pushw       %cx
    movb        $1, %cl
    call        read_blocks
    popw        %cx
    popw        %ax
    incw        %ax
    addw        $BLOCK_SIZE, %di
    loop        _load_inodes_loop

_load_root_dentry:
    # load root directory entry
    #   TODO: this only loads one block, there might be more if there are enough
    #         files on disk
    movw        $ROOT_DENTRY_INODE, %ax
    call        get_inode_addr
    movw        I_BLOCK(%di), %ax
    pushw       I_SIZE(%di)
    movw        $ROOT_DENTRY_BASE, %di
    movb        $1, %cl
    call        read_blocks

    # Need to zero-out the upper bits of ebx and edx here
    # because all 32 bits are used later in a memory address displacement
    xorl        %edx, %edx              # data block index
    xorl        %ebx, %ebx              # data block index
    movw        %di, %bx                # dentry record ptr

_find_kernel:
    # locate the kernel image
    cmpw        4(%bp), %ax            # inode size
    jae         filenotfound
    cmpw        $0, INODE(%bx)
    je          filenotfound
    movw        $TMP_BUF, %di
    leaw        NAME(%bx), %si
    movzbw      NAME_LEN(%bx), %cx
    rep         movsb
    movb        $0, 0(%di)
    movw        $TMP_BUF, %si
    leaw        s_kernelimg, %di
    call        strcmp
    cmpw        $0, %ax
    je          _load_kernel
    movw        REC_LEN(%bx), %ax
    addw        %ax, %bx                # next record pointer
    addw        %ax, %dx                # increment data block index
    jmp         _find_kernel

_load_kernel:
    pushw       %bx
    leaw        s_loading, %si
    call        print
    popw        %bx
    movw        INODE(%bx), %ax         # dentry ptr from find_kernel in bx
    call        get_inode_addr
    movw        %di, %bx
    movl        I_SIZE(%bx), %edx
    movl        %edx, d_kernelsize
    movw        I_BLOCKS(%bx), %si
    xorw        %dx, %dx
    movw        $KERNEL_BASE, %di
_load_kernel_loop:
    cmpw        %si, %dx
    jae         _load_kernel_done
    movw        I_BLOCK(%ebx, %edx, 4), %ax
    movb        $1, %cl
    call        read_blocks
    incw        %dx
    addw        $BLOCK_SIZE, %di
    jmp         _load_kernel_loop
_load_kernel_done:
    jmp         stage2


## ===== SUBROUTINES =====

##
# Halts the system; spins forever... and ever.
##
.globl halt
halt:
    hlt
    jmp         halt


##
# Prints a zero-terminated string to the screen at the current cursor position.
#
#   Inputs: si - address of string to print
#  Outputs: (none)
# Clobbers: ax, bx, si
##
.globl print
print:
    movb        $BIOS_TTY_OUTPUT, %ah
    movw        $0, %bx

_print_loop:
    movb        0(%si), %al
    cmpb        $0, %al
    je          _print_done
    int         $0x10
    incw        %si
    jmp         _print_loop

_print_done:
    ret


##
# Reads one or more blocks from the boot disk.
#
#   Inputs: es:di - destination address
#           ax    - disk block index
#           cl    - number of blocks to read
#  Outputs: ax    - actual number of blocks read
# Clobbers: bx, cx, dx
##
.globl read_blocks
read_blocks:
    # sect_count = block_count << (log_block_size + 1)
    # sect_start = 2 + ((block_start - 1) << (log_block_size + 1))
    cmpw        $0, %ax
    jle         badfs
    movb        %cl, %dl
    movb        $1, %cl
    shlb        %cl, %dl
    decw        %ax
    shlw        %cl, %ax
    addw        $2, %ax
    movb        %dl, %cl
    call        read_sectors
    shrw        $1, %ax
    ret


##
# Reads one or more sectors from the boot disk.
#
#   Inputs: es:di - destination address
#           ax    - disk sector base index (LBA)
#           cl    - number of sectors to read
#  Outputs: ax    - actual number of sectors read
# Clobbers: bx, cx, dx, si
##
.globl read_sectors
read_sectors:
    pushw       %cx                 # save count
    call        lba2chs
    popw        %ax                 # restore count (goes in %al)
    movw        $RETRY_COUNT, %si

_read_sectors_loop:
    decw        %si
    movw        %di, %bx
    movb        d_diskno, %dl
    movb        $BIOS_READ_DISK, %ah
    int         $0x13
    jc          _read_sectors_err
    movzbw      %al, %ax
    ret

_read_sectors_err:
    cmpw        $0, %si
    je          diskerr
    jmp         _read_sectors_loop


##
# Converts a Linear Block Address into a Cylinder Head Sector address.
#
#   Inputs: ax - linear block address
#  Outputs: cx - [15:6] = cylinder, [5:0] = sector
#           dh - head
# Clobbers: ax, bx, dl
##
lba2chs:
    pushw       %ax                 # save lba for later

    # c = lba / (SECT_PER_CYL * 2)
    xorw        %dx, %dx
    movw        $SECT_PER_CYL, %bx
    shlw        $1, %bx
    divw        %bx
    movb        %al, %ch            # bits 7:0 go in %ch
    shrw        $2, %ax
    andb        $0xC0, %al
    movb        %al, %cl            # bits 9:8 go in bits 7:6 of %cl

    # h = (lba % (SECT_PER_CYL * 2)) / SPC
    movw        %dx, %ax            # take remainder from above
    xorw        %dx, %dx
    movw        $SECT_PER_CYL, %bx
    divw        %bx
    movb        %al, %dh

    # s = lba % SECT_PER_CYL + 1
    popw        %ax                 # restore lba
    pushw       %dx                 # save h
    xorw        %dx, %dx
    movw        $SECT_PER_CYL, %bx
    divw        %bx
    incw        %dx
    andb        $0x1F, %dl
    orb         %dl, %cl            # bits 5:0 go in %cl, rest are unused

    popw        %dx                 # restore h
    ret


## ===== FAIL ROUTINES =====

diskerr:
    leaw        s_diskerr, %si
    jmp         _fail

diskinval:
    leaw        s_diskinval, %si
    jmp         _fail

badfs:
    leaw        s_badfs, %si
    jmp         _fail

filenotfound:
    leaw        s_kernelnotfound, %si
    jmp         _fail

_fail:
    call        print
    jmp         halt


## ===== DATA =====

d_diskno:
    .byte           0

d_kernelsize:
    .long           0

s_kernelimg:
    .ascii          "kernel"
    .byte           0

s_loading:
    .ascii          "Loading kernel..."
    .byte           13, 10, 0

s_diskinval:
    .ascii          "Use a floppy!"
    .byte           0

s_diskerr:
    .ascii          "Disk read error!"
    .byte           0

s_badfs:
    .ascii          "Bad file system!"
    .byte           0

s_kernelnotfound:
    .ascii          "Kernel not found!"
    .byte           0
