#ifndef _UART_H_
#define _UART_H_

#include <stdbool.h>
#include <stdint.h>

#define BAUDRATE    115200

void uart_init(uint32_t baudrate_prescaler); /* baudrate_prescaler = clock_frequency / (2 * baudrate) */
bool uart_get(char *data, bool is_blocking);
void uart_put(char byte);
void uart_print(char *str);
void uart_print_hex(const uint32_t value);

#endif /* _UART_H_ */