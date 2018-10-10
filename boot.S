#include "boot.h"

RETRY_COUNT = 3

.section .stage1, "ax", @progbits
.code16

.globl entry
entry:
    cld
    ljmp        $0, $set_regs           # reload %cs

set_regs:
    xorw        %ax, %ax
    movw        %ax, %ds
    movw        %ax, %es
    movw        %ax, %ss
    movw        $0x7C00, %bp
    movw        %bp, %sp

check_boot_disk:
    cmpb        $1, %dl
    ja          diskinval
    movb        %dl, d_diskno

load_stage2:
    movw        $STAGE2_BASE, %di
    movw        $STAGE2_SECTOR, %ax
    movb        $STAGE2_SECTORS, %cl
    call        read_sectors

load_super_block:
    movw        $SUPER_BLOCK_BASE, %di
    movw        $SUPER_BLOCK_SECTOR, %ax
    movb        $SUPER_BLOCK_SECTORS, %cl
    call        read_sectors

    movw        $SUPER_BLOCK_BASE, %di
    cmpw        $EXT2_SUPER_MAGIC, S_MAGIC(%di)
    jne         badfs

    # Ensure block size of 1024
    movb        S_LOG_BLOCK_SIZE(%di), %cl
    cmpb        $0, %cl
    ja          badblocksize

load_group_desc:
    movw        $GROUP_DESC_BASE, %di
    movw        $GROUP_DESC_BLOCK, %ax
    movb        $1, %cl                 # assuming 1 group for floppy disks (TODO error)
    call        read_blocks

load_inodes:
    movw        BG_INODE_TABLE(%di), %ax
    movw        $INODE_TABLE_BASE, %di
    movb        $NUM_INODE_BLOCKS, %cl
    call        read_blocks

    addw        $INODE_SIZE, %di
    movw        I_BLOCK(%di), %ax
    pushw       %di
    movw        $0x9400, %di
    movb        $1, %cl
    call        read_blocks

    xorw        %cx, %cx
dir_list_loop:
    cmpl        $0, INODE(%di)
    je          filenotfound
    popw        %si
    cmpw        I_SIZE(%si), %cx
    jae         filenotfound
    pushw       %si
    pushw       %cx
    leaw        NAME(%di), %si
    movzbw      NAME_LEN(%di), %cx
    pushw       %di
    pushw       %cx
    movw        $0x9800, %di
    rep         movsb
    popw        %si
    movb        $0, 0x9800(%si)
    movw        $0x9800, %si
    leaw        s_file, %di
    call        strcmp
    cmpw        $0, %ax
    je          load_file
    popw        %di
    popw        %cx
    movw        REC_LEN(%di), %ax
    addw        %ax, %cx
    addw        %ax, %di
    jmp         dir_list_loop



## ===== SUBROUTINES =====

TTY_OUTPUT  = 0x0E  # int 10h command to print a string
READ_FLOPPY = 0x02  # int 13h command to read from floppy
SPC         = 18    # sectors per cylinder (for a 3.5in 1.44MB floppy)

##
# Halts the system; spins forever... and ever.
##
.globl halt
halt:
    hlt
    jmp         halt


##
# Prints a zero-terminated string to the screen at the current cursor position.
#
#   Inputs: si - address of string to print
#  Outputs: (none)
# Clobbers: ax, bx, si
##
.globl print
print:
    movb        $TTY_OUTPUT, %ah
    movw        $0, %bx

_print_loop:
    movb        0(%si), %al
    cmpb        $0, %al
    je          _print_done
    int         $0x10
    incw        %si
    jmp         _print_loop

_print_done:
    ret


##
# Reads one or more blocks from the boot disk.
#
#   Inputs: es:di - destination address
#           ax    - disk block index
#           cl    - num. blocks to read
#  Outputs: (none)
# Clobbers: ax, bx, cx, dx
##
.globl read_blocks
read_blocks:
    # sect_count = block_count << (log_block_size + 1)
    # sect_start = 2 + ((block_start - 1) << (log_block_size + 1))
    cmpw    $0, %ax
    jle     badblock
    movb    %cl, %dl
    movb    $1, %cl
    shlb    %cl, %dl
    decw    %ax
    shlw    %cl, %ax
    addw    $2, %ax
    movb    %dl, %cl
    call    read_sectors
    ret


