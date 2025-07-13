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

void app_base();
void app_lcd();

int main() {

    // perf_flash();
    // perf_ram();
    
#if defined(CONFIG_WITH_SYSTICK)
    systick_add_event(led_action, (void*)&leds, SYSTICK_PRIO_HIGH, 200);
    systick_init_irq(0, F_CPU/100);
#endif /* defined(CONFIG_WITH_SYSTICK) */

#if defined(CONFIG_FS_MINIMAL)
    while (1) {}
#elif defined(CONFIG_FS_BASE)
    app_base();
#elif defined(CONFIG_FS_LCD)
    app_lcd();
#endif

return 0;
}