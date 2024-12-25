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

int main() {

    int counter = 0;

    systick_init(0);
    systick_irq(true);
    systick_start(F_CPU/10);

    while (1) {
        leds ^= 0b100000;
        set_leds(leds);
        delay();
        counter++;
        if (counter == 10) {
            mask_irq(IRQ_SYSTICK);
        }
        if (counter == 20) {
            unmask_irq(IRQ_SYSTICK);
            counter = 0;
        }
    }

    return 0;
}

void systick_irq_handler() {
    leds ^= 0b000011;
    set_leds(leds);
    systick_start(F_CPU/10);
}