Repository of my FPGA (Verilog) projects

Content:
> 001_i2c_pwm - led pwm driver with i2c interface (i2c source - opencores.org)
> 002_ws2812b - addressable led driver (with color generator module)
> 003_cortex_m3_blink - GW1NSR-4C Cortex-M3 Hard Core with led blink example
> 004_cortex_m3_uart - extension of previous example with uart IP Core
> 005_cortex_m3_apb_pwm - extension of previous example with PWM peripheral on APB bus
> 006_picoRV - RiscV (picorv32) core with custom peripherals (like uart, systick, led controller, cached flash) and bare-metal code
> 007_tang_nano_9k - simple examples like uart interface or lan8720 driver
> 008_spi_flash - spi interface for flash memory (for future use in picoRV)
> 009_amba - examples of ARM AMBA interface inplementations (like AXI-Stream)
> 010_one_sec_timer - high precision one second timer (250MHz pll tick) - focused on positive slack for counters paths
