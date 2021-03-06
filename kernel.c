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
 *   Desc: A sample kernel.
 *----------------------------------------------------------------------------*/

/*
 * VGA framebuffer address
 */
#define FB_PTR          0xB8000

/*
 * Screen dimensions
 */
#define ROWS            25
#define COLS            80
#define SCREEN_AREA     (ROWS * COLS)

/*
 * VGA colors
 */
#define VGA_BLK         0x00
#define VGA_BLU         0x01
#define VGA_GRN         0x02
#define VGA_CYN         0x03
#define VGA_RED         0x04
#define VGA_MGA         0x05
#define VGA_BRN         0x06
#define VGA_GRY         0x07

/*
 * Text mode color scheme.
 * Bits [7:4] are background color
 * Bits [3:0] are foreground color
 */
#define COLOR_SCHEME    ((VGA_BLU << 4) | VGA_GRY)

/**
 * Blanks the screen and fills the background with the default color.
 */
void clear_screen(void)
{
    char *vid_mem;
    int i, k;

    vid_mem = (char *) FB_PTR;
    for (i = 0, k = 0; i < SCREEN_AREA; i++, k += 2) {
        vid_mem[k] = '\0';
        vid_mem[k + 1] = COLOR_SCHEME;
    }
}

/**
 * Prints a string to the screen at the top-left corner.
 */
void print(char *s)
{
    char *vid_mem;
    int i;
    char c;

    vid_mem = (char *) FB_PTR;
    i = 0;

    while ((c = *(s++)) != '\0') {
        switch (c) {
            case '\r':
                i -= (i % COLS);
                break;
            case '\n':
                i += COLS;
                break;
            default:
                vid_mem[i << 1] = c;
                i++;
        }
    }
}

/**
 * The kernel entry point.
 */
void kmain(void)
{
    clear_screen();
    print("Welcome to the 32-bit kernel! :-)\r\n");
}
