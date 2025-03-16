#include <stdio.h>
#include "font8x16.h"

int main(int argc, char const *argv[]) {

    size_t char_idx, line;
    size_t characters = sizeof(ssd1306xled_font8x16) / 16;
    FILE *fptr = fopen("ascii.hex", "w");

    for (char_idx = 0; char_idx < characters; char_idx++) {
        unsigned int bytes[16] = {0};
        size_t pos = char_idx * 16;

        /* Lines 1 -> 8 */
        for (line = 0; line < 8; line++) {
            bytes[line] = ((ssd1306xled_font8x16[pos] & (1 << line)) ? 1 : 0) << 0 |
                        ((ssd1306xled_font8x16[pos + 1] & (1 << line)) ? 1 : 0) << 1 |
                        ((ssd1306xled_font8x16[pos + 2] & (1 << line)) ? 1 : 0) << 2 |
                        ((ssd1306xled_font8x16[pos + 3] & (1 << line)) ? 1 : 0) << 3 |
                        ((ssd1306xled_font8x16[pos + 4] & (1 << line)) ? 1 : 0) << 4 | 
                        ((ssd1306xled_font8x16[pos + 5] & (1 << line)) ? 1 : 0) << 5 |
                        ((ssd1306xled_font8x16[pos + 6] & (1 << line)) ? 1 : 0) << 6 |
                        ((ssd1306xled_font8x16[pos + 7] & (1 << line)) ? 1 : 0) << 7;
        }
        /* Lines 9 -> 16 */
        for (line = 0; line < 8; line++) {
            bytes[8 + line] = ((ssd1306xled_font8x16[pos + 8] & (1 << line)) ? 1 : 0) << 0 |
                        ((ssd1306xled_font8x16[pos + 9] & (1 << line)) ? 1 : 0) << 1 |
                        ((ssd1306xled_font8x16[pos + 10] & (1 << line)) ? 1 : 0) << 2 |
                        ((ssd1306xled_font8x16[pos + 11] & (1 << line)) ? 1 : 0) << 3 |
                        ((ssd1306xled_font8x16[pos + 12] & (1 << line)) ? 1 : 0) << 4 |
                        ((ssd1306xled_font8x16[pos + 13] & (1 << line)) ? 1 : 0) << 5 |
                        ((ssd1306xled_font8x16[pos + 14] & (1 << line)) ? 1 : 0) << 6 |
                        ((ssd1306xled_font8x16[pos + 15] & (1 << line)) ? 1 : 0) << 7;
        }

        /* Display results (and write to ascii.hex file) */
        printf("char %2ld = ", char_idx);
        for (line = 0; line < 16; line++) {
            printf("%02x ", bytes[line]);
            fprintf(fptr, "%02x\n", bytes[line]);
        }
        printf("\n");
    }

    /* Generate array of subsequent characters to display (and write to screen.hex file) */
    size_t height, width;
    unsigned int cr = 0;
    fptr = fopen("screen.hex", "w");
    for (height = 0; height < 17; height++) {
        for (width = 0; width < 60; width++) {
            fprintf(fptr, "%02x\n", cr);
            cr = (cr + 1) % 90;
        }
    }
    
    return 0;
}
