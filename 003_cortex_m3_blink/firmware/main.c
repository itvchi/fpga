#include "gpio.h"
#include <stdbool.h>

#define F_CPU_MHZ       27
#define F_CPU_HZ        (F_CPU_MHZ * 1000000)
#define HZ_TO_TICKS(x)  (F_CPU_HZ/(x))

#define LED_PIN 0
#define BTN_PIN 1


volatile uint32_t ticks;
uint32_t led_ticks = 500;
bool last;

void delay_ms(uint32_t ms);

void SysTick_Handler() {

    ticks++;

    if ((ticks % led_ticks) == 0) {
        last = !last;
        gpio_write(LED_PIN, (gpio_state_t)last);
    }
}

int main() {

    gpio_init();
    gpio_dir(LED_PIN, GPIO_OUT);
    gpio_dir(BTN_PIN, GPIO_IN);

    SysTick_Config(HZ_TO_TICKS(1000));

    while (1) {
        if (gpio_read(BTN_PIN) == GPIO_LOW) {
            delay_ms(10);
            if (gpio_read(BTN_PIN) == GPIO_LOW) {
                led_ticks *= 5;
                if (led_ticks > 2500) {
                    led_ticks = 100;
                }
                while (gpio_read(BTN_PIN) == GPIO_LOW);
            }
        }
    }

    return 0;
}

void delay_ms(uint32_t ms) {

    uint32_t last_ticks = ticks;

    /* No conversion needed, because 1 ms = 1 tick */
    while ((ticks - last_ticks) < ms);
}