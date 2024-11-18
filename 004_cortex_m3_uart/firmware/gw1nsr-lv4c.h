#ifndef _GW1NSR_LV4C_H_
#define _GW1NSR_LV4C_H_

/**
  * @brief Configuration of the Cortex-M3 Processor and Core Peripherals
  */
#define __NVIC_PRIO_BITS          4U       /*!< GW1NSR_LV4C uses 4 Bits for the Priority Levels */
#define __Vendor_SysTickConfig    0U       /*!< Set to 1 if different SysTick Config is used    */
#define __FPU_PRESENT             0U       /*!< FPU present                                     */

typedef enum
{
  /******  Cortex-M3 Processor Exceptions Numbers ****************************************************************/
  NonMaskableInt_IRQn         = -14,    /*!< 2 Non Maskable Interrupt                                          */
  MemoryManagement_IRQn       = -12,    /*!< 4 Cortex-M3 Memory Management Interrupt                           */
  BusFault_IRQn               = -11,    /*!< 5 Cortex-M3 Bus Fault Interrupt                                   */
  UsageFault_IRQn             = -10,    /*!< 6 Cortex-M3 Usage Fault Interrupt                                 */
  SVCall_IRQn                 = -5,     /*!< 11 Cortex-M3 SV Call Interrupt                                    */
  DebugMonitor_IRQn           = -4,     /*!< 12 Cortex-M3 Debug Monitor Interrupt                              */
  PendSV_IRQn                 = -2,     /*!< 14 Cortex-M3 Pend SV Interrupt                                    */
  SysTick_IRQn                = -1,     /*!< 15 Cortex-M3 System Tick Interrupt                                */
  /******  GW1NSR_LV4C specific Interrupt Numbers **********************************************************************/
} IRQn_Type;

#include "cmsis_minimal/core_cm3.h"

typedef struct {
    __IO uint32_t DATA_IN;
    __IO uint32_t DATA_OUT;
    uint32_t RESERVED0[2U];
    __IO uint32_t OUTENSET;
    __IO uint32_t OUTENCLR;
    __IO uint32_t ALTFUNCSET;
    __IO uint32_t ALTFUNCCLR;
    __IO uint32_t INTENSET;
    __IO uint32_t INTENCLR;
    __IO uint32_t INTTYPESET;
    __IO uint32_t INTTYPECLR;
    __IO uint32_t INTPOLSET;
    __IO uint32_t INTPOLCLR;
    __IO uint32_t INTSTATCLEAR;
} GPIO_TypeDef;

#define GPIO0_BASE          0x40010000
#define GPIO0               ((GPIO_TypeDef *) GPIO0_BASE)
#define GPIO0_MASKLOWBYTE(N) (*(volatile unsigned int *) (GPIO0_BASE + 0x400 + (N)))
#define GPIO0_MASKHIGHBYTE(N) (*(volatile unsigned int *) (GPIO0_BASE + 0x800 + (N)))


typedef struct {
    __IO uint32_t DATA;
    __IO uint32_t STATE;
    __IO uint32_t CTRL;
    __IO uint32_t INT;
    __IO uint32_t BAUDDIV;
} UART_TypeDef;

#define UART0_BASE          0x40004000
#define UART1_BASE          0x40005000
#define UART0               ((UART_TypeDef *) UART0_BASE)
#define UART1               ((UART_TypeDef *) UART1_BASE)

#endif /* _GW1NSR_LV4C_H_ */