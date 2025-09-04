#ifndef _UART_H_
#define _UART_H_

#include <stdint.h>

#define BAUDRATE    115200


typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t BAUD_PRESC;
    volatile uint32_t STATUS;
    volatile uint32_t RX_DATA;
    volatile uint32_t TX_DATA;  
} Uart_TypeDef;

#define UART_BASE   0x80000200
#define UART        ((Uart_TypeDef *) UART_BASE)
#define UART2_BASE   0x80000280
#define UART2        ((Uart_TypeDef *) UART2_BASE)


void uart_init(uint32_t baudrate_prescaler); /* baudrate_prescaler = clock_frequency / (2 * baudrate) */
// char uart_get();
void uart_put(Uart_TypeDef *uart, char byte);
void uart_print(Uart_TypeDef *uart, char *str);
void uart_print_hex(Uart_TypeDef *uart, const uint32_t value);
void uart_print_irq(Uart_TypeDef *uart, char *buffer);

#endif /* _UART_H_ */