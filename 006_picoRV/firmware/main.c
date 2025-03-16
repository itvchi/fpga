#include "leds.h"
#include "systick.h"
#include "irq.h"
#include "perf.h"
#include "uart.h"
#include "lcd.h"

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

    char character;

    systick_add_event(led_action, (void*)&leds, SYSTICK_PRIO_HIGH, 2);
    systick_init_irq(0, F_CPU/10);

    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print_irq("Hello world!\r\n");

    lcd_clear();
    lcd_write_str("Hello world!!!");
    lcd_write_str_xy("This is wrapped line ->\r this should be at front", 30, 3);
    lcd_write_str_xy("This is first line\n And this should be line below", 0, 6);

    while (1) {
        uart_print_irq("Press any key\r\n");
        character = uart_get();
        uart_print_irq("\rYou pressed: ");
        uart_put(character);
        uart_print_irq("\r\n");
    }

    return 0;
}