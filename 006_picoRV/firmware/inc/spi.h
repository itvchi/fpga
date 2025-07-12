#ifndef _SPI_H_
#define _SPI_H_

#include <stdint.h>

void spi_init();
void spi_send_blocking(char byte);

#endif /* _SPI_H_ */