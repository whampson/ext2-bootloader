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
 *   File: a20.S
 * Author: Wes Hampson
 *   Desc: Ensures address line 20 is enabled.
 *----------------------------------------------------------------------------*/

.code16
.section .stage2, "ax", @progbits

##
# Attempts to enable the A20 address line using several methods.
# If all attempts fail, an error message will be displayed and the boot process
# will halt.
#
# The following methods are used to try to enable the A20 line:
#   BIOS interrupt
#   PS/2 controller
#
#   Inputs: (none)
#  Outputs: (none)
# Clobbers: ax, bx, cx, fs
##
.globl a20_enable
a20_enable:
    movw    _a20_enable_jmptbl_count, %cx

_a20_enable_loop:
    call    a20_test_enabled
    cmpw    $1, %ax
    je      _a20_enable_success

    decw    %cx
    js      _a20_enable_fail

    # Use loop counter as index into jumptable.
    # Keep trying methods to enable A20 until it works!
    call    *_a20_enable_jmptbl(, %ecx, 2)
    jmp     _a20_enable_loop

_a20_enable_fail:
    leaw    s_a20_enable_fail, %bx
    call    print
    movw    $-1, %ax
    ret

_a20_enable_success:
    movw    $0, %ax
    ret

s_a20_enable_fail:
    .ascii  "Failed to enable A20 line!"
    .byte   13, 10, 0

_a20_enable_jmptbl:
    .word   a20_enablefunc_fast
    .word   a20_enablefunc_i8042
    .word   a20_enablefunc_bios
_a20_enable_jmptbl_count:
    .word   (. - _a20_enable_jmptbl) / 2


##
# Enables the A20 address line using a BIOS interrupt.
# Not supported on many systems.
#
#   Inputs: (none)
#  Outputs: (none)
# Clobbers: ax
##
a20_enablefunc_bios:
    mov     $0x2401, %ax
    int     $0x15
    ret


##
# Enables the A20 address line using the PS/2 controller.
# Supported on most (all?) systems.
#
#   Inputs: (none)
#  Outputs: (none)
# Clobbers: ax
##
a20_enablefunc_i8042:
    call    i8042_disable

    call    i8042_out_delay
    movb    $0xD0, %al      # cmd: read PS/2 output port
    outb    %al, $0x64      # send cmd

    call    i8042_in_delay
    inb     $0x60, %al      # data in: output port status
    pushw   %ax

    call    i8042_out_delay
    movb    $0xD1, %al      # cmd: write PS/2 output port
    outb    %al, $0x64      # send cmd

    call    i8042_out_delay
    popw    %ax
    orb     $0x02, %al      # set A20 bit
    outb    %al, $0x60      # send data

    call    i8042_enable
    ret


##
# Enables the A20 address line using the "fast" method (a single outb).
# Supported on some systems.
#
#   Inputs: (none)
#  Outputs: (none)
# Clobbers: al
##
a20_enablefunc_fast:
    inb     $0x92, %al
    testb   $0x02, %al
    jnz     _a20_enablefunc_fast_done
    orb     $0x02, %al
    outb    %al, $0x92

_a20_enablefunc_fast_done:
    ret


##
# Tests whether the A20 address line is enabled.
#
# Methodology:
#   Test whether memory "wraps around" when using a 21-bit segmented
#   address. We can use the bootsector identifier as a marker. If A20 is NOT
#   enabled, segment addresses 0000:7CFE and FFFF:7EOE will map to the same
#   physical address (whose value is 0xAA55, i.e. the bootsector ID). If
#   the values at these two addresses are different, then the A20 line is
#   enabled.
#
#   Inputs: (none)
#  Outputs: ax set to 1 if enabled,
#           ax set to 0 if disabled
# Clobbers: ax, fs
##
.globl a20_test_enabled
a20_test_enabled:
    pushw   %bx
    pushw   %cx
    movw    $1, %cx

_a20_test_loop:
    movw    $0xFFFF, %ax
    movw    %ax, %fs
    movw    %fs:0x7E0E, %bx         # read "wrapped around" address
    xorw    %ax, %ax
    movw    %ax, %fs
    cmpw    %bx, %fs:0x7DFE         # compare with bootsect ID
    jne     _a20_test_true

    # The values were equal! Ensure it wasn't a fluke.
    # Alter the bootsector ID and recompare.
    cmpw    $0, %cx
    je      _a20_test_done
    decw    %cx
    rorw    $8, %bx
    movw    %bx, %fs:0x7DFE
    jmp     _a20_test_loop

_a20_test_true:
    movw    $1, %ax

_a20_test_done:
    popw    %cx
    popw    %bx
    ret
