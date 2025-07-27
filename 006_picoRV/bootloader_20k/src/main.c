#include "leds.h"
#include "uart.h"
#include "system.h"
#include "crc32.h"
#include "systick.h"

#define _1S_TIKCS   1000
#define TIMEOUT_S 5

/* Bootloader will be placed in ROM or RAM to avoid bitstream generation
    each time the firmware is recompiled (because of SRAM mode of GW2A-18) */

void send_ack();
void send_nack();
bool receive_address(uint32_t *address);
uint32_t receive_data(uint32_t last_addr);

uint8_t ok;

void timeout_fn() {

    uint32_t leds = (1 << ok);

    uart_print("timeout ");
    uart_print_hex(ok);
    
    while (1) {
        for (uint16_t i = 0; i < 1000; i++) {
            set_leds(leds);
        }
        for (uint16_t i = 0; i < 1000; i++) {
            set_leds(0x00);
        }
    }
}

void time_update(bool reset) {

    static uint32_t last_ticks;

    if (reset) {
        last_ticks = get_ticks();
    } else if (get_ticks() - last_ticks > TIMEOUT_S * _1S_TIKCS) {
        timeout_fn();
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
                case 'M': /* Address command */
                    time_update(true); /* Reset timeout at first try */
                    ok = 0;
                    if (receive_address(&address)) {
                        last_addr = address;
                        send_ack();
                    } else {
                        send_nack();
                    }
                    break;
                case 0xDD: /* Data command */
                    time_update(true); /* Reset timeout each data chunk */
                    last_addr = receive_data(last_addr);
                    break;
                case 0xCC: /* Start command */
                    send_ack();
                    // boot();
                    // start_ptr = (void *)address;
                    // start_ptr();
                    break;
                case 'P':
                    uart_print("Addr: ");
                    uart_print_hex(address);
                    uart_print("\r\n");
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

void send_ack() {

    uart_put(0xff);
}

void send_nack() {

    uart_put(0x00);
}

bool receive_address(uint32_t *address) {

    uint32_t last_ticks = get_ticks();
    uint32_t recv_address = 0;
    uint8_t payload_length, response = 0;
    char data;

    /* Get payload length - 1s timeout */
    while (!uart_get((char *)&payload_length, false)) {
        if (get_ticks() - last_ticks > _1S_TIKCS) {
            return false;
        }
    }

    ok++;
    payload_length = 4;

    /* Get address - timeout for each byte */
    do {
        last_ticks = get_ticks();
        while (!uart_get((char *)&data, false)) {
            if (get_ticks() - last_ticks > _1S_TIKCS) {
                return false;
            }
        }
        response = response ^ data;
        recv_address = recv_address << 8 | data;
        ok++;
    } while (--payload_length);

    uart_put(response);
    *address = recv_address;

    return true;
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

    // if (chunk_length) {
    //     if (crc32_get() == crc32) {
    //         cmd_ack();
    //     } else {
    //         cma_nack();
    //     }
    // } else {
    //     cmd_ack();
    // }

    return (last_addr + chunk_length);
}