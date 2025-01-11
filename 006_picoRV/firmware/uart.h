#ifndef _UART_H_
#define _UART_H_

#include <stdint.h>

void uart_init(uint32_t baudrate_prescaler); /* baudrate_prescaler = clock_frequency / (2 * baudrate) */
void uart_put(char byte);
void uart_print(char *str);
void uart_print_irq(char *buffer);

#endif /* _UART_H_ */