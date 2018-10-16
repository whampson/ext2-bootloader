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
    __KERNEL_START = 0x20000;        /* KERNEL_BASE from boot.h */

    .text __KERNEL_START :
    {
        LONG(kmain)     /* kernel entry point, needed for indirect jump */
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

    __KERNEL_SIZE = .;

    .rodata :
    {
        . = __KERNEL_START + (266 * 1024) - __KERNEL_SIZE;
        *(.rodata*)
    }
}
