#include "system.h"
#include "uart.h"
#include "spi.h"
#include "systick.h"
#include <stdio.h>
#include <stdbool.h>


typedef struct {
    int value;
    bool updated;
} counter_t;

void uart_action(void* ctx) {

    counter_t *counter = (counter_t *)ctx;
    counter->value++;
    counter->updated = true;
}

void app_base() {

    char buffer[64];
    counter_t counter = {};
    char spi_data = 0x00;

#if defined(CONFIG_WITH_UART)
    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print_irq("Hello world!\r\n");
#endif /* defined(CONFIG_WITH_UART) */
#if defined(CONFIG_WITH_SYSTICK)
    systick_add_event(uart_action, (void *)&counter, SYSTICK_PRIO_LOW, 1000);
#endif /* defined(CONFIG_WITH_SYSTICK) */
#if defined(CONFIG_WITH_SPI)
    spi_init(true);
#endif /* defined(CONFIG_WITH_SPI) */

    while (1) {
        if (counter.updated) {
            counter.updated = false;
            sprintf(buffer, "Counter is %d\r\n", counter.value);
#if defined(CONFIG_WITH_UART)
            uart_print_irq(buffer);
#endif /* defined(CONFIG_WITH_UART) */
        }
#if defined(CONFIG_WITH_SPI)
        spi_send_blocking(spi_data++);
#endif /* defined(CONFIG_WITH_SPI) */
    }
}