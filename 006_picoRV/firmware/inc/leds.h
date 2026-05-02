#ifndef _LEDS_H_
#define _LEDS_H_

#include <stdint.h>

void blink_once(const uint8_t bitshift);
void blink(void);
void set_leds(uint32_t value);
uint32_t get_leds(void);

#endif /* _LEDS_H_*/