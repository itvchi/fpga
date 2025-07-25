#include "leds.h"
#include "uart.h"
#include "system.h"
#include <stdbool.h>
#include "crc32.h"
#include "systick.h"

/* Bootloader will be placed in ROM or RAM to avoid bitstream generation
    each time the firmware is recompiled (because of SRAM mode of GW2A-18) */

void cmd_ack();
uint32_t receive_address();
uint32_t receive_data(uint32_t last_addr);

void timeout_fn() {

    uint32_t leds = 0;

    uart_print("timeout");
    
    while (1) {
        set_leds(leds-->>16);
    }
}

void time_update(bool reset) {

    static uint32_t last_ticks;
    static uint32_t seconds;

    if (reset) {
        seconds = 0;
    } else {
        if (get_ticks() - last_ticks > 1000) {
            last_ticks = get_ticks();
            seconds++;
        }
        if (seconds > 10) {
            timeout_fn();
        }
    }
}

int main() {

    int leds = 0;
    char cmd;
    uint32_t address = 0; /* Start command will cause reset if address was not set */
    uint32_t last_addr = address;
    void (*start_ptr)(void);

    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print("\r\nStarting bootloader (ROM)\r\n");

    systick_init(F_CPU/1000); /* 1ms per tick */
    time_update(true);
    
    crc32_init(CRC32_DATA_IN_WORD);

    while (1) {
        set_leds(leds++>>16);

        time_update(false);

        if (uart_get(&cmd, false)) {
            switch (cmd) {
                case 0xCC: /* Start command */
                    cmd_ack();
                    // start_ptr = (void *)address;
                    // start_ptr();
                    break;
                case 0xAA: /* Address command */
                    time_update(true); /* Reset timeout at first try */
                    address = receive_address();
                    last_addr = address;
                    cmd_ack();
                    break;
                case 0xDD: /* Data command */
                    last_addr = receive_data(last_addr);
                    cmd_ack();
                    break;
                case '?': /* Test command - serial console */
                    time_update(true);
                    uart_print("OK\r\n");
                    break;
                case 'R': /* Test command - serial console */
                    uart_print("RESET\r\n");
                    start_ptr = 0x0;
                    start_ptr();
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

void cmd_ack() {

    uart_put(0xff);
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
    uint32_t crc32 = 0;
    uint8_t chunk_length, i = 0;
    uint8_t response = 0;
    uint8_t length;
    char data;
    char buffer[255];

    uart_get((char *)&length, true);
    chunk_length = length;

    if (chunk_length) {
        for (int i = 0; i < 4; i++) {
            uart_get(&data, true);
            crc32 = crc32 << 8 | data;
        }
    }

    do {
        uart_get(&data, true);
        response = response ^ data;
        buffer[i++] = data;
    } while (--length);

    uart_put(response);

    crc32_reset(CRC32_DATA_IN_BYTE);
    for (i = 0; i < chunk_length; i++) {
        mem_addr[i] = buffer[i];
        crc32_push(buffer[i]);
    }

    return (last_addr + chunk_length);
}