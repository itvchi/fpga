#include "st7789.h"
#include "gpio.h"
#include "spi.h"

#define LCD_CS_PIN		2
#define LCD_RST_PIN		5
#define LCD_DC_PIN		6


void LCD_GPIO_Init() {

    gpio_set_mode(GPIO_MODE_OUTPUT, LCD_CS_PIN);
    gpio_set_mode(GPIO_MODE_OUTPUT, LCD_RST_PIN);
    gpio_set_mode(GPIO_MODE_OUTPUT, LCD_DC_PIN);

    gpio_write_pin(LCD_CS_PIN, GPIO_STATE_HIGH);
    gpio_write_pin(LCD_RST_PIN, GPIO_STATE_LOW);
    gpio_write_pin(LCD_DC_PIN, GPIO_STATE_LOW);
}

/* ST7789 API implementation */
void ST7789_RST_Clr() {

    gpio_write_pin(LCD_RST_PIN, GPIO_STATE_LOW);
}

void ST7789_RST_Set() {

    gpio_write_pin(LCD_RST_PIN, GPIO_STATE_HIGH);
}

void ST7789_DC_Clr() {

    gpio_write_pin(LCD_DC_PIN, GPIO_STATE_LOW);
}

void ST7789_DC_Set() {

    gpio_write_pin(LCD_DC_PIN, GPIO_STATE_HIGH);
}

void ST7789_Select() {

    gpio_write_pin(LCD_CS_PIN, GPIO_STATE_LOW);
}

void ST7789_UnSelect() {

    gpio_write_pin(LCD_CS_PIN, GPIO_STATE_HIGH);
}

void ST7789_SPI_Transmit(uint8_t *data, size_t data_len) {

    spi_send_bytes(data, data_len);
}
