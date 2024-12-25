#include "systick.h"


void systick_init(uint32_t prescaler) {

    SystickConfig_TypeDef *config = (SystickConfig_TypeDef *)&(SYSTICK->CONFIG);

    config->reset = 1; /* Reset */
    while (config->reset); /* Wait until reset done */
    config->prescaler = (prescaler << 16); /* Set prescaler */
}

void systick_irq(bool enable) {

    SystickConfig_TypeDef *config = (SystickConfig_TypeDef *)&(SYSTICK->CONFIG);

    config->irq = enable; /* Set irq state */
}

void systick_start(uint32_t value) {

    SystickConfig_TypeDef *config = (SystickConfig_TypeDef *)&(SYSTICK->CONFIG);

    SYSTICK->COUNTER = value;
    config->enable = 1; /* Enable timer */
}

void systick_wait(uint32_t value) {

    SystickConfig_TypeDef *config = (SystickConfig_TypeDef *)&(SYSTICK->CONFIG);
    SystickStatus_TypeDef *status = (SystickStatus_TypeDef *)&(SYSTICK->STATUS);

    SYSTICK->COUNTER = value;
    config->enable = 1; /* Enable timer */
    while (status->pending); /* Wait until count is done */
}