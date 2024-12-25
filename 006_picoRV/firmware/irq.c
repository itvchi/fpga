#include "irq.h"

#define IRQ_BITMASK(x)  (1 << (x))

extern unsigned int __maskirq;
extern unsigned int maskirq_instr(unsigned int mask);

unsigned int __irq_prio[__IRQ_COUNT] = {
    IRQ_PRIO_HIGH,
    IRQ_PRIO_HIGH,
    IRQ_PRIO_HIGH,
    IRQ_PRIO_LOW,
};

static void __default_handler() {

}

void __attribute__((weak, alias("__default_handler"))) timer_irq_handler();
void __attribute__((weak, alias("__default_handler"))) illegal_instr_irq_handler();
void __attribute__((weak, alias("__default_handler"))) bus_error_irq_handler();
void __attribute__((weak, alias("__default_handler"))) systick_irq_handler();


void mask_irq(irq_t irq) {

    __maskirq |= 1 << irq;
    __maskirq = maskirq_instr(__maskirq);
}

void unmask_irq(irq_t irq) {

    __maskirq &= 1 << irq;
    __maskirq = maskirq_instr(__maskirq);
}

void irq_init() {
    __irq_prio[IRQ_TIMER] = IRQ_PRIO_HIGH;
    __irq_prio[IRQ_II] = IRQ_PRIO_HIGH;
    __irq_prio[IRQ_BUS] = IRQ_PRIO_HIGH;
    __irq_prio[IRQ_SYSTICK] = IRQ_PRIO_LOW;
}

unsigned int *irq(unsigned int *regs, unsigned int irqs) {

    unsigned int priority;

    for (priority = IRQ_PRIO_HIGH; priority < __IRQ_COUNT; priority++) {
        if ((__irq_prio[IRQ_TIMER] == priority) && (irqs & IRQ_BITMASK(IRQ_TIMER))) {
            timer_irq_handler();
        }

        if ((__irq_prio[IRQ_II] == priority) && (irqs & IRQ_BITMASK(IRQ_II))) {
            illegal_instr_irq_handler();
        }

        if ((__irq_prio[IRQ_BUS] == priority) && (irqs & IRQ_BITMASK(IRQ_BUS))) {
            bus_error_irq_handler();
        }

        if ((__irq_prio[IRQ_SYSTICK] == priority) && (irqs & IRQ_BITMASK(IRQ_SYSTICK))) {
            systick_irq_handler();
        }
    }

    return regs;
}