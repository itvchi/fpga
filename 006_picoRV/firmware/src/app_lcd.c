#include "lcd.h"


int app_lcd() {

    lcd_clear();
    lcd_write_str("Hello world!!!");
    lcd_write_str_xy("This is wrapped line ->\r this should be at front", 30, 3);
    lcd_write_str_xy("This is first line\n And this should be line below", 0, 6);

    while (1) {
    }

    return 0;
}