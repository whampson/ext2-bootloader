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
 *   File: kernel.ld
 * Author: Wes Hampson
 *----------------------------------------------------------------------------*/

OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(kmain)

SECTIONS
{
    __KERNEL_BASE = 0x10000;    /* KERNEL_BASE from boot.h */

    .text __KERNEL_BASE :
    {
        LONG(kmain)             /* entry point address */
        *(.text*)
    }

    .data :
    {
        *(.data*)
    }

    .bss :
    {
        *(.bss*)
    }

    .rodata :
    {
        *(.rodata*)
    }

    __KERNEL_SIZE = .;
}
