.syntax unified
.cpu cortex-m3
.arch armv7-m
.fpu softvfp
.thumb

.global  g_pfnVectors
.global  Default_Handler


/* start address for the initialization values of the .data section. 
defined in linker script */
.word  __data_lma_start__
/* start address for the .data section. defined in linker script */  
.word  __data_vma_start__
/* end address for the .data section. defined in linker script */
.word  __data_vma_end__
/* start address for the .bss section. defined in linker script */
.word  __bss_vma_start__
/* end address for the .bss section. defined in linker script */
.word  __bss_vma_end__


/**
 * @brief  This is the code that gets called when the processor first
 *          starts execution following a reset event. Only the absolutely
 *          necessary set is performed, after which the application
 *          supplied main() routine is called. 
 * @param  None
 * @retval : None
*/
.section  .text.Reset_Handler
.weak  Reset_Handler
.type  Reset_Handler, %function

Reset_Handler:  
    ldr   sp, =_estack /* set stack pointer */

/* Copy the data segment initializers from flash to SRAM */  
    ldr r0, =__data_vma_start__
    ldr r1, =__data_vma_end__
    ldr r2, =__data_lma_start__
    movs r3, #0
    b LoopCopyDataInit

CopyDataInit:
    ldr r4, [r2, r3]
    str r4, [r0, r3]
    adds r3, r3, #4

LoopCopyDataInit:
    adds r4, r0, r3
    cmp r4, r1
    bcc CopyDataInit

/* Zero fill the bss segment. */
    ldr r2, =__bss_vma_start__
    ldr r4, =__bss_vma_end__
    movs r3, #0
    b LoopFillZerobss

FillZerobss:
    str  r3, [r2]
    adds r2, r2, #4

LoopFillZerobss:
    cmp r2, r4
    bcc FillZerobss

/* Call static constructors */
    @ bl __libc_init_array
/* Call the application's entry point.*/
    bl  main
    bx  lr    
.size  Reset_Handler, .-Reset_Handler


/**
 * @brief  This is the code that gets called when the processor receives an 
 *         unexpected interrupt.  This simply enters an infinite loop, preserving
 *         the system state for examination by a debugger.
 * @param  None     
 * @retval None       
*/
.section  .text.Default_Handler,"ax",%progbits

Default_Handler:
Infinite_Loop:
    b  Infinite_Loop
.size  Default_Handler, .-Default_Handler


/******************************************************************************
*
* The minimal vector table for a Cortex M3. Note that the proper constructs
* must be placed on this to ensure that it ends up at physical address
* 0x0000.0000.
* 
*******************************************************************************/
.section .isr_vector,"a",%progbits
.type g_pfnVectors, %object

	/* Interrupt vector table: Gowin doc IPUG922-1.1E */
g_pfnVectors:
	.word _estack               /* main stack ptr at end of 16384 bytes of SRAM */
	.word Reset_Handler         /*  1: reset, +1 sets bit for thumb mode */
	.word NMI_Handler           /*  2: NMI */
	.word HardFault_Handler     /*  3: hard fault */
	.word MemManage_Handler     /*  4: mem manage */
	.word BusFault_Handler      /*  5: bus fault */
	.word UsageFault_Handler    /*  6: usage fault */
	.word 0                     /*  7: res */
	.word 0                     /*  8: res */
	.word 0                     /*  9: res */
	.word 0                     /* 10: res */
	.word SVC_Handler           /* 11: svcall */
	.word DebugMon_Handler      /* 12: debug mon */
	.word 0                     /* 13: res */
	.word PendSV_Handler        /* 14: pend SV */
	.word SysTick_Handler       /* 15: sys tick */

    /* External Interrupts */
	.word 0                     /* 16: UART0 RX and TX */
	.word 0                     /* 17: UART1 RX and TX */
	.word 0                     /* 18: timer 0 */
	.word 0                     /* 19: timer 1 */
	.word 0                     /* 20: GPIO port 0 combined */
	.word 0                     /* 21: UART0,1 overflow */
	.word 0                     /* 22: RTC */
	.word 0                     /* 23: I2C */
	.word 0                     /* 24: int 8 */
	.word 0                     /* 25: ETH */
	.word 0                     /* 26: int 10 */
	.word 0                     /* 27: int 11 */
	.word 0                     /* 28: int 12 */
	.word 0                     /* 29: int 13 */
	.word 0                     /* 30: int 14 */
	.word 0                     /* 31: int 15 */
	.word 0                     /* 32: GPIO0_0 */
	.word 0                     /* 33: GPIO0_1 */
	.word 0                     /* 34: GPIO0_2 */
	.word 0                     /* 35: GPIO0_3 */
	.word 0                     /* 36: GPIO0_4 */
	.word 0                     /* 37: GPIO0_5 */
	.word 0                     /* 38: GPIO0_6 */
	.word 0                     /* 39: GPIO0_7 */
	.word 0                     /* 40: GPIO0_8 */
	.word 0                     /* 41: GPIO0_9 */
	.word 0                     /* 42: GPIO0_10 */
	.word 0                     /* 43: GPIO0_11 */
	.word 0                     /* 44: GPIO0_12 */
	.word 0                     /* 45: GPIO0_13 */
	.word 0                     /* 46: GPIO0_14 */
	.word 0                     /* 47: GPIO0_15 */
	.word 0                     /* 48: User int 0 */
	.word 0                     /* 49: User int 1 */
	.word 0                     /* 50: User int 2 */
	.word 0                     /* 51: User int 3 */
	.word 0                     /* 52: User int 4 */
	.word 0                     /* 53: User int 5 */
	.word 0                     /* 54: User int 6 */
	.word 0                     /* 55: User int 7 */
	.word 0                     /* 56: User int 8 */
	.word 0                     /* 57: User int 9 */
	.word 0                     /* 58: User int 10 */
	.word 0                     /* 59: User int 11 */
	.word 0                     /* 60: User int 12 */
	.word 0                     /* 61: User int 13 */
	.word 0                     /* 62: User int 14 */
	.word 0                     /* 63: User int 15 */
.size  g_pfnVectors, .-g_pfnVectors


/*******************************************************************************
*
* Provide weak aliases for each Exception handler to the Default_Handler. 
* As they are weak aliases, any function with the same name will override 
* this definition.
* 
*******************************************************************************/
.weak      NMI_Handler
.thumb_set NMI_Handler,Default_Handler

.weak      HardFault_Handler
.thumb_set HardFault_Handler,Default_Handler

.weak      MemManage_Handler
.thumb_set MemManage_Handler,Default_Handler

.weak      BusFault_Handler
.thumb_set BusFault_Handler,Default_Handler

.weak      UsageFault_Handler
.thumb_set UsageFault_Handler,Default_Handler

.weak      SVC_Handler
.thumb_set SVC_Handler,Default_Handler

.weak      DebugMon_Handler
.thumb_set DebugMon_Handler,Default_Handler

.weak      PendSV_Handler
.thumb_set PendSV_Handler,Default_Handler

.weak      SysTick_Handler
.thumb_set SysTick_Handler,Default_Handler
