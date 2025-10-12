#include "spi.h"
#include "gpio.h"
#include "macros.h"


typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t PRESCALER;
    volatile uint32_t STATUS;
    volatile uint32_t TX_DATA;  
    volatile uint32_t RX_DATA;  
} Spi_TypeDef;

#define SPI_BASE    0x80000300
#define SPI         ((Spi_TypeDef *) SPI_BASE)

#define SPI_CONFIG_RESET_BIT_Pos    (0U)
#define SPI_CONFIG_RESET_BIT        (1 << SPI_CONFIG_RESET_BIT_Pos)
#define SPI_CONFIG_ENABLE_BIT_Pos   (1U)
#define SPI_CONFIG_ENABLE_BIT       (1 << SPI_CONFIG_ENABLE_BIT_Pos)
#define SPI_CONFIG_CPOL_BIT_Pos     (2U)
#define SPI_CONFIG_CPOL_BIT         (1 << SPI_CONFIG_CPOL_BIT_Pos)
#define SPI_CONFIG_CPHA_BIT_Pos     (3U)
#define SPI_CONFIG_CPHA_BIT         (1 << SPI_CONFIG_CPHA_BIT_Pos)

#define SPI_STATUS_BUSY_BIT_Pos     (0U)
#define SPI_STATUS_BUSY_BIT         (1 << SPI_STATUS_BUSY_BIT_Pos)

void spi_init(const Spi_Mode mode, const uint8_t clk_prescaler, const bool hw_cs) {

    SET_BIT(SPI->CONFIG, SPI_CONFIG_RESET_BIT); /* Reset */
    while (READ_BIT(SPI->CONFIG, SPI_CONFIG_RESET_BIT)); /* Wait until reset done */

    SPI->PRESCALER = clk_prescaler;
    if (mode == SPI_MODE2 || mode == SPI_MODE3) {
        SET_BIT(SPI->CONFIG, SPI_CONFIG_CPOL_BIT);
    }
    if (mode == SPI_MODE1 || mode == SPI_MODE3) {
        SET_BIT(SPI->CONFIG, SPI_CONFIG_CPHA_BIT);
    }

    SET_BIT(SPI->CONFIG, SPI_CONFIG_ENABLE_BIT); /* Enable spi */

    if (hw_cs) {
        gpio_set_mode(GPIO_MODE_AF, 2);
    }
    gpio_set_mode(GPIO_MODE_AF, 3);
    gpio_set_mode(GPIO_MODE_AF, 4);
}

void spi_send_byte(uint8_t byte) {

    while (READ_BIT(SPI->STATUS, SPI_STATUS_BUSY_BIT));
    SPI->TX_DATA = byte;
}

void spi_send_bytes(uint8_t *data, size_t data_len) {

    size_t idx;

    while (READ_BIT(SPI->STATUS, SPI_STATUS_BUSY_BIT));

    for (idx = 0; idx < data_len; idx++) {
        SPI->TX_DATA = data[idx];
    }
}