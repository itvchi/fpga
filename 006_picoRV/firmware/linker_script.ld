ENTRY(_start)

_estack = ORIGIN(RAM) + LENGTH(RAM);

MEMORY
{
    RAM    (xrw)    : ORIGIN = 0x00000000,   LENGTH = 8K
    FLASH   (xr)    : ORIGIN = 0x00020000,   LENGTH = 76K
}

SECTIONS
{
    /* text: test code section */
    . = 0x0;
    .text :
    {
        . = ALIGN(4);
        KEEP(*(.entry.start));
        . = 0x100;
        KEEP(*(.entry.irq_vector))
        . = ALIGN(4);
        *(.text)
    } > RAM
    .rodata :
    {
        *(.rodata)
    } > RAM
    .data :
    {
        *(.data)
    } > RAM
    . = ALIGN(4);
    .bss :
    {
        _sbss = .;
        *(.bss)
        *(.sbss)
        . = ALIGN(4);
        _ebss = .;
    } > RAM
    .flash :
    {
        . = ALIGN(4);
        *(.flash)
    } > FLASH
}