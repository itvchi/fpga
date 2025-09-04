#include "macros.h"
#include "systick.h"
#include "irq.h"
#include <stddef.h>

typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t STATUS;
    volatile uint32_t COUNTER;   
    volatile uint32_t PRELOAD;   
    volatile uint32_t WRAPS;   
} Systick_TypeDef;

#define SYSTICK_BASE    0x80000100
#define SYSTICK         ((Systick_TypeDef *) SYSTICK_BASE)

#define SYSTICK_CONFIG_RESET_BIT_Pos    (0U)
#define SYSTICK_CONFIG_RESET_BIT        (1 << SYSTICK_CONFIG_RESET_BIT_Pos)
#define SYSTICK_CONFIG_ENABLE_BIT_Pos   (1U)
#define SYSTICK_CONFIG_ENABLE_BIT       (1 << SYSTICK_CONFIG_ENABLE_BIT_Pos)
#define SYSTICK_CONFIG_IRQ_BIT_Pos      (2U)
#define SYSTICK_CONFIG_IRQ_BIT          (1 << SYSTICK_CONFIG_IRQ_BIT_Pos)
#define SYSTICK_CONFIG_WRAPS_BIT_Pos    (3U)
#define SYSTICK_CONFIG_WRAPS_BIT        (1 << SYSTICK_CONFIG_WRAPS_BIT_Pos)
#define SYSTICK_CONFIG_PRESCALER_Pos    (16U)
#define SYSTICK_CONFIG_PRESCALER_Msk    (0xFF << SYSTICK_CONFIG_PRESCALER_Pos)

#define SYSTICK_STATUS_PENDING_BIT_Pos  (0U)
#define SYSTICK_STATUS_PENDING_BIT      (1 << SYSTICK_STATUS_PENDING_BIT_Pos)


void systick_init(uint32_t prescaler) {

    SET_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_RESET_BIT); /* Reset */
    while (READ_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_RESET_BIT)); /* Wait until reset done */
    MODIFY_REG(SYSTICK->CONFIG, SYSTICK_CONFIG_PRESCALER_Msk, prescaler << SYSTICK_CONFIG_PRESCALER_Pos); /* Set prescaler */
}

void systick_irq(bool enable) {

    MODIFY_REG(SYSTICK->CONFIG, SYSTICK_CONFIG_IRQ_BIT, enable << SYSTICK_CONFIG_IRQ_BIT_Pos);
}

void systick_start(uint32_t value) {

    SYSTICK->COUNTER = value;
    SET_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_ENABLE_BIT); /* Enable timer */
}

void systick_wait(uint32_t value) {

    SYSTICK->COUNTER = value;
    SET_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_ENABLE_BIT); /* Enable timer */
    while (SYSTICK->STATUS & SYSTICK_STATUS_PENDING_BIT); /* Wait until count is done */
}

#define CALLBACKS   10
static uint32_t __ticks;

static systick_callbacks_t callbacks[CALLBACKS] = {0};

void systick_init_irq(uint32_t prescaler, uint32_t value) {

    SET_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_RESET_BIT); /* Reset */
    while (READ_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_RESET_BIT)); /* Wait until reset done */
    MODIFY_REG(SYSTICK->CONFIG, SYSTICK_CONFIG_PRESCALER_Msk, prescaler << SYSTICK_CONFIG_PRESCALER_Pos); /* Set prescaler */
    SET_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_IRQ_BIT); /* IRQ */

    SYSTICK->COUNTER = value;
    SYSTICK->PRELOAD = value;
    SET_BIT(SYSTICK->CONFIG, SYSTICK_CONFIG_ENABLE_BIT); /* Enable timer */
}

void systick_add_event(systick_cb cb, void *ctx, systick_prio_t prio, uint32_t interval) {

    size_t idx;

    for (idx = 0; idx < CALLBACKS; idx++) {
        if (callbacks[idx].cb == NULL) {
            callbacks[idx].cb = cb;
            callbacks[idx].ctx = ctx;
            callbacks[idx].prio = prio;
            callbacks[idx].interval = interval;
            break;
        }
    }
}

/* Achived 30us (@27MHz clk) of execution time for no callback tick */
__attribute__((section(".code_ram")))
__attribute__((optimize("-O3")))
void systick_irq_handler() {

    systick_prio_t priority;
    size_t idx;

    __ticks++;

    for (priority = SYSTICK_PRIO_HIGH; priority < __SYSTICK_PRIO_COUNT; priority++) {
        for (idx = 0; idx < CALLBACKS; idx++) {
            if (callbacks[idx].cb && !(__ticks % callbacks[idx].interval) && callbacks[idx].prio == priority) {
                callbacks[idx].cb(callbacks[idx].ctx);
            }
        } 
    }
}

uint32_t get_ticks() {

    return __ticks;
}

void delay(uint32_t ticks) {

    const uint32_t start = get_ticks();

    while ((get_ticks() - start) < ticks) {}
}