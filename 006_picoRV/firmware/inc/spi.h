#ifndef _SPI_H_
#define _SPI_H_

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>


void spi_init(const bool hw_cs);
void spi_send_blocking(char byte);
void spi_send_bytes(uint8_t *data, size_t data_len);

#endif /* _SPI_H_ */