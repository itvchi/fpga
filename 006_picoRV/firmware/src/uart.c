#include "macros.h"
#include "uart.h"
#include "gpio.h"
#include "system.h"
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

/* baudrate_prescaler = clock_frequency / (2 * baudrate) *///
static uint32_t get_prescaler(const baudrate_t baudrate) {

    switch (baudrate) {
        case BAUDRATE_9600:     return F_CPU / (2 * 9600);
        case BAUDRATE_115200:   return F_CPU / (2 * 115200);
    }

    return get_prescaler(BAUDRATE_115200);
}

void uart_init(const baudrate_t baudrate) {

    uint32_t baudrate_prescaler = get_prescaler(baudrate);

    gpio_set_mode(GPIO_MODE_AF, 0);
    gpio_set_mode(GPIO_MODE_AF, 1);
    do_uart_init(UART1, &baudrate_prescaler);

#if defined(UART_2_AVAILABLE)
    gpio_set_mode(GPIO_MODE_AF, 6);
    gpio_set_mode(GPIO_MODE_AF, 7);
    do_uart_init(UART2, &baudrate_prescaler);
#endif /* defined(UART_2_AVAILABLE) */
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
    uart_tx_handler(UART1);
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

char *irq_rx_buffer = NULL;
volatile size_t irq_rx_buffer_size;
callback_t irq_rx_ready_cb = NULL;
unsigned int irq_rx_flags;

void uart_read_irq(Uart_TypeDef *uart, char *buffer, size_t buffer_size, callback_t ready_cb, unsigned int flags) {

    irq_rx_buffer = buffer;
    irq_rx_buffer_size = buffer_size;
    irq_rx_ready_cb = ready_cb;
    irq_rx_flags = flags;
    SET_BIT(uart->CONFIG, UART_CONFIG_RX_IRQ_BIT); /* Enable rx irq */
}

void uart2_rx_handler() {

    static size_t buffer_data;
    char data;

    if (buffer_data < irq_rx_buffer_size) {
        data = UART2->RX_DATA;
        irq_rx_buffer[buffer_data] = data;
        buffer_data++;
    }

    if (((irq_rx_flags & UART_RX_CALLBACK_ON_NL) && data == '\n') ||
        ((irq_rx_flags & UART_RX_CALLBACK_ON_CR) && data == '\r') ||
        buffer_data == irq_rx_buffer_size) {

        if (irq_rx_ready_cb) {
            irq_rx_ready_cb(irq_rx_buffer, buffer_data);
        }

        buffer_data = 0;
    }
}