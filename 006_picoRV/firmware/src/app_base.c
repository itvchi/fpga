#include "system.h"
#include "uart.h"
#include "systick.h"


void uart_action(void* ctx) {

    uart_print_irq("Hello RISC-V!\r\n");
}

void app_base() {

#if defined(CONFIG_WITH_UART)
    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print_irq("Hello world!\r\n");
#endif /* defined(CONFIG_WITH_UART) */
#if defined(CONFIG_WITH_SYSTICK)
    systick_add_event(uart_action, 0, SYSTICK_PRIO_LOW, 10);
#endif /* defined(CONFIG_WITH_SYSTICK) */

    while (1) {
    }
}