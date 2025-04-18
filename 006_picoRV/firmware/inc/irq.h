#ifndef _IRQ_H_
#define _IRQ_H_

typedef enum {
    IRQ_TIMER = 0,
    IRQ_II,
    IRQ_BUS,
    IRQ_SYSTICK,
    IRQ_UART_RX,
    IRQ_UART_TX,
    __IRQ_COUNT
} irq_t;

typedef enum {
    IRQ_PRIO_HIGH = 0,
    IRQ_PRIO_MEDIUM,
    IRQ_PRIO_LOW,
    __IRQ_PRIO_COUNT
} irq_prio_t;

void mask_irq(irq_t irq);
void unmask_irq(irq_t irq);

#endif /* _IRQ_H_ */