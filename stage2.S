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
 *----------------------------------------------------------------------------*/

#include "boot.h"

PIC_M_CMD   = 0x21
PIC_S_CMD   = 0xA1

KERNEL_CS   = 0x08
KERNEL_DS   = 0x10

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
    movl        $0x40000, %ebp
    movl        %ebp, %esp

_start_kernel:
    movl        KERNEL_BASE, %eax
    call        *%eax

_halt:
    hlt
    jmp         _halt

## ===== SUBROUTINES =====

##
# Gets the base address of an inode.
#
#   Inputs: ax  - inode number
#  Outputs: di  - inode base address
# Clobbers: ax, dx
##
.code16
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



.globl print_hex
print_hex:
    pushl       %esi
    pushw       %bx
    pushw       %cx
    movl        $5, %ecx
    leal        s_hex, %esi
_print_hex_loop:
    movw        %ax, %bx
    andb        $0x0F, %bl
    cmpb        $9, %bl
    ja          _print_hex_letter
    addb        $0x30, %bl
    jmp         _print_hex_char

_print_hex_letter:
    addb        $0x37, %bl

_print_hex_char:
    movb        %bl, (%esi, %ecx)
    rorw        $4, %ax
    decl        %ecx
    cmpl        $1, %ecx
    ja          _print_hex_loop
    call        print
    popw        %cx
    popw        %bx
    popl        %esi
    ret

## ===== DATA =====

.align 16
gdt_base:
    .quad       0x0000000000000000  # (null entry)
    .quad       0x00CF9A000000FFFF  # KERNEL_CS = 0x08
    .quad       0x00CF92000000FFFF  # KERNEL_DS = 0x10
gdt_limit:

.align 4
d_gdt_ptr:
    .word       gdt_limit - gdt_base - 1
    .long       gdt_base
    .word       0

s_hex:
    .ascii      "0xXXXX"
    .byte       13, 10, 0
