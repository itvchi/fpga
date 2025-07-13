#ifndef _SPI_H_
#define _SPI_H_

#include <stdint.h>
#include <stdbool.h>


void spi_init(const bool hw_cs);
void spi_send_blocking(char byte);

#endif /* _SPI_H_ */