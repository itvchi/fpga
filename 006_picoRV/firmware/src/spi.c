#include "spi.h"
#include "gpio.h"


typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t PRESCALER;
    volatile uint32_t STATUS;
    volatile uint32_t TX_DATA;  
} Spi_TypeDef;

typedef union {
    uint32_t value;
    struct {
        uint32_t reset          :  1; /* Reset peripheral */
        uint32_t enable         :  1; /* Enable uart */
        uint32_t reserved2_31   : 30;
    };
} SpiConfig_TypeDef;

typedef union {
    uint32_t value;
    struct {
        uint32_t tx_busy        :  1; /* Tx data sending */
        uint32_t reserved1_31   : 31;
    };
} SpiStatus_TypeDef;

#define SPI_BASE    0x80000300
#define SPI         ((Spi_TypeDef *) SPI_BASE)


void spi_init(const bool hw_cs) {

    SpiConfig_TypeDef *config = (SpiConfig_TypeDef *)&(SPI->CONFIG);

    config->reset = 1; /* Reset */
    while (config->reset); /* Wait until reset done */

    config->enable = 1; /* Enable spi */

    if (hw_cs) {
        gpio_set_mode(GPIO_MODE_AF, 2);
    }
    gpio_set_mode(GPIO_MODE_AF, 3);
    gpio_set_mode(GPIO_MODE_AF, 4);
}

void spi_send_blocking(char byte) {

    SpiStatus_TypeDef *status = (SpiStatus_TypeDef *)&(SPI->STATUS);

    while (status->tx_busy);
    SPI->TX_DATA = byte;
}

__attribute__((section(".code_ram")))
void spi_send_bytes(uint8_t *data, size_t data_len) {

    SpiStatus_TypeDef *status = (SpiStatus_TypeDef *)&(SPI->STATUS);
    size_t idx;

    for (idx = 0; idx < data_len; idx++) {
        while (status->tx_busy);
        SPI->TX_DATA = data[idx];
    }
}