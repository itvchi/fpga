#ifndef _PWM_H_
#define _PWM_H_

#include <stdint.h>
#include <stdbool.h>

void pwm_init(uint16_t prescaler);
void pwm_set_reload(uint32_t reload);
void pwm_set_trigger(uint32_t trigger);
void pwm_set_active(bool active_state);

#endif /* _PWM_H_ */