#include "leds.h"

#define LEDS ((volatile unsigned char *) 0x80000000)

void set_leds(unsigned char val) {

    *LEDS = val;
}

unsigned char get_leds(void) {

    return *LEDS;
}