#include "uart.h"
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
        uint32_t reserved2_31  : 30;
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
}

void uart_put(char byte) {

    UartStatus_TypeDef *status = (UartStatus_TypeDef *)&(UART->STATUS);

    if (!status->tx_busy) {
        UART->TX_DATA = byte;
    }
}

void uart_print(char *str) {

    UartStatus_TypeDef *status = (UartStatus_TypeDef *)&(UART->STATUS);

    while (*str) {
        while (status->tx_busy);
        uart_put(*str);
        str++;
    }
}