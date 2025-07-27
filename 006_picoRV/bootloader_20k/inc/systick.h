#ifndef _SYSTICK_H_
#define _SYSTICK_H_

#include <stdint.h>

void systick_init(uint32_t prescaler);
uint32_t get_ticks();
void delay(uint32_t ticks);

#endif /* _SYSTICK_H_ */