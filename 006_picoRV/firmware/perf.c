#include "perf.h"
#include "leds.h"

#define LEDS ((volatile unsigned char *) 0x80000000)

/* Led blink takes 4.6ns */
/* With new user flash controller time decreased to 1.7ns */
void perf_flash() {

    while(1) {
        *LEDS = 0;
        *LEDS = 1;
    }
}

/* Led blink takes 1.2ns */
__attribute__((section(".code_ram")))
void perf_ram() {

    while(1) {
        *LEDS = 0;
        *LEDS = 1;
    }
}