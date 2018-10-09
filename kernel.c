__asm__ (".code16gcc\n");

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

void kmain(void)
{
    print("Welcome to the kernel! :-)\r\n");
}
