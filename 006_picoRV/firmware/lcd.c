#include "lcd.h"
#include <stddef.h>

#define LCD ((unsigned int *) 0x80001000)
#define SCREEN_WIDTH    60
#define SCREEN_HEIGHT   17
#define SCREEN_SIZE     (SCREEN_WIDTH * SCREEN_HEIGHT)


unsigned int global_x, global_y;

void lcd_clear() {

    unsigned int *screen = LCD;

    for (size_t index = 0; index < SCREEN_SIZE; index++) {
        screen[index] = 0x00;
    }

    global_x = 0;
    global_y = 0;
}

static void lcd_write_char(char *ch, unsigned int x, unsigned int y);
static void lcd_write_char_idx(char *ch, unsigned int index);

void lcd_write_str(char *str) {

    lcd_write_str_xy(str, global_x, global_y);
}

void lcd_write_str_xy(char *str, unsigned int x, unsigned int y) {

    size_t index = y * SCREEN_WIDTH + x;

    while (*str && index < SCREEN_SIZE) {
        if (*str == '\r') {
            x = 0;
            index = y * SCREEN_WIDTH + x;
        } else if (*str == '\n') {
            x = 0;
            y++;
            index = y * SCREEN_WIDTH + x;
        } else {
            lcd_write_char_idx(str, index);
            index++;
            x++;
            if (x >= SCREEN_WIDTH) {
                x = 0;
                y++;
            }
        }
        str++;
    }

    global_x = x;
    global_y = y;
}

static void lcd_write_char(char *ch, unsigned int x, unsigned int y) {

    size_t index = y * SCREEN_WIDTH + x;

    lcd_write_char_idx(ch, index);
}

static void lcd_write_char_idx(char *ch, unsigned int index) {

    unsigned int *screen = LCD;

    if (index < SCREEN_SIZE) {
        if (*ch < 0x20 || *ch > 0x7E) {
            screen[index] = 0x20; /* Space */
        } else {
            screen[index] = *ch - 0x20;
        }
    }
}