OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(entry)

SECTIONS
{
    .stage1 0x7C00 : AT (0x0000)
    {
        *(.stage1)

        ASSERT(. <= 0x01FE, "Stage 1 does not fit inside boot sector!");

        . = 0x1FE;
        SHORT(0xAA55)   /* boot sector magic */
    }

    .stage2 0x7E00 : AT (0x0200)
    {
        *(.stage2)

        ASSERT(. <= 0x0200, "Stage 2 does not fit inside boot block!");
        . = 0x0200;
    }
}
