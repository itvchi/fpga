#include "custom_ops.S"

.global _start

.extern irq_init
.weak irq_init

.word _sidata
.word _sdata
.word _edata
.word _estack
.word _sbss
.word _ebss

.section  .entry.start, "ax"
_start:
	la sp, _estack

/* Copy the data segment initializers from FLASH to SRAM */
CopyDataInit: 
	la t0, _sdata
	la t1, _edata
	la t2, _sidata
	li t3, 0

LoopCopyDataInit:
	add t4, t0, t3
	bge t4, t1, CopyCodeInit 
	lw t5, 0(t2)
	sw t5, 0(t4)
	addi t2, t2, 4
	addi t3, t3, 4
	j LoopCopyDataInit

CopyCodeInit:
	la t0, _scode
	la t1, _ecode
	la t2, _sicode
	li t3, 0

LoopCopyCodeInit:
	add t4, t0, t3
	bge t4, t1, FillZeroBSS 
	lw t5, 0(t2)
	sw t5, 0(t4)
	addi t2, t2, 4
	addi t3, t3, 4
	j LoopCopyCodeInit

FillZeroBSS:
	la t0, _sbss
	la t1, _ebss
	li t2, 0

LoopFillZeroBSS:
	bge t0, t1, InitDone
	sw t2, 0(t0)
	addi t0, t0, 4
	j LoopFillZeroBSS

InitDone:
	call irq_init
	call main

inf_loop:
	j inf_loop

/* if irq not enable, this weak hook just returns */
irq_init:
    ret