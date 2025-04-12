#include "perf.h"
#include "leds.h"
#include "systick.h"
#include "system.h"

volatile int leds;

void led_action(void* ctx) {

    volatile int *led_ctx = (volatile int*)ctx;
    *led_ctx ^= 0b000011;
    set_leds(*led_ctx);
}

int app_minimal();
int app_base();
int app_lcd();

int main() {

    // perf_flash();
    // perf_ram();
    
#if defined(CONFIG_WITH_SYSTICK)
    systick_add_event(led_action, (void*)&leds, SYSTICK_PRIO_HIGH, 2);
    systick_init_irq(0, F_CPU/10);
#endif /* defined(CONFIG_WITH_SYSTICK) */

#if defined(CONFIG_FS_MINIMAL)
    return app_minimal();
#elif defined(CONFIG_FS_BASE)
    return app_base();
#elif defined(CONFIG_FS_LCD)
    return app_lcd();
#else 
    return 0;
#endif
}