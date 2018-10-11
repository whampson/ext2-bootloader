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
 *   File: kernel.c
 * Author: Wes Hampson
 *   Desc: A sample "kernel".
 *----------------------------------------------------------------------------*/

#define VIDMEM  0xB8000

void print(char *s)
{
    __asm__ volatile (
        "                               \n\
            movb        $0x0E, %%ah     \n\
            xorw        %%bx, %%bx      \n\
        .loop:                          \n\
            movb        0(%0), %%al     \n\
            cmpb        $0, %%al        \n\
            je          .done           \n\
            int         $0x10           \n\
            incl        %0              \n\
            jmp         .loop           \n\
        .done:                          \n\
        "
        : /* no outputs */
        : "r"(s)
        : "eax", "ebx", "memory"
    );
}

void clear_screen(void)
{
    char *vid_mem;
    int i;

    vid_mem = (char *) VIDMEM;
    for (i = 0; i < 80 * 25; i++) {
        vid_mem[i * 2] = '\0';
    }
}

void kmain(void)
{
    clear_screen();
    /* print("Welcome to the 32-bit kernel! :-)\r\n"); */
}
