#include "leds.h"

#define LEDS ((volatile uint32_t *) 0x80000000)

void blink(void) {

    int cnt = 0;

    while (1) {
        cnt++;
        *LEDS = cnt>>15;
        // *LEDS = cnt>>10; //good for 1MHz system clock
    }
}

void set_leds(const uint32_t value) {

    *LEDS = value;
}

uint32_t get_leds(void) {

    return *LEDS;
}