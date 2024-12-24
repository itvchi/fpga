#include "leds.h"
#include "systick.h"

#define F_CPU   27000000

int main() {

    int leds = 0;
    systick_init(0);

    while (1) {
        if (leds == 0b111111) { 
            leds = 0;
        }    
        set_leds(leds);
        systick_wait(F_CPU/2);
        leds++;
    }

    return 0;
}