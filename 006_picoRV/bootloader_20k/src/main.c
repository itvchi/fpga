#include "leds.h"
#include "uart.h"
#include "system.h"
#include <stdbool.h>

/* Bootloader will be placed in ROM or RAM to avoid bitstream generation
    each time the firmware is recompiled (because of SRAM mode of GW2A-18) */

uint32_t receive_address();
uint32_t receive_data(uint32_t last_addr);

int main() {

    int leds = 0;
    char cmd;
    uint32_t address = 0; /* Start command will cause reset if address was not set */
    uint32_t last_addr = address;
    void (*start_ptr)(void);

    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print("Starting bootloader\r\n");

    while (1) {
        set_leds(leds++>>16);

        if (uart_get(&cmd, false)) {
            switch (cmd) {
                case 0xCC: /* Start command */
                    uart_put(0xff);
                    start_ptr = (void *)address;
                    start_ptr();
                    while (1) {
                        leds ^= 0x10101;
                        set_leds(leds);
                    }
                    break;
                case 0xAA: /* Address command */
                    address = receive_address();
                    last_addr = address;
                    uart_put(0xff);
                    break;
                case 0xDD: /* Data command */
                    last_addr = receive_data(last_addr);
                    uart_put(0xff);
                    break;
                case '?': /* Test command - serial console */
                    uart_print("OK\r\n");
                    break;
                case '\0':
                    /* Do not response on wake signal */
                    break;
                default:
                    break;
            }
        }
    }

    return 0;
}

uint32_t receive_address() {

    uint32_t address = 0;
    uint8_t response = 0;
    uint8_t length;
    char data;

    uart_get((char *)&length, true);

    do {
        uart_get(&data, true);
        response = response ^ data;
        address = address << 8 | data;
    } while (--length);

    uart_put(response);

    return address;
}

uint32_t receive_data(uint32_t last_addr) {

    uint8_t *mem_addr = (uint8_t *)last_addr;
    uint8_t chunk_length, i = 0;
    uint8_t response = 0;
    uint8_t length;
    char data;
    char buffer[255];

    uart_get((char *)&length, true);
    chunk_length = length;

    do {
        uart_get(&data, true);
        response = response ^ data;
        buffer[i++] = data;
    } while (--length);

    uart_put(response);

    for (i = 0; i < chunk_length; i++) {
        mem_addr[i] = buffer[i];
    }

    return (last_addr + chunk_length);
}