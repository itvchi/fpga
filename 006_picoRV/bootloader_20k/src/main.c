#include "leds.h"
#include "uart.h"
#include "system.h"
#include "crc32.h"
#include "systick.h"

#define DEBUG

#ifdef DEBUG
#define debug_print(x)      uart2_print(x)
#define debug_print_hex(x)  uart2_print_hex(x)
#else
#define debug_print(x)
#define debug_print_hex(x)
#endif

#define TICKS_PER_1S 1000
#define TIMEOUT_S 5

/* Bootloader will be placed in ROM or RAM to avoid bitstream generation
    each time the firmware is recompiled (because of SRAM mode of GW2A-18) */

void send_ack();
void send_nack();
bool receive_data(bool cmd_address, uint32_t *address);

void timeout_fn() {

    while (1) {
        debug_print("timeout\r\n");
        set_leds(0x0E);
        delay(TICKS_PER_1S/2);
        set_leds(0x00);
        delay(TICKS_PER_1S/2);
    }
}

void time_update(bool reset) {

    static uint32_t last_ticks;

    if (reset) {
        last_ticks = get_ticks();
    } else if (get_ticks() - last_ticks > TIMEOUT_S * TICKS_PER_1S) {
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
    debug_print("\r\nBoot (ROM)\r\n");

    systick_init(F_CPU/TICKS_PER_1S); /* 1ms per tick */
    time_update(true);
    
    crc32_init(CRC32_DATA_IN_WORD);

    while (1) {
        set_leds(leds++>>16);

        time_update(false);

        if (uart_get(&cmd, false)) {
            switch (cmd) {
                case 0xAA: /* Address command */
                    time_update(true); /* Reset timeout at first try */
                    if (receive_data(true, &address)) {
                        last_addr = address;
                        debug_print("addr ");
                        debug_print_hex(address);
                        debug_print("\r\n");
                        send_ack();
                    } else {
                        send_nack();
                    }
                    break;
                case 0xDD: /* Data command */
                    time_update(true); /* Reset timeout each data chunk */
                    if (receive_data(false, &last_addr)) {
                        debug_print("data - new addr ");
                        debug_print_hex(last_addr);
                        debug_print("\r\n");
                        send_ack();
                    } else {
                        debug_print("data - failed\r\n");
                        send_nack();
                    }
                    break;
                case 0xCC: /* Start command */
                    send_ack();
                    // boot();
                    // start_ptr = (void *)address;
                    // start_ptr();
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

static uint32_t adress_from_buffer(const uint8_t *buffer) {

    return buffer[0] << 24 | buffer[1] << 16 | buffer[2] << 8 | buffer[3];
}

bool receive_data(bool cmd_address, uint32_t *address) {

    uint8_t payload_length, length, i, byte;
    uint8_t buffer[255];
    uint8_t *mem_addr = (uint8_t *)*address;
    uint32_t crc32 = 0;

    /* Get payload length - 1s timeout */
    if (!uart_get_timeout(&payload_length, TICKS_PER_1S)) {
        return false;
    }

    if (payload_length) {
        length = payload_length;

        /* Get crc32 of payload - timeout for each byte */
        for (i = 0; i < 4; i++) {
            if (!uart_get_timeout(&byte, TICKS_PER_1S)) {
                return false;
            }
            crc32 = crc32 << 8 | byte;
        }

        /* Get payload - timeout for each byte */
        i = 0;
        do {
            if (!uart_get_timeout(&byte, TICKS_PER_1S)) {
                return false;
            }
            buffer[i++] = byte;
        } while (--length);
    }

    crc32_reset(CRC32_DATA_IN_BYTE);
    for (i = 0; i < payload_length; i++) {
        crc32_push(buffer[i]);
    }

    if (payload_length && (crc32_get() != crc32)) {
        return false;
    }

    if (cmd_address) {
        if (payload_length != 4) {
            return false;
        }
        *address = adress_from_buffer(buffer);
    } else {
        debug_print("programming ");
        debug_print_hex((uint32_t)mem_addr);
        debug_print("\r\n");

        for (i = 0; i < payload_length; i++) {
            mem_addr[i] = buffer[i];
        }
        *address += payload_length;
    }

    return true;
}