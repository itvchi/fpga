ENTRY(_start)

_estack = ORIGIN(RAM) + LENGTH(RAM);

MEMORY
{
    ROM     (xr)    : ORIGIN = 0x00000000,   LENGTH = 4K
    RAM    (xrw)    : ORIGIN = 0x00020000,   LENGTH = 8K
}

SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        KEEP(*(.entry.start));
        . = ALIGN(4);
        *(.text)
    } > ROM

    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
        . = ALIGN(4);
    } > ROM

    _sidata = LOADADDR(.data);

    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data)
        . = ALIGN(4);
        _edata = .;
    } > RAM AT> ROM

    _sicode = LOADADDR(.code_ram);

    .code_ram (NOLOAD) :
    {
        . = ALIGN(4);
        _scode = .;
        *(.code_ram)
        _ecode = .;
    } > RAM AT> ROM

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