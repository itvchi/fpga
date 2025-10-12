#include "leds.h"

#define LEDS ((volatile uint32_t *) 0x80000000)

void set_leds(const uint32_t value) {

    *LEDS = value;
}

uint32_t get_leds(void) {

    return *LEDS;
}