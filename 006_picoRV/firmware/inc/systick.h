#ifndef _SYSTICK_H_
#define _SYSTICK_H_

#include <stdint.h>
#include <stdbool.h>

typedef void (*systick_cb)(void *);

typedef enum {
    SYSTICK_PRIO_HIGH = 0,
    SYSTICK_PRIO_MEDIUM,
    SYSTICK_PRIO_LOW,
    __SYSTICK_PRIO_COUNT
} systick_prio_t;

typedef struct {
    systick_cb cb;
    void *ctx;
    systick_prio_t prio;
    uint32_t interval;
} systick_callbacks_t;

void systick_init(uint32_t prescaler);
void systick_irq(bool enable);
void systick_start(uint32_t value);
void systick_wait(uint32_t value);

void systick_init_irq(uint32_t prescaler, uint32_t value);
void systick_add_event(systick_cb cb, void *ctx, systick_prio_t prio, uint32_t interval);

uint32_t get_ticks();
void delay_ms(uint32_t ms);

#endif /* _SYSTICK_H_ */