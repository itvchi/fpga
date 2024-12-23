#include "pwm.h"
#include "gw1nsr-lv4c.h"


void pwm_init(uint16_t prescaler) {

    PWM0->CONFIG |= (1 << 0); /* Reset */

    while (PWM0->CONFIG & (1 << 0)); /* Wait until reset done */

    PWM0->CONFIG |= (prescaler << 16) | (1 << 1); /* Set prescaler and enable */
}

void pwm_set_reload(uint32_t reload) {

    PWM0->RELOAD = reload;
}

void pwm_set_trigger(uint32_t trigger) {

    PWM0->TRIGGER = trigger;
}

void pwm_set_active(bool active_state) {

    PWM0->CONFIG &= (1 << 3);
    PWM0->CONFIG |= (active_state << 3);
}