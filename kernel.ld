OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(kmain)

SECTIONS
{
    .text 0x1000 :
    {
        LONG(kmain)
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
}
