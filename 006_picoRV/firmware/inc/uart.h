#ifndef _UART_H_
#define _UART_H_

#include <stdint.h>

#define BAUDRATE    115200

void uart_init(uint32_t baudrate_prescaler); /* baudrate_prescaler = clock_frequency / (2 * baudrate) */
void uart_put(char byte);
char uart_get();
void uart_print(char *str);
void uart_print_irq(char *buffer);

#endif /* _UART_H_ */