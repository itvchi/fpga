#include "uart.h"
#include "pwm.h"
#include "gw1nsr-lv4c.h"

#define F_CPU_MHZ       27
#define F_CPU_HZ        (F_CPU_MHZ * 1000000)
#define HZ_TO_TICKS(x)  (F_CPU_HZ/(x))

volatile uint32_t ticks;

void delay_ms(uint32_t ms);

void SysTick_Handler() {

    ticks++;
}

int main() {

    uart_init(UART_0, BAUDRATE_115200);
    uart_puts(UART_0, "Hello, world!\r\nCPUID: ");
    uart_print_hex(UART_0, *(unsigned int *) 0xE000ED00);
    uart_puts(UART_0, "\r\n");

    SysTick_Config(HZ_TO_TICKS(1000));

    pwm_init(2700);
    pwm_set_active(false);
    pwm_set_reload(1000);
    pwm_set_trigger(50);

    while (1) {
        delay_ms(1000);
        uart_puts(UART_0, "Set trigger to 50\r\n");
        pwm_set_trigger(50);

        delay_ms(1000);
        uart_puts(UART_0, "Set trigger to 250\r\n");
        pwm_set_trigger(250);

        delay_ms(1000);
        uart_puts(UART_0, "Set trigger to 450\r\n");
        pwm_set_trigger(450);

        delay_ms(1000);
        uart_puts(UART_0, "Set trigger to 650\r\n");
        pwm_set_trigger(650);

        delay_ms(1000);
        uart_puts(UART_0, "Set trigger to 850\r\n");
        pwm_set_trigger(850);
    }

    return 0;
}

void delay_ms(uint32_t ms) {

    uint32_t last_ticks = ticks;

    /* No conversion needed, because 1 ms = 1 tick */
    while ((ticks - last_ticks) < ms);
}