#ifndef _SPI_H_
#define _SPI_H_

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>


typedef enum {
    SPI_MODE0 = 0,
    SPI_MODE1,
    SPI_MODE2,
    SPI_MODE3
} Spi_Mode;

void spi_init(const Spi_Mode mode, const uint8_t clk_prescaler, const bool hw_cs);
void spi_send_byte(uint8_t byte);
void spi_send_bytes(uint8_t *data, size_t data_len);

#endif /* _SPI_H_ */