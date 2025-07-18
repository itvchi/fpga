#include "leds.h"
#include "uart.h"
#include "system.h"
#include <stdbool.h>

volatile int leds;

/* Bootloader will be placed in ROM or RAM to avoid bitstream generation
    each time the firmware is recompiled (because of SRAM mode of GW2A-18) */

uint32_t receive_address();
bool receive_data();

int main() {

    char cmd;
    uint32_t address;
    bool last = false;

    uart_init(F_CPU / (2 * BAUDRATE));

    while (1) {
        set_leds(leds++>>12);

        if (uart_try_get(&cmd)) {
            switch (cmd) {
                case 0xAA:
                    address = receive_address();
                    uart_put(0xff);
                    break;
                case 0xDD:
                    last = receive_data();
                    uart_put(0xff);
                    break;
                case 'P':
                    uart_print("OK\r\n");
                    break;
                case '\0':
                    /* Do not response on wake signal */
                    break;
                default:
                    uart_print("Unknown command\r\n");
                    break;
            }
        }

        if (last) {
            /* all data received */
        }
    }

    return 0;
}

uint32_t receive_address() {

    uint32_t address = 0;
    uint8_t response = 0;
    uint8_t length;
    char data;

    length = uart_get();

    do {
        data = uart_get();
        response = response ^ data;
        address = address << 8 | data;
    } while (--length);

    uart_put(response);

    return address;
}

bool receive_data() {

    bool last;
    uint8_t response = 0;
    uint8_t length;
    char data;

    length = uart_get();
    last = (length != 255);

    do {
        data = uart_get();
        response = response ^ data;
    } while (--length);

    uart_put(response);

    return last;
}