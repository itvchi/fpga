#include "uart.h"
#include "gw1nsr-lv4c.h"


void uart_init(const uart_no_t uart, const uart_baudrate_t baudrate) {

    if (uart == UART_0) {
        UART0->BAUDDIV = (27000000 / (uint32_t)baudrate);  /* clock_hz / bauds */
        UART0->CTRL = 3; /* enable RX and TX */
    } else if (uart == UART_1) {
        UART1->BAUDDIV = (27000000 / (uint32_t)baudrate);
        UART1->CTRL = 3; /* enable RX and TX */
    } else {
        /* Invalid input */
    }
}

void uart_putchar(const uart_no_t uart, const char c) {

    if (uart == UART_0) {
        UART0->DATA = c;
        while (UART0->STATE & 1); /* await char being sent */
    } else if (uart == UART_1) {
        UART1->DATA = c;
        while (UART1->STATE & 1); /* await char being sent */
    } else {
        /* Invalid input */
    }
}

void uart_puts(const uart_no_t uart, const char *str) {

    char c;

    while ((c = *str++) != 0) uart_putchar(uart, c);
}

char uart_getchar(const uart_no_t uart) {

    char c = 0;

    if (uart == UART_0) {
        while ((UART0->STATE & 2) == 0); /* await presence of character */
        c = UART0->DATA;
    } else if (uart == UART_1) {
        while ((UART1->STATE & 2) == 0); /* await presence of character */
        c = UART1->DATA;
    } else {
        /* Invalid input */
    }

    return c;
}

void uart_print_hex(const uart_no_t uart, unsigned int val) {

    char ch;
    int i;

    for (i = 0; i < 8; i++) {
        ch = (val & 0xf0000000) >> 28;
        uart_putchar(uart, "0123456789abcdef"[(short)ch]);
        val = val << 4;
    }
}