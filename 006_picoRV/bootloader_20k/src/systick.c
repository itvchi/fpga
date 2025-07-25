#include "systick.h"
#include "macros.h"
#include <stddef.h>

typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t STATUS;
    volatile uint32_t COUNTER;   
    volatile uint32_t PRELOAD;   
    volatile uint32_t WRAPS;   
} Systick_TypeDef;

#define SYSTICK_BASE           0x80000100
#define SYSTICK                ((Systick_TypeDef *) SYSTICK_BASE)

#define SYSTICK_CONFIG_RESET_BIT_Pos    (0U)
#define SYSTICK_CONFIG_RESET_BIT        (1 << SYSTICK_CONFIG_RESET_BIT_Pos)
#define SYSTICK_CONFIG_ENABLE_BIT_Pos   (1U)
#define SYSTICK_CONFIG_ENABLE_BIT       (1 << SYSTICK_CONFIG_ENABLE_BIT_Pos)
#define SYSTICK_CONFIG_WRAPS_BIT_Pos    (3U)
#define SYSTICK_CONFIG_WRAPS_BIT        (1 << SYSTICK_CONFIG_WRAPS_BIT_Pos)
#define SYSTICK_CONFIG_PRESCALER_Pos    (16U)
#define SYSTICK_CONFIG_PRESCALER_Msk    (0xFF << SYSTICK_CONFIG_PRESCALER_Pos)

#define SYSTICK_STATUS_PANDING_BIT_Pos  (0U)
#define SYSTICK_STATUS_PANDING_BIT      (1 << SYSTICK_STATUS_PANDING_BIT_Pos)


void systick_init(uint32_t prescaler) {

    SET_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_RESET_BIT); /* Reset */
    while (READ_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_RESET_BIT)); /* Wait until reset done */

    MODIFY_REG(SYSTICK->CONFIG, SYSTICK_CONFIG_PRESCALER_Msk, prescaler << SYSTICK_CONFIG_PRESCALER_Pos);

    SYSTICK->COUNTER = 0xFFFFFF;
    SYSTICK->PRELOAD = 0xFFFFFF;
    SET_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_WRAPS_BIT);
    SET_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_ENABLE_BIT); /* Enable timer */
}

static uint32_t __ticks;

uint32_t get_ticks() {

    __ticks = (0xFFFFFFFF - SYSTICK->COUNTER);
    return __ticks;
}