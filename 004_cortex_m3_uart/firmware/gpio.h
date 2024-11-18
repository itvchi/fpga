#ifndef _GPIO_H_
#define _GPIO_H_


typedef enum {
    GPIO_IN = 0,
    GPIO_OUT
} gpio_dir_t;

typedef enum {
    GPIO_LOW = 0,
    GPIO_HIGH
} gpio_state_t;

typedef unsigned int gpio_no_t;

void gpio_init(void);
void gpio_dir(gpio_no_t gpio, gpio_dir_t dir);
void gpio_write(gpio_no_t gpio, gpio_state_t value);
gpio_state_t gpio_read(gpio_no_t gpio_t);

#endif /* _GPIO_H_ */