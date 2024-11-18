#ifndef _UART_H_
#define _UART_H_

typedef enum {
    UART_0,
    UART_1
} uart_no_t;

typedef enum {
    BAUDRATE_4800 = 4800, 
    BAUDRATE_9600 = 9600, 
    BAUDRATE_19200 = 19200, 
    BAUDRATE_38400 = 38400, 
    BAUDRATE_57600 = 57600, 
    BAUDRATE_115200 = 115200, 
    BAUDRATE_230400 = 230400, 
    BAUDRATE_460800 = 460800, 
    BAUDRATE_921600 = 921600
} uart_baudrate_t;

void uart_init(const uart_no_t uart, const uart_baudrate_t baudrate);
void uart_putchar(const uart_no_t uart, const char c);
void uart_puts(const uart_no_t uart, const char *str);
char uart_getchar(const uart_no_t uart);
void uart_print_hex(const uart_no_t uart, unsigned int val);

#endif /* _UART_H_ */