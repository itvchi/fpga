#include "leds.h"
#include "uart.h"
#include "system.h"

volatile int leds;

/* Bootloader will be placed in ROM or RAM to avoid bitstream generation
    each time the firmware is recompiled (because of SRAM mode of GW2A-18) */

void receive();

int main() {

    char cmd;

    uart_init(F_CPU / (2 * BAUDRATE));

    while (1) {
        set_leds(leds++>>12);

        if (uart_try_get(&cmd)) {
            switch (cmd) {
                case 0xA5:
                    receive();
                    break;
                case 'P':
                    uart_print("OK\r\n");
                    break;
                default:
                    uart_print("Unknown command\r\n");
                    break;
            }
        }
    }

    return 0;
}

void receive() {

    uint8_t response = 0;
    uint8_t length;
    char data;

    length = uart_get();

    do {
        data = uart_get();
        response ^= data;
    } while (--length);

    uart_put(response);
}