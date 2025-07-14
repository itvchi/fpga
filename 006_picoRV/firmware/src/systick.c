#include "systick.h"
#include "irq.h"
#include <stddef.h>

typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t STATUS;
    volatile uint32_t COUNTER;  
    volatile uint32_t IRQ_PRELOAD;  
} Systick_TypeDef;

typedef union {
    uint32_t value;
    struct {
        uint32_t reset         :  1; /* Reset peripheral */
        uint32_t enable        :  1; /* Enable counting */
        uint32_t irq           :  1; /* Enable irq */
        uint32_t reserved3_15  : 13;
        uint32_t prescaler     : 16; /* Clock prescaler */
    };
} SystickConfig_TypeDef;

typedef union {
    uint32_t value;
    struct {
        uint32_t pending       :  1; /* Counter is working */
        uint32_t reserved1_31  : 31;
    };
} SystickStatus_TypeDef;

#define SYSTICK_BASE           0x80000100
#define SYSTICK                ((Systick_TypeDef *) SYSTICK_BASE)


void systick_init(uint32_t prescaler) {

    SystickConfig_TypeDef *config = (SystickConfig_TypeDef *)&(SYSTICK->CONFIG);

    config->reset = 1; /* Reset */
    while (config->reset); /* Wait until reset done */
    config->prescaler = (prescaler << 16); /* Set prescaler */
}

void systick_irq(bool enable) {

    SystickConfig_TypeDef *config = (SystickConfig_TypeDef *)&(SYSTICK->CONFIG);

    config->irq = enable; /* Set irq state */
}

void systick_start(uint32_t value) {

    SystickConfig_TypeDef *config = (SystickConfig_TypeDef *)&(SYSTICK->CONFIG);

    SYSTICK->COUNTER = value;
    config->enable = 1; /* Enable timer */
}

void systick_wait(uint32_t value) {

    SystickConfig_TypeDef *config = (SystickConfig_TypeDef *)&(SYSTICK->CONFIG);
    SystickStatus_TypeDef *status = (SystickStatus_TypeDef *)&(SYSTICK->STATUS);

    SYSTICK->COUNTER = value;
    config->enable = 1; /* Enable timer */
    while (status->pending); /* Wait until count is done */
}

#define CALLBACKS   10
static uint32_t __counter;
static uint32_t __ticks;

static systick_callbacks_t callbacks[CALLBACKS] = {0};

void systick_init_irq(uint32_t prescaler, uint32_t value) {

    SystickConfig_TypeDef *config = (SystickConfig_TypeDef *)&(SYSTICK->CONFIG);

    config->reset = 1; /* Reset */
    while (config->reset); /* Wait until reset done */
    config->prescaler = (prescaler << 16); /* Set prescaler */
    config->irq = true; /* Set irq state */

    __counter = value;
    SYSTICK->COUNTER = value;
    SYSTICK->IRQ_PRELOAD = value;
    config->enable = 1; /* Enable timer */
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

/* Achived 80us of execution time for no callback tick */
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

uint32_t get_millis() {

    return __ticks * 10;
}

void delay_ms(uint32_t ms) {

    const uint32_t start = __ticks;
    ms = ms/10;

    while ((__ticks - start) < ms) {}
}