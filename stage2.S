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
 *   File: stage2.S
 * Author: Wes Hampson
 *   Desc: Stage 2 of the bootloader. Stage 1 is responsible for getting the
 *         CPU into Protected Mode and calling the kernel. It also contains some
 *         subroutines used throughout the booting process.
 *----------------------------------------------------------------------------*/

#include "boot.h"

PIC_M_CMD   = 0x21
PIC_S_CMD   = 0xA1

.section .stage2, "ax", @progbits
.code16

.globl stage2
stage2:
    # kill interrupts
    cli
    movb        $0xFF, %al
    outb        %al, $PIC_M_CMD
    outb        %al, $PIC_S_CMD

    # enable A20
    call        a20_enable

    # move GDT
    xorw        %ax, %ax
    movw        %ax, %es
    leal        gdt_base, %esi
    movl        $GDT_BASE, %edi
    movzwl      d_gdt_ptr, %ecx     # GDT size
    incl        %ecx
    rep         movsb

    # enter Protected Mode
    lgdt        d_gdt_ptr
    movl        %cr0, %eax
    orl         $0x01, %eax
    movl        %eax, %cr0
    ljmp        $KERNEL_CS, $entry32

.code32
entry32:
    movw        $KERNEL_DS, %ax
    movw        %ax, %ds
    movw        %ax, %es
    movw        %ax, %fs
    movw        %ax, %gs
    movw        %ax, %ss
    movl        $KERNEL_STACK, %ebp
    movl        %ebp, %esp

_start_kernel:
    movl        KERNEL_BASE, %eax
    call        *%eax

_halt:
    hlt
    jmp         _halt

## ===== SUBROUTINES (16-bit) =====
.code16

##
# Gets the base address of an inode.
#
#   Inputs: ax  - inode number
#  Outputs: di  - inode base address
# Clobbers: ax, dx
##
.globl get_inode_addr
get_inode_addr:
    cmpw        $1, %ax
    jb          badfs
    cmpw        $INODE_COUNT, %ax
    ja          badfs
    movw        $INODE_TABLE_BASE, %di
    decw        %ax
    movw        $INODE_SIZE, %dx
    mulw        %dx
    addw        %ax, %di
    ret

##
# Loads a file from the disk into memory.
#
# TODO: Support indirect block indexing.
#
#   Inputs: es:di - destination address
#           ax    - inode number
#  Outputs: file contents loaded at es:di
# Clobbers: ax, ebx, cx, edx, si, di
##
.globl load_file
load_file:
    pushw       %di
    call        get_inode_addr
    movzwl      %di, %ebx
    popw        %di
    movw        I_BLOCKS(%bx), %si  # max num 512-byte blocks used for file
    shrw        $1, %si             #   converted to 1024-byte blocks
    xorl        %edx, %edx

_load_loop:
    movw        I_BLOCK(%ebx, %edx, 4), %ax
    cmpw        $0, %ax
    je          _load_done

    cmpw        $EXT2_IND_BLOCK, %dx
    je          _do_load_ind_blk
    ja          _load_fail

_do_load_dir_blk:
    call        _load_dir_blk
    jmp         _load_loop

_do_load_ind_blk:
    call        _load_ind_blk
    jmp         _load_loop

_load_dir_blk:
    movb        $1, %cl
    call        read_blocks
    incw        %dx
    addw        $BLOCK_SIZE, %di
    cmpw        $0, %di
    jne         _load_dir_blk_done
    movw        %es, %cx
    addw        $0x1000, %cx
    movw        %cx, %es

_load_dir_blk_done:
    ret

_load_ind_blk:
    pushl       %ebx
    pushl       %edx
    pushw       %es
    pushw       %di
    xorw        %bx, %bx
    movw        %bx, %es
    movw        $BLOCK_BUF, %di
    movb        $1, %cl
    call        read_blocks
    movzwl      %di, %ebx
    popw        %di
    popw        %es
    xorl        %edx, %edx

_load_ind_blk_loop:
    cmpw        $256, %dx
    jae         _load_ind_blk_done
    movw        0(%ebx, %edx, 4), %ax
    cmpw        $0, %ax
    je          _load_ind_blk_done
    call        _load_dir_blk
    jmp         _load_ind_blk_loop

_load_ind_blk_done:
    popl        %edx
    popl        %ebx
    incw        %dx
    ret

_load_fail:
    leaw        s_filetoolarge, %si
    jmp         fail

_load_done:
    ret

##
# Compares two strings.
#
#   Inputs: si - pointer to string 1
#           di - pointer to string 2
#  Outputs: ax - comparison result
#                < 0: str1 < str2
#                > 0: str1 > str2
#                = 0: str1 = str2
# Clobbers: si, di
##
.globl strcmp
strcmp:
    pushw       %dx
_strcmp_loop:
    cmpb        $0, (%si)
    je          _strcmp_less
    movb        (%si), %dl
    cmpb        %dl, (%di)
    jb          _strcmp_less
    ja          _strcmp_more
    cmpb        $0, %dl
    je          _strcmp_done
    incw        %si
    incw        %di
    jmp         _strcmp_loop

_strcmp_less:
    cmpb        $0, (%di)
    je          _strcmp_equal
    movw        $-1, %ax
    jmp         _strcmp_done

_strcmp_more:
    movw        $1, %ax
    jmp         _strcmp_done

_strcmp_equal:
    xorw        %ax, %ax

_strcmp_done:
    popw        %dx
    ret

## ===== DATA =====
.section .data2

gdt_base:
    .quad       0x0000000000000000  # (null entry)
    .quad       0x00CF9A000000FFFF  # KERNEL_CS = 0x08
    .quad       0x00CF92000000FFFF  # KERNEL_DS = 0x10
gdt_end:

.align 4
d_gdt_ptr:
    .word       gdt_end - gdt_base - 1
    .long       GDT_BASE
    .word       0           # padding

s_filetoolarge:
    .ascii      "File is too large!"
    .byte       0
