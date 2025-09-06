#include "custom_ops.S"

.global _start
.global __maskirq

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
	la t0, _sdata
	la t1, _edata
	la t2, _sidata
	li t3, 0

LoopCopyDataInit:
	add t4, t0, t3
	bge t4, t1, DoneCopyDataInit 
	lw t5, 0(t2)
	sw t5, 0(t4)
	addi t2, t2, 4
	addi t3, t3, 4
	j LoopCopyDataInit

DoneCopyDataInit:

	la t0, _scode
	la t1, _ecode
	la t2, _sicode
	li t3, 0

LoopCopyCodeInit:
	add t4, t0, t3
	bge t4, t1, DoneCopyCodeInit 
	lw t5, 0(t2)
	sw t5, 0(t4)
	addi t2, t2, 4
	addi t3, t3, 4
	j LoopCopyCodeInit

DoneCopyCodeInit:

/* Zero fill the BSS segment. */
	la t0, _sbss
	la t1, _ebss
	li t2, 0

LoopFillZeroBSS:
	bge t0, t1, DoneFillZeroBSS
	sw t2, 0(t0)
	addi t0, t0, 4
	j LoopFillZeroBSS

DoneFillZeroBSS:

	/* Load __mtvec into mtvec register value */
	la t0, __mtvec
    lw t1, 0(t0)
	picorv32_mtvec_insn(t1, t1)

	/* Load current irq_mask register value into __maskirq */
	la t0, __maskirq
	picorv32_maskirq_insn(t1, zero)		
    sw t1, 0(t0)

	call main

inf_loop:	
	j inf_loop

.data
__mtvec:
	.word 0x1100
__maskirq:
    .word 0