#include "leds.h"
#include "systick.h"
#include "irq.h"

#define F_CPU   27000000

volatile int leds;

void delay() {

    volatile unsigned int counter;

    for (counter = 0; counter < 500000; counter++) {
    }
}

void led_action(void* ctx) {

    int *led_ctx = (int*)ctx;
    *led_ctx ^= 0b000011;
    set_leds(*led_ctx);
}

int main() {

    int counter = 0;

    systick_add_event(led_action, &leds, SYSTICK_PRIO_HIGH, 2);
    systick_init_irq(0, F_CPU/10);

    while (1) {
        leds ^= 0b100000;
        set_leds(leds);
        delay();
        counter++;
    }

    return 0;
}