#include "macros.h"
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

#define UART_BASE   0x80000200
#define UART        ((Uart_TypeDef *) UART_BASE)

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


void uart_init(uint32_t baudrate_prescaler) {

    gpio_set_mode(GPIO_MODE_AF, 0);
    gpio_set_mode(GPIO_MODE_AF, 1);

    SET_BIT(UART->CONFIG, UART_CONFIG_RESET_BIT); /* Reset */
    while (READ_BIT(UART->CONFIG, UART_CONFIG_RESET_BIT)); /* Wait until reset done */

    UART->BAUD_PRESC = baudrate_prescaler;
    SET_BIT(UART->CONFIG, UART_CONFIG_ENABLE_BIT); /* Enable uart */
}

bool uart_get(char *data, bool is_blocking) {

    if (is_blocking) {
        while (!READ_BIT(UART->STATUS, UART_STATUS_RX_VALID_BIT));
    }

    if (is_blocking || READ_BIT(UART->STATUS, UART_STATUS_RX_VALID_BIT)) {
        CLEAR_BIT(UART->STATUS, UART_STATUS_RX_VALID_BIT);
        *data = UART->RX_DATA;
        return true;
    }

    return false;
}

void uart_put(char byte) {

    while (READ_BIT(UART->STATUS, UART_STATUS_TX_BUSY_BIT));
    UART->TX_DATA = byte;
}

void uart_print(char *str) {

    while (*str) {
        uart_put(*str);
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

void uart_print_hex(const uint32_t value) {

    int idx;

    uart_print("0x");

    for (idx = 28; idx >= 0; idx -= 4) {
        char nibble = (value >> idx) & 0xF;
        uart_put(hex_to_char(nibble));
    }
}