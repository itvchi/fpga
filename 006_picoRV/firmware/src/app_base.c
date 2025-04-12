#include "system.h"
#include "uart.h"

int app_base() {

#if defined(CONFIG_WITH_UART)
    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print_irq("Hello world!\r\n");
#endif /* defined(CONFIG_WITH_UART) */

    while (1) {
#if defined(CONFIG_WITH_UART)
        uart_print_irq("Press any key\r\n");
        char character = uart_get();
        uart_print_irq("\rYou pressed: ");
        uart_put(character);
        uart_print_irq("\r\n");
#endif /* defined(CONFIG_WITH_UART) */
    }

    return 0;
}