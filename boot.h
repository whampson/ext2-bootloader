#ifndef __BOOT_H
#define __BOOT_H

#define STAGE2_BASE         0x7E00
#define STAGE2_SECTOR       1
#define STAGE2_SECTORS      1

#define SUPER_BLOCK_BASE    0x8000
#define SUPER_BLOCK_SECTOR  2
#define SUPER_BLOCK_SECTORS 2

/* struct ext2_super_block fields */
#define S_LOG_BLOCK_SIZE    24
#define S_INODES_PER_GROUP  40
#define S_MAGIC             56

#define EXT2_SUPER_MAGIC    0xEF53

#define GROUP_DESC_BASE     0x9000
#define GROUP_DESC_BLOCK    2

/* struct ext2_group_desc fields */
#define BG_INODE_TABLE      8

#define INODE_TABLE_BASE    0xA000
#define NUM_INODES          184
#define INODE_SIZE          128
#define NUM_INODE_BLOCKS    (NUM_INODES / (1024 / INODE_SIZE))

/* struct ext2_inode fields */
#define I_SIZE              4
#define I_BLOCKS            28
#define I_BLOCK             40

/* struct ext2_dir_entry_2 fields */
#define INODE               0
#define REC_LEN             4
#define NAME_LEN            6
#define FILE_TYPE           7
#define NAME                8

#endif /* __BOOT_H */
