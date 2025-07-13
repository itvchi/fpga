#include "gpio.h"
#include <stddef.h>


typedef struct {
    volatile uint32_t MODE;
    volatile uint32_t OUT;
    volatile uint32_t IN;  
} Gpio_TypeDef;

#define GPIO_BASE   0x80000400
#define GPIO        ((Gpio_TypeDef *) GPIO_BASE)


uint32_t gpio_set_mode(const gpio_mode_t mode, const uint32_t gpio) {

    uint32_t old_mode = GPIO->MODE;
    uint32_t new_mode = (old_mode & ~((0b11) << 2*gpio)) | (mode << 2*gpio);

    GPIO->MODE = new_mode;
    return new_mode;
}

uint32_t gpio_read_all() {

    return GPIO->IN;
}

void gpio_write(const uint32_t value) {

    GPIO->OUT = value;
}

void gpio_write_pin(const uint32_t gpio, const gpio_state_t value) {

    uint32_t old_value = GPIO->OUT;
    uint32_t new_value; 

    if (value == GPIO_STATE_LOW) {
        new_value = (old_value & ~(0b1 << gpio));
    } else {
        new_value = (old_value | (0b1 << gpio));
    }

    GPIO->OUT = new_value;
}