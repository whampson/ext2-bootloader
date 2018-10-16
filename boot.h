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
 *   File: boot.h
 * Author: Wes Hampson
 *----------------------------------------------------------------------------*/

#ifndef __BOOT_H
#define __BOOT_H


/*******************************************
 * Important stuff for kernel developers.
 ******************************************/

#define KERNEL_BASE_SEG     0x2000      /* 128 KiB */
#define KERNEL_BASE_OFF     0x0000
#define KERNEL_BASE         ((KERNEL_BASE_SEG << 4) + KERNEL_BASE_OFF)

#define KERNEL_STACK        0x40000     /* 256 KiB */

#define KERNEL_CS           0x08
#define KERNEL_DS           0x10

#define GDT_BASE            0x7000


/*******************************************
 * For those curious about booting.
 * (These are not necessarily needed after landing in the kernel.)
 ******************************************/

#define BIOS_TTY_OUTPUT     0x0E    /* int 10h */
#define BIOS_READ_DISK      0x02    /* int 13h */

#define RETRY_COUNT         3
#define SECT_PER_CYL        18

#define BLOCK_SIZE          1024
#define EXT2_SUPER_MAGIC    0xEF53

#define STAGE2_BASE         0x7E00
#define STAGE2_SECTOR       1
#define STAGE2_SECTORS      1

#define SUPER_BLOCK_BASE    0x8000
#define SUPER_BLOCK_SECTOR  2
#define SUPER_BLOCK_SECTORS 2

#define GROUP_DESC_BASE     0x8400
#define GROUP_DESC_BLOCK    2
#define GROUP_DESC_COUNT    1

#define INODE_TABLE_BASE    0x1000
#define INODE_COUNT         184
#define INODE_SIZE          128
#define INODE_BLOCKS        (INODE_COUNT / (BLOCK_SIZE / INODE_SIZE))
#define MAX_BLOCKS          12

#define ROOT_DENTRY_BASE    0x8800
#define ROOT_DENTRY_INODE   2

#define BLOCK_BUF           0x9000
#define BLOCK_BUF2          0x9400

/* struct ext2_super_block field offsets */
#define S_LOG_BLOCK_SIZE    24
#define S_INODES_PER_GROUP  40
#define S_MAGIC             56

/* struct ext2_group_desc field offsets */
#define BG_INODE_TABLE      8

/* struct ext2_inode field offsets */
#define I_SIZE              4
#define I_BLOCKS            28
#define I_BLOCK             40

/* struct ext2_dir_entry_2 field offsets */
#define INODE               0
#define REC_LEN             4
#define NAME_LEN            6
#define FILE_TYPE           7
#define NAME                8

/* ext2 i_block indices */
#define EXT2_NDIR_BLOCKS    12                      /* number direct blocks */
#define EXT2_IND_BLOCK      (EXT2_NDIR_BLOCKS)      /* single indirect block */
#define EXT2_DIND_BLOCK     (EXT2_IND_BLOCK + 1)    /* double indirect block */
#define EXT2_TIND_BLOCK     (EXT2_DIND_BLOCK + 1)   /* triple indirect block */
#define EXT2_N_BLOCKS       (EXT2_TIND_BLOCK + 1)   /* total number blocks */

#endif /* __BOOT_H */
