#include "gpio.h"

void gpio_init(void) {

    uint32_t i;

    /* These are documented as having undefined value at reset */
    for (i = 0; i < 256; i++) {
        GPIO0_MASKLOWBYTE(i) = 0;
        GPIO0_MASKHIGHBYTE(i) = 0;
    }
}

void gpio_dir(gpio_no_t gpio, gpio_dir_t dir) {

    if (dir == GPIO_OUT) {
        GPIO0->OUTENSET = (1 << gpio);
    } else if (dir == GPIO_IN) {
        GPIO0->OUTENCLR = (1 << gpio);
    } else {
        /* Invalid input */
    }
}

void gpio_write(gpio_no_t gpio, gpio_state_t value) {

    if (value == GPIO_HIGH) {
        GPIO0->DATA_OUT |= (1 << gpio);
    } else if(value == GPIO_LOW) {
        GPIO0->DATA_OUT &= ~(1 << gpio);
    } else {
        /* Invalid input */
    }
}

gpio_state_t gpio_read(gpio_no_t gpio) {

    return ((GPIO0->DATA_IN >> gpio) & 0x1) ? GPIO_HIGH : GPIO_LOW;
}