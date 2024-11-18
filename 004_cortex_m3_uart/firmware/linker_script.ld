ENTRY(Reset_Handler)

MEMORY
{
    flash : ORIGIN = 0x00000000, LENGTH = 0x8000
    ram : ORIGIN = 0x20000000, LENGTH = 0x4000
}

/* Highest address of the user mode stack (end of "RAM" Ram type memory) */
_estack = ORIGIN(ram) + LENGTH(ram);

SECTIONS
{
    .isr_vector :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector)) /* Startup code */
        . = ALIGN(4);
    } > flash

    .text : 
    { 
        *(.text*)
    } > flash

    .rodata : 
    { 
        *(.rodata*) 
    } > flash

    __data_lma_start__ = ALIGN(4);

    .data : AT (__data_lma_start__)
    {	
        __data_vma_start__ = .;
        *(.data*)
        __data_vma_end__ = .;
    } > ram

    .bss :
    {
        __bss_vma_start__ = .;
        *(.bss*)
        __bss_vma_end__ = .;
    } > ram
}