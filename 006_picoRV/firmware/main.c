#include "leds.h"


void delay(void);

int main() {

    int leds = 0;

    while (1) {
        if (leds == 0b111111) { 
            leds = 0;
        }    
        set_leds(leds);
        delay();
        leds++;
    }

    return 0;
}

void delay() {

    unsigned int counter;

    for (counter = 0; counter < 30000; counter++) {
    }
}