##
# Reads one or more sectors from the boot disk.
#
#   Inputs: es:di - destination address
#           ax    - disk sector base index (LBA)
#           cl    - num. sectors to read
#  Outputs: (none)
# Clobbers: ax, bx, cx, dx
##
.globl read_sectors
read_sectors:
    pushw       %si
    pushw       %cx                 # save count
    call        lba2chs
    popw        %ax                 # restore count (goes in %al)
    movw        $RETRY_COUNT, %si

_read_sectors_loop:
    decw        %si
    movw        %di, %bx
    movb        d_diskno, %dl
    movb        $READ_FLOPPY, %ah
    int         $0x13
    jc          _read_sectors_err
    popw        %si
    ret

_read_sectors_err:
    cmpw        $0, %si
    je          diskerr
    jmp         _read_sectors_loop


##
# Converts a Linear Block Address into a Cylinder Head Sector address.
#
#   Inputs: ax - linear block address
#  Outputs: cx - [15:6] = cylinder, [5:0] = sector
#           dh - head
# Clobbers: ax, bx, dl
##
lba2chs:
    pushw       %ax                 # save lba for later

    # c = lba / (SPC * 2)
    xorw        %dx, %dx
    movw        $SPC, %bx
    shlw        $1, %bx
    divw        %bx
    movb        %al, %ch            # bits 7:0 go in %ch
    shrw        $2, %ax
    andb        $0xC0, %al
    movb        %al, %cl            # bits 9:8 go in bits 7:6 of %cl

    # h = (lba % (SPC * 2)) / SPC
    movw        %dx, %ax            # take remainder from above
    xorw        %dx, %dx
    movw        $SPC, %bx
    divw        %bx
    movb        %al, %dh

    # s = lba % SPC + 1
    popw        %ax                 # restore lba
    pushw       %dx                 # save h
    xorw        %dx, %dx
    movw        $SPC, %bx
    divw        %bx
    incw        %dx
    andb        $0x1F, %dl
    orb         %dl, %cl            # bits 5:0 go in %cl, rest are unused

    popw        %dx                 # restore h
    ret


##
# Compares two strings.
#
#   Inputs: si - pointer to string 1
#           di - pointer to string 2
#  Outputs: ax - comparison result
#                < 0: str1 < str2
#                > 0: str1 > str2
#                = 0: str1 = str2
# Clobbers: dl, si, di
##
.globl strcmp
strcmp:
_strcmp_loop:
    cmpb        $0, (%si)
    je          _strcmp_less
    movb        (%si), %dl
    cmpb        %dl, (%di)
    jb          _strcmp_less
    ja          _strcmp_more
    cmpb        $0, %dl
    je          _strcmp_done
    incw        %si
    incw        %di
    jmp         _strcmp_loop

_strcmp_less:
    cmpb        $0, (%di)
    je          _strcmp_equal
    movw        $-1, %ax
    jmp         _strcmp_done

_strcmp_more:
    movw        $1, %ax
    jmp         _strcmp_done

_strcmp_equal:
    xorw        %ax, %ax

_strcmp_done:
    ret


## ===== FAIL ROUTINES =====

diskerr:
    leaw        s_diskerr, %si
    jmp         _fail

diskinval:
    leaw        s_diskinval, %si
    jmp         _fail

badfs:
    leaw        s_badfs, %si
    jmp         _fail

badblock:
    leaw        s_badblock, %si
    jmp         _fail

badblocksize:
    leaw        s_badblocksize, %si
    jmp         _fail

filenotfound:
    leaw        s_filenotfound, %si
    jmp         _fail

_fail:
    call        print
    jmp         halt


## ===== DATA =====

d_diskno:
    .byte           0

s_file:
    .ascii          "kernel"
    .byte           0

s_diskinval:
    .ascii          "Invalid disk type!"
    .byte           0

s_diskerr:
    .ascii          "Disk read error!"
    .byte           0

s_badfs:
    .ascii          "Bad file system!"
    .byte           0

s_badblock:
    .ascii          "Bad block index!"
    .byte           0

s_badblocksize:
    .ascii          "Invalid block size!"
    .byte           0

s_filenotfound:
    .ascii          "File not found!"
    .byte           0
