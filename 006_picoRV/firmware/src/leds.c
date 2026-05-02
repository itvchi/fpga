#include "leds.h"

#define LEDS ((volatile uint32_t *) 0x80000000)

static int cnt;

void blink_once(const uint8_t bitshift) {

    cnt++;
    *LEDS = cnt>>bitshift;
}

void blink(void) {

    while (1) {
        blink_once(15);
        // blink_once(10); //good for 1MHz system clock
    }
}

void set_leds(const uint32_t value) {

    *LEDS = value;
}

uint32_t get_leds(void) {

    return *LEDS;
}