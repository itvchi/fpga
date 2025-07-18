#include "leds.h"

volatile int leds;

/* Bootloader will be placed in ROM or RAM to avoid bitstream generation
    each time the firmware is recompiled (because of SRAM mode of GW2A-18) */

int main() {

    while(1) {
        leds++;
        set_leds(leds>>16);
    }

    return 0;
}