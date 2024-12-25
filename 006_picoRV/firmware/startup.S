#include "custom_ops.S"

.global _start
.global __maskirq

.word _estack
.word _sbss
.word _ebss

.section  .entry.start
_start:
	la sp, _estack

/* Zero fill the BSS segment. */
/* This is not necessary in this case, because CPU runs code from RAM
	and all other sections of memory are initialized with data from code */
	la t0, _sbss
	la t1, _ebss
	li t2, 0

LoopFillZeroBSS:
	bge t0, t1, DoneFillZeroBSS
	sw t2, 0(t0)
	addi t0, t0, 4
	j LoopFillZeroBSS

DoneFillZeroBSS:
	la t0, leds
	sw t2, 0(t0)

	la t0, __maskirq
	picorv32_maskirq_insn(t1, zero)		
    sw t1, 0(t0)
	call main

inf_loop:	
	j inf_loop

.data
__maskirq:
    .word 0