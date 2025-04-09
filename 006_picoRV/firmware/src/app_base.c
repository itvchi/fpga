#include "system.h"
#include "uart.h"

int app_base() {

    char character;

    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print_irq("Hello world!\r\n");

    while (1) {
        uart_print_irq("Press any key\r\n");
        character = uart_get();
        uart_print_irq("\rYou pressed: ");
        uart_put(character);
        uart_print_irq("\r\n");
    }

    return 0;
}