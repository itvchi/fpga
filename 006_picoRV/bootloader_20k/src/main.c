#include "leds.h"
#include "uart.h"
#include "system.h"
#include "crc32.h"
#include "systick.h"

#define _1S_TIKCS 1000
#define TIMEOUT_S 5

/* Bootloader will be placed in ROM or RAM to avoid bitstream generation
    each time the firmware is recompiled (because of SRAM mode of GW2A-18) */

void send_ack();
void send_nack();
bool receive_address(uint32_t *address);
bool receive_data(uint32_t *address);

void timeout_fn() {

    while (1) {
        uart2_print("timeout\r\n");
        set_leds(0x0E);
        delay(_1S_TIKCS/2);
        set_leds(0x00);
        delay(_1S_TIKCS/2);
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
    uart2_print("\r\nStarting bootloader (ROM)\r\n");

    systick_init(F_CPU/1000); /* 1ms per tick */
    time_update(true);
    
    crc32_init(CRC32_DATA_IN_WORD);

    while (1) {
        set_leds(leds++>>16);

        time_update(false);

        if (uart_get(&cmd, false)) {
            switch (cmd) {
                case 0xAA: /* Address command */
                    time_update(true); /* Reset timeout at first try */
                    if (receive_address(&address)) {
                        last_addr = address;
                        send_ack();
                        uart2_print("\r\nreceive_address ok\r\n");
                        uart2_print_hex(address);
                    } else {
                        send_nack();
                        uart2_print("\r\nreceive_address fails\r\n");
                    }
                    break;
                case 0xDD: /* Data command */
                    time_update(true); /* Reset timeout each data chunk */
                    if (receive_data(&last_addr)) {
                        send_ack();
                    } else {
                        send_nack();
                    }
                    break;
                case 0xCC: /* Start command */
                    send_ack();
                    // boot();
                    // start_ptr = (void *)address;
                    // start_ptr();
                    break;
                case '?': /* Test command - serial console */
                    time_update(true);
                    uart2_print("OK\r\n");
                    break;
                case 'R': /* Test command - serial console */
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

static bool uart_get_timeout(uint8_t *byte, const uint32_t timeout) {

    uint32_t last_ticks = get_ticks();

    while (!uart_get((char *)byte, false)) {
        if (get_ticks() - last_ticks > timeout) {
            return false;
        }
    }

    return true;
}

bool receive_address(uint32_t *address) {

    uint32_t recv_address = 0;
    uint8_t payload_length, response = 0;
    uint8_t byte;

    /* Get payload length - 1s timeout */
    if (!uart_get_timeout(&payload_length, _1S_TIKCS)) {
        return false;
    }

    /* Get address - timeout for each byte */
    while (payload_length--) {
        if (!uart_get_timeout(&byte, _1S_TIKCS)) {
            return false;
        }
        response = response ^ byte;
        recv_address = recv_address << 8 | byte;
    }

    uart_put(response);
    *address = recv_address;

    return true;
}

bool receive_data(uint32_t *address) {

    uint8_t payload_length, length, i, response = 0;
    uint8_t buffer[255], byte;
    uint8_t *mem_addr = (uint8_t *)address;
    uint32_t crc32 = 0;

    /* Get payload length - 1s timeout */
    if (!uart_get_timeout(&payload_length, _1S_TIKCS)) {
        return false;
    }

    if (payload_length) {
        length = payload_length;

        /* Get crc32 of payload - timeout for each byte */
        for (int i = 0; i < 4; i++) {
            if (!uart_get_timeout(&byte, _1S_TIKCS)) {
                return false;
            }
            crc32 = crc32 << 8 | byte;
        }

        /* Get payload - timeout for each byte */
        i = 0;
        do {
            if (!uart_get_timeout(&byte, _1S_TIKCS)) {
                return false;
            }
            response = response ^ byte;
            buffer[i++] = byte;
        } while (--length);
    }

    // uart_put(response);
    // *address += payload_length;

    // crc32_reset(CRC32_DATA_IN_BYTE);
    // for (i = 0; i < payload_length; i++) {
    //     mem_addr[i] = buffer[i];
    //     crc32_push(buffer[i]);
    // }

    // if (payload_length && crc32_get() != crc32) {
    //     return false;
    // }

    return true;
}