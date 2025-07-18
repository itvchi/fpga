#include "uart.h"
#include "gpio.h"
#include <stddef.h>

typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t BAUD_PRESC;
    volatile uint32_t STATUS;
    volatile uint32_t RX_DATA;
    volatile uint32_t TX_DATA;  
} Uart_TypeDef;

typedef union {
    uint32_t value;
    struct {
        uint32_t reset         :  1; /* Reset peripheral */
        uint32_t enable        :  1; /* Enable uart */
        uint32_t irq_rx        :  1; /* Enable rx irq */
        uint32_t irq_tx        :  1; /* Enable tx irq */
        uint32_t reserved4_31  : 28;
    };
} UartConfig_TypeDef;

typedef union {
    uint32_t value;
    struct {
        uint32_t rx_valid      :  1; /* Rx data arrived */
        uint32_t tx_busy       :  1; /* Tx data sending */
        uint32_t reserved2_31  : 30;
    };
} UartStatus_TypeDef;

#define UART_BASE   0x80000200
#define UART        ((Uart_TypeDef *) UART_BASE)


void uart_init(uint32_t baudrate_prescaler) {

    UartConfig_TypeDef *config = (UartConfig_TypeDef *)&(UART->CONFIG);

    config->reset = 1; /* Reset */
    while (config->reset); /* Wait until reset done */

    UART->BAUD_PRESC = baudrate_prescaler;
    config->enable = 1; /* Enable uart */

    gpio_set_mode(GPIO_MODE_AF, 0);
    gpio_set_mode(GPIO_MODE_AF, 1);
}

void uart_put(char byte) {

    UartConfig_TypeDef *config = (UartConfig_TypeDef *)&(UART->CONFIG);
    UartStatus_TypeDef *status = (UartStatus_TypeDef *)&(UART->STATUS);

    while (status->tx_busy || config->irq_tx);
    UART->TX_DATA = byte;
}

bool uart_try_get(char *data) {

    UartStatus_TypeDef *status = (UartStatus_TypeDef *)&(UART->STATUS);

    if (status->rx_valid) {
        status->rx_valid = 0;
        *data = UART->RX_DATA;
        return true;
    }

    return false;
}

char uart_get() {

    UartStatus_TypeDef *status = (UartStatus_TypeDef *)&(UART->STATUS);

    while (!(status->rx_valid));
    status->rx_valid = 0;

    return UART->RX_DATA;
}

void uart_print(char *str) {

    UartConfig_TypeDef *config = (UartConfig_TypeDef *)&(UART->CONFIG);
    UartStatus_TypeDef *status = (UartStatus_TypeDef *)&(UART->STATUS);

    while (*str) {
        while (status->tx_busy || config->irq_tx);
        UART->TX_DATA = *str;
        str++;
    }
}

volatile char *irq_tx_buffer = NULL;

void uart_tx_handler() {

    UartConfig_TypeDef *config;

    if (irq_tx_buffer) {
        if (*irq_tx_buffer) {
            UART->TX_DATA = *irq_tx_buffer;
            irq_tx_buffer++;
        } else {
            config = (UartConfig_TypeDef *)&(UART->CONFIG);
            config->irq_tx = 0; /* Disable tx irq */
            irq_tx_buffer = NULL;
        }
    }
}

void uart_print_irq(char *buffer) {

    UartConfig_TypeDef *config = (UartConfig_TypeDef *)&(UART->CONFIG);
    UartStatus_TypeDef *status = (UartStatus_TypeDef *)&(UART->STATUS);

    while (status->tx_busy || config->irq_tx); /* Wait until previous data was send or irq mode still enabled */
    if (buffer[0]) {
        config->irq_tx = 1; /* Enable tx irq */
        irq_tx_buffer = &buffer[0];
        UART->TX_DATA = *irq_tx_buffer;
        irq_tx_buffer++;
    }
}