#include "leds.h"
#include "spi.h"
#include "system.h"

/* Boot ROM have to initialize SPI peripheral, flash controller (for code execution directly from flash) and flash IC itself */

int main() {

    int leds = 0;
    uint8_t data[] = {0x9F, 0x00, 0x00, 0x00};
    uint8_t rec[10] = {};

    spi_init(SPI_MODE0, 0, true);

    spi_send_byte(0xFF);
    spi_send_byte(0xAB);
    spi_transfer(data, rec, sizeof(data));
    rec[0] = 0xFF;
    spi_transfer(rec, NULL, sizeof(rec));

    while (1) {
        set_leds(leds++>>16);
    }

    return 0;
}
