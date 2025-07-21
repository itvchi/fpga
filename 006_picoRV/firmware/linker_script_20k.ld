ENTRY(_start)

_estack = ORIGIN(RAM) + LENGTH(RAM);

MEMORY
{
    /* Not used yet - TODO :
    - correct flash address
    - move bootloader_20k into ROM section */
    ROM     (xr)    : ORIGIN = 0x00000000,   LENGTH = 1K
    FLASH   (xr)    : ORIGIN = 0x00010000,   LENGTH = 32K
    RAM    (xrw)    : ORIGIN = 0x00020000,   LENGTH = 8K
}

SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        KEEP(*(.entry.start));
        . = 0x100;
        KEEP(*(.entry.irq_vector))
        . = ALIGN(4);
        *(.text)
    } > FLASH

    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
        . = ALIGN(4);
    } > FLASH

    _sidata = LOADADDR(.data);

    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data)
        . = ALIGN(4);
        _edata = .;
    } > RAM AT> FLASH

    _sicode = LOADADDR(.code_ram);

    .code_ram :
    {
        . = ALIGN(4);
        _scode = .;
        *(.code_ram)
        _ecode = .;
    } > RAM AT> FLASH

    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.sbss)
        . = ALIGN(4);
        _ebss = .;
    } > RAM
}