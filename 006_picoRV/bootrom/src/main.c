#include "leds.h"
#include "spi.h"
#include "system.h"

/* Boot ROM have to initialize SPI peripheral, flash controller (for code execution directly from flash) and flash IC itself */

int main() {

    int leds = 0;
    uint8_t data[] = {0xCD, 0x14, 0xE7, 0x13};

    spi_init(SPI_MODE0, 0, true);

    while (1) {
        set_leds(leds++>>16);
        spi_send_byte(0xA5);
        set_leds(leds++>>16);
        spi_send_bytes(data, sizeof(data));
    }

    return 0;
}
