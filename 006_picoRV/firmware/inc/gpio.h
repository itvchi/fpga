#ifndef _GPIO_H_
#define _GPIO_H_

#include <stdint.h>


typedef enum {
    GPIO_MODE_INPUT,
    GPIO_MODE_OUTPUT,
    GPIO_MODE_AF
} gpio_mode_t;

typedef enum {
    GPIO_STATE_LOW,
    GPIO_STATE_HIGH
} gpio_state_t;

uint32_t gpio_set_mode(const gpio_mode_t mode, const uint32_t gpio);
// uint32_t gpio_read(const uint32_t gpio);
// uint32_t gpio_read_masked(const uint32_t mask);
uint32_t gpio_read_all();
void gpio_write(const uint32_t value);
void gpio_write_pin(const uint32_t gpio, const gpio_state_t value);

#endif /* _GPIO_H_ */