#ifndef _SYSTICK_H_
#define _SYSTICK_H_

#include <stdint.h>
#include <stdbool.h>

typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t STATUS;
    volatile uint32_t COUNTER;  
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

void systick_init(uint32_t prescaler);
void systick_irq(bool enable);
void systick_start(uint32_t value);
void systick_wait(uint32_t value);

#endif /* _SYSTICK_H_ */