#include "leds.h"
#include "perf.h"

int main() {

#if defined(EXAMPLE_PERF_FLASH)
    perf_flash();
#elif defined(EXAMPLE_PERF_RAM)
    perf_ram();
#else
    blink();
#endif

    return 0;
}