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
 *   File: i8042.S
 * Author: Wes Hampson
 *   Desc: Misc. routines for communicating with the Intel 8042 PS/2 Controller.
 *----------------------------------------------------------------------------*/

.code16
.section .stage2, "ax", @progbits

##
# Disables the keyboard.
#
#   Inputs: (none)
#  Outputs: (none)
# Clobbers: al
##
.globl i8042_disable
i8042_disable:
    call    i8042_out_delay
    movb    $0xAD, %al
    outb    %al, $0x64
    ret

##
# Enables the keyboard.
#
#   Inputs: (none)
#  Outputs: (none)
# Clobbers: al
##
.globl i8042_enable
i8042_enable:
    call    i8042_out_delay
    movb    $0xAE, %al
    outb    %al, $0x64
    ret

##
# Wait until input buffer is available for read.
#
#   Inputs: (none)
#  Outputs: (none)
# Clobbers: al
##
.globl i8042_in_delay
i8042_in_delay:
    call    i8042_delay
    inb     $0x64, %al
    testb   $0x01, %al
    jz      i8042_in_delay
    ret

##
# Wait until output buffer is available for write.
#
#   Inputs: (none)
#  Outputs: (none)
# Clobbers: al
##
.globl i8042_out_delay
i8042_out_delay:
    call    i8042_delay
    inb     $0x64, %al
    testb   $0x02, %al
    jnz     i8042_out_delay
    ret

##
# Wait some time before next transaction.
##
i8042_delay:
    xorb    %al, %al
    outb    %al, $0x80
    ret
