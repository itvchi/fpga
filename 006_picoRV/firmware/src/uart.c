#include "macros.h"
#include "uart.h"
#include "gpio.h"
#include <stddef.h>

#define UART_CONFIG_RESET_BIT_Pos       (0U)
#define UART_CONFIG_RESET_BIT           (1 << UART_CONFIG_RESET_BIT_Pos)
#define UART_CONFIG_ENABLE_BIT_Pos      (1U)
#define UART_CONFIG_ENABLE_BIT          (1 << UART_CONFIG_ENABLE_BIT_Pos)
#define UART_CONFIG_RX_IRQ_BIT_Pos      (2U)
#define UART_CONFIG_RX_IRQ_BIT          (1 << UART_CONFIG_RX_IRQ_BIT_Pos)
#define UART_CONFIG_TX_IRQ_BIT_Pos      (3U)
#define UART_CONFIG_TX_IRQ_BIT          (1 << UART_CONFIG_TX_IRQ_BIT_Pos)

#define UART_STATUS_RX_VALID_BIT_Pos    (0U)
#define UART_STATUS_RX_VALID_BIT        (1 << UART_STATUS_RX_VALID_BIT_Pos)
#define UART_STATUS_TX_BUSY_BIT_Pos     (1U)
#define UART_STATUS_TX_BUSY_BIT         (1 << UART_STATUS_TX_BUSY_BIT_Pos)


static void do_uart_init(Uart_TypeDef *uart, uint32_t *baudrate_prescaler) {

    SET_BIT(uart->CONFIG, UART_CONFIG_RESET_BIT); /* Reset */
    while (READ_BIT(uart->CONFIG, UART_CONFIG_RESET_BIT)); /* Wait until reset done */

    uart->BAUD_PRESC = *baudrate_prescaler;
    SET_BIT(uart->CONFIG, UART_CONFIG_ENABLE_BIT); /* Enable uart */
}

void uart_init(uint32_t baudrate_prescaler) {

    gpio_set_mode(GPIO_MODE_AF, 0);
    gpio_set_mode(GPIO_MODE_AF, 1);

    do_uart_init(UART, &baudrate_prescaler);
    
    gpio_set_mode(GPIO_MODE_AF, 5);
    gpio_set_mode(GPIO_MODE_AF, 6);
    
    do_uart_init(UART2, &baudrate_prescaler);
}

// bool uart_get(char *data, bool is_blocking) {

//     if (is_blocking) {
//         while (!READ_BIT(UART->STATUS, UART_STATUS_RX_VALID_BIT));
//     }

//     if (is_blocking || READ_BIT(UART->STATUS, UART_STATUS_RX_VALID_BIT)) {
//         CLEAR_BIT(UART->STATUS, UART_STATUS_RX_VALID_BIT);
//         *data = UART->RX_DATA;
//         return true;
//     }

//     return false;
// }

void uart_put(Uart_TypeDef *uart, char byte) {

    while (READ_BIT(uart->STATUS, UART_STATUS_TX_BUSY_BIT));
    uart->TX_DATA = byte;
}

void uart_print(Uart_TypeDef *uart, char *str) {

    while (*str) {
        uart_put(uart, *str);
        str++;
    }
}

static char hex_to_char(uint8_t value) {

    if (value < 10) {
        return value + 0x30;
    } else {
        return value - 10 + 0x41;
    }
}

void uart_print_hex(Uart_TypeDef *uart, const uint32_t value) {

    int8_t idx;

    uart_print(uart, "0x");

    for (idx = 28; idx >= 0; idx -= 4) {
        char nibble = (value >> idx) & 0xF;
        uart_put(uart, hex_to_char(nibble));
    }
}

/* TODO: Add separate buffer for second uart */
volatile char *irq_tx_buffer = NULL;

void uart_tx_handler(Uart_TypeDef *uart) {

    if (irq_tx_buffer) {
        if (*irq_tx_buffer) {
            uart->TX_DATA = *irq_tx_buffer;
            irq_tx_buffer++;
        } else {
            CLEAR_BIT(uart->CONFIG, UART_CONFIG_TX_IRQ_BIT); /* Disable tx irq */ 
            irq_tx_buffer = NULL;
        }
    }
}

void uart1_tx_handler() {
    uart_tx_handler(UART);
}

void uart2_tx_handler() {
    uart_tx_handler(UART2);
}

void uart_print_irq(Uart_TypeDef *uart, char *buffer) {

    /* Wait until previous data was send or irq mode still enabled */
    while ((uart->STATUS & UART_STATUS_TX_BUSY_BIT) || (uart->CONFIG & UART_CONFIG_TX_IRQ_BIT)); 
    if (*buffer) {
        SET_BIT(uart->CONFIG, UART_CONFIG_TX_IRQ_BIT); /* Enable tx irq */
        irq_tx_buffer = buffer;
        uart->TX_DATA = *irq_tx_buffer;
        irq_tx_buffer++;
    }
}