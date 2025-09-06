#include "system.h"
#include "uart.h"
#include "spi.h"
#include "systick.h"
#include "leds.h"
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

char uart_rx_buffer[64];

typedef struct {
    char data[64];
    bool valid;
} buffer_t;

buffer_t uart_tx_buffer;

void uart_rx_cb(char *buffer, size_t len) {

    size_t idx;

    for (idx = 0; (idx < len) && (idx < 61); idx++) {
        uart_tx_buffer.data[idx] = buffer[idx];
    }
    uart_tx_buffer.data[idx++] = '\r';
    uart_tx_buffer.data[idx++] = '\n';
    uart_tx_buffer.data[idx++] = '\0';
    uart_tx_buffer.valid = true;
}

void app_base() {

    char buffer[64];
    counter_t counter = {};
#if defined(CONFIG_WITH_SPI)
    char spi_data = 0x00;
#endif /* defined(CONFIG_WITH_SPI) */

#if defined(CONFIG_WITH_UART)
    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print_irq(UART2, "Hello world!\r\n");
    uart_read_irq(UART2, uart_rx_buffer, 64, uart_rx_cb, UART_RX_CALLBACK_ON_NL | UART_RX_CALLBACK_ON_CR);
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
#if defined(CONFIG_WITH_UART)
            sprintf(buffer, "Counter is %d\r\n", counter.value);
            uart_print_irq(UART2, buffer);
#endif /* defined(CONFIG_WITH_UART) */
        }
        if (uart_tx_buffer.valid) {
            uart_tx_buffer.valid = false;
#if defined(CONFIG_WITH_UART)
            uart_print_irq(UART2, uart_tx_buffer.data);
#endif /* defined(CONFIG_WITH_UART) */
        }
#if defined(CONFIG_WITH_SPI)
        spi_send_blocking(spi_data++);
#endif /* defined(CONFIG_WITH_SPI) */
    }
}