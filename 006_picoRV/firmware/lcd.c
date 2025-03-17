#include "lcd.h"
#include <stddef.h>

#define ASCII_BUFFER_WIDTH  60
#define ASCII_BUFFER_HEIGHT 17
#define ASCII_BUFFER_SIZE   (ASCII_BUFFER_WIDTH * ASCII_BUFFER_HEIGHT)
typedef struct {
    union {
        char buffer[ASCII_BUFFER_HEIGHT][ASCII_BUFFER_WIDTH];
        char data[ASCII_BUFFER_SIZE];
    };
} LcdAscii_TypeDef;

#define TILES_BUFFER_WIDTH  60
#define TILES_BUFFER_HEIGHT 34
#define TILES_BUFFER_SIZE   (TILES_BUFFER_WIDTH * TILES_BUFFER_HEIGHT)

typedef struct {
    union {
        char buffer[TILES_BUFFER_HEIGHT][TILES_BUFFER_WIDTH];
        char data[TILES_BUFFER_SIZE];
    };
} LcdTiles_TypeDef;

#define LCD_ASCII_BASE  0x80001000
#define LCD_ASCII       ((LcdAscii_TypeDef *) LCD_ASCII_BASE)
#define LCD_TILES_BASE  0x80002000
#define LCD_TILES       ((LcdTiles_TypeDef *) LCD_TILES_BASE)


unsigned int global_x, global_y;

void lcd_clear() {

    size_t index;
    char *screen = LCD_ASCII->data;

    for (index = 0; index < ASCII_BUFFER_SIZE; index++) {
        screen[index] = 0x00;
    }

    /* Tile test */
    screen = LCD_TILES->data;
    for (index = 0; index < (TILES_BUFFER_SIZE/2 - 1); index++) {
        screen[index] = 0x00;
    }
    for (; index < (TILES_BUFFER_SIZE - 1); index++) {
        screen[index] = 0x03;
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

    size_t index = y * ASCII_BUFFER_WIDTH + x;

    while (*str && index < ASCII_BUFFER_SIZE) {
        if (*str == '\r') {
            x = 0;
            index = y * ASCII_BUFFER_WIDTH + x;
        } else if (*str == '\n') {
            x = 0;
            y++;
            index = y * ASCII_BUFFER_WIDTH + x;
        } else {
            lcd_write_char_idx(str, index);
            index++;
            x++;
            if (x >= ASCII_BUFFER_WIDTH) {
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

    size_t index = y * ASCII_BUFFER_WIDTH + x;

    lcd_write_char_idx(ch, index);
}

static void lcd_write_char_idx(char *ch, unsigned int index) {

    char *screen = LCD_ASCII->data;

    if (index < ASCII_BUFFER_SIZE) {
        screen[index] = *ch;
    }
}

/* Note:
Change in memory access organisation from word to byte allow to map character buffer
on LCD memory addresses (but need hardware conversion and character range checking) 
and frees not used bytes from addess space (change from 1020 word to 1020 bytes) */