#include "boot.h"

.section .stage2, "ax", @progbits
.code16

.globl load_file
load_file:
    popw        %di
    movw        INODE(%di), %bx
    decw        %bx
    movl        $INODE_TABLE_BASE, %esi
    movl        $INODE_SIZE, %eax
    mulw        %bx
    addl        %eax, %esi
    xorl        %edx, %edx

_load_loop:
    movl        I_BLOCKS(%esi), %eax
    shrl        $1, %eax
    cmpl        %eax, %edx
    jae         start_kernel
    movw        I_BLOCK(%esi, %edx, 4), %ax
    movw        $0x1000, %di
    movb        $1, %cl
    pushl       %esi
    pushl       %edx
    call        read_blocks
    popl        %edx
    popl        %esi
    incl        %edx
    jmp         _load_loop

# TODO: enter protected mode

start_kernel:
    movl        0x1000, %eax
    calll       *%eax
    jmp         halt
