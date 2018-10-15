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
 *   File: boot.ld
 * Author: Wes Hampson
 *----------------------------------------------------------------------------*/

OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(entry)

SECTIONS
{
    .stage1 0x7C00 : AT (0x0000)
    {
        *(.stage1)
        *(.data1)

        ASSERT(. <= 0x01FE, "Stage 1 does not fit inside boot sector!");

        . = 0x1FE;
        SHORT(0xAA55)   /* boot sector magic number */
    }

    .stage2 0x7E00 : AT (0x0200)
    {
        *(.stage2)
        *(.data2)

        ASSERT(. <= 0x0200, "Stage 2 does not fit inside boot block!");
        . = 0x0200;
    }
}
