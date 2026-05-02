#ifndef _UART_H_
#define _UART_H_

#include <stdint.h>
#include <stddef.h>

#if defined(TARGET_TANG_NANO_9K)
#define USER_UART   UART1
#elif defined(TARGET_TANG_PRIMER_20K)
#define USER_UART   UART2
#define UART_2_AVAILABLE
#endif

typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t BAUD_PRESC;
    volatile uint32_t STATUS;
    volatile uint32_t RX_DATA;
    volatile uint32_t TX_DATA;  
} Uart_TypeDef;

#define UART1_BASE   0x80000200
#define UART1        ((Uart_TypeDef *) UART1_BASE)
#define UART2_BASE   0x80000280
#define UART2        ((Uart_TypeDef *) UART2_BASE)

typedef enum {
    BAUDRATE_9600,
    BAUDRATE_115200
} baudrate_t;

void uart_init(const baudrate_t baudrate);
// char uart_get();
void uart_put(Uart_TypeDef *uart, char byte);
void uart_print(Uart_TypeDef *uart, char *str);
void uart_print_hex(Uart_TypeDef *uart, const uint32_t value);
void uart_print_irq(Uart_TypeDef *uart, char *buffer);

typedef void (*callback_t)(char *, size_t);
#define UART_RX_CALLBACK_ON_NL 0x01
#define UART_RX_CALLBACK_ON_CR 0x02

void uart_read_irq(Uart_TypeDef *uart, char *buffer, size_t buffer_size, callback_t ready_cb, unsigned int flags);

#endif /* _UART_H_ */