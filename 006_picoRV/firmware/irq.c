#include "irq.h"

#define IRQ_BITMASK(x)  (1 << (x))

extern unsigned int __maskirq;
extern unsigned int maskirq_instr(unsigned int mask);

static irq_prio_t __irq_prio[__IRQ_COUNT] = {
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

unsigned int *irq(unsigned int *regs, unsigned int irqs) {

    irq_prio_t priority;

    for (priority = IRQ_PRIO_HIGH; priority < __IRQ_PRIO_COUNT; priority++) {
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