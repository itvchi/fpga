#include "leds.h"
#include "systick.h"
#include "irq.h"
#include "perf.h"
#include "uart.h"

#define F_CPU       27000000
#define BAUDRATE    115200

volatile int leds;

void delay() {

    volatile unsigned int counter;

    for (counter = 0; counter < 50000; counter++) {
    }
}

void led_action(void* ctx) {

    volatile int *led_ctx = (volatile int*)ctx;
    *led_ctx ^= 0b000011;
    set_leds(*led_ctx);
}

int main() {

    // perf_flash();
    // perf_ram();

    int counter = 0;

    systick_add_event(led_action, (void*)&leds, SYSTICK_PRIO_HIGH, 2);
    systick_init_irq(0, F_CPU/10);

    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print("Hello world!\r\n");

    while (1) {
        uart_print("x\r\n");
        leds ^= 0b100000;
        set_leds(leds);
        delay();
        counter++;
    }

    return 0;
}