#include "st7789_lcd/lcd.h"
#include "st7789_lcd/st7789.h"
#include "spi.h"
#include "uart.h"
#include "system.h"
#include "systick.h"
#include <stdio.h>


void app_st7789() {

    char buffer[64];
    uint32_t start;

    uart_init(F_CPU / (2 * BAUDRATE));
    uart_print_irq("Hello world!\r\n");

    spi_init(false);
    LCD_GPIO_Init();
    delay_ms(100);

    ST7789_Init(ST7789_RESOLUTION_170X320, ST7789_ROTATION_180);

    uart_print_irq("Init done!\r\n");

    ST7789_Fill_Color(RED);
    delay_ms(1000); 

    while (1) {
        start = get_millis();
        ST7789_Test();
        sprintf(buffer, "Test done in %ld ms\r\n", get_millis() - start);
        uart_print_irq(buffer);
    }
}



