#include "leds.h"
#include "perf.h"
#if defined(EXAMPLE_SYSTICK)
#include "systick.h"
#include "system.h"

void example_systick();
#endif
#if defined(EXAMPLE_UART)
#include <stdbool.h>
#include <stdio.h>
#include "uart.h"

void example_uart();
#endif

int main() {

#if defined(EXAMPLE_SYSTICK)
    example_systick();
#elif defined(EXAMPLE_UART)
    example_uart();
#elif defined(EXAMPLE_PERF_FLASH)
    perf_flash();
#elif defined(EXAMPLE_PERF_RAM)
    perf_ram();
#else
    blink();
#endif

    return 0;
}

#if defined(EXAMPLE_SYSTICK)
void example_systick() {

    systick_init(F_CPU/1000); /* 1000 ticks per second */

    while (1) {
        systick_wait(500);
        blink_once(0);
    }
}
#endif /* defined(EXAMPLE_SYSTICK) */

#if defined(EXAMPLE_UART)
void example_uart() {

    int counter = 0;
    char buffer[64];

    uart_init(BAUDRATE_115200);
    uart_print(USER_UART, "Hello world!\r\n");

    while (1) {
        blink_once(5);
        sprintf(buffer, "Counter is %d\r\n", counter++);
        uart_print(USER_UART, buffer);
    }
}
#endif /* defined(EXAMPLE_UART) */