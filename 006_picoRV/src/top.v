module top (
    input clk,
    input rst_btn_n,
    output [5:0] leds,
    input rx_gpio,
    output tx_gpio,
    output cache_hit,
    output cache_miss);
    
    parameter BARREL_SHIFTER = 0;
    parameter ENABLE_MUL = 0;
    parameter ENABLE_DIV = 0;
    parameter ENABLE_FAST_MUL = 0;
    parameter ENABLE_COMPRESSED = 0;
    parameter ENABLE_IRQ = 1;
    parameter ENABLE_IRQ_QREGS = 1;
    parameter MASKED_IRQ = 32'hffff_ffc0;
    parameter LATCHED_IRQ = 32'hffff_ffff;

    parameter integer MEMBYTES = 8192;
    parameter [31:0] STACKADDR = 32'h0002_0000 + (MEMBYTES);
    parameter [31:0] PROGADDR_RESET = 32'h0000_0000;    
    parameter [31:0] PROGADDR_IRQ = 32'h0000_0100;

    wire        reset_n; 
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    wire [3:0]  mem_wstrb;
    wire        mem_ready;
    wire        mem_instr;
    wire        mem_valid;

    reg         leds_sel;
    wire        leds_ready;
    wire [31:0] leds_data_o;

    reg         sram_sel;
    wire        sram_ready;
    wire [31:0] sram_data_o;
    
    reg         systick_sel;
    wire        systick_ready;
    wire [31:0] systick_data_o;
    wire        systick_irq;

    reg         flash_sel;
    wire [31:0] flash_data_o;
    wire        flash_ready;

    reg         uart_sel;
    wire        uart_ready;
    wire [31:0] uart_data_o;
    wire        uart_rx_irq;
    wire        uart_tx_irq;

    /* Assign slave select signal basing on mem_addr */
    /* Memory map for all slaves:
     * FLASH    00000000 - 00012fff
     * SRAM     00020000 - 00021fff
     * MM_LED   80000000
     * SYSTICK  80000100 - 80000110
     * UART     80000200 - 80000220
    */

    always @(*) begin
        sram_sel <= 1'b0;
        leds_sel <= 1'b0;               
        systick_sel <= 1'b0;
        flash_sel <= 1'b0;
        uart_sel <= 1'b0;

        if (mem_valid) begin
            if (mem_addr < 32'h1_3000) begin
                flash_sel <= 1'b1;
            end else if ((mem_addr >= 32'h2_0000) && (mem_addr < 32'h2_2000)) begin
                sram_sel <= 1'b1;
            end else if (mem_addr == 32'h8000_0000) begin
                leds_sel <= 1'b1;
            end else if ((mem_addr >= 32'h8000_0100) && (mem_addr < 32'h8000_0110)) begin
                systick_sel <= 1'b1;
            end else if ((mem_addr >= 32'h8000_0200) && (mem_addr < 32'h8000_0220)) begin
                uart_sel <= 1'b1;
            end
        end
    end

    /* Assign mem_ready signal */
    assign mem_ready = mem_valid & (sram_ready | leds_ready | systick_ready | flash_ready | uart_ready);

    /* mem_rdata bus multiplexer */
    assign mem_rdata = sram_sel ? sram_data_o :
                        leds_sel ? leds_data_o :
                        systick_sel ? systick_data_o :
                        flash_sel ? flash_data_o : 
                        uart_sel ? uart_data_o : 32'h0;

    reset_control reset_controller (
        .clk(clk),
        .rst_btn_n(rst_btn_n),
        .reset_n(reset_n));

    sram #(.ADDRWIDTH(13)) memory (
        .clk(clk),
        .reset_n(reset_n),      
        .select(sram_sel),
        .wstrb(mem_wstrb),
        .addr(mem_addr[12:0]),
        .data_i(mem_wdata),
        .ready(sram_ready),
        .data_o(sram_data_o));

    mm_leds leds_slave (
        .clk(clk),
        .reset_n(reset_n),
        .select(leds_sel),
        .data_i(mem_wdata),
        .write_en(mem_wstrb[0]),
        .ready(leds_ready),
        .data_o(leds_data_o));

    systick timer (
        .clk(clk),
        .reset_n(reset_n),
        .select(systick_sel),
        .wstrb(mem_wstrb),
        .addr(mem_addr[3:0]),
        .data_i(mem_wdata),
        .ready(systick_ready),
        .data_o(systick_data_o),
        .irq(systick_irq));

    user_flash_custom flash (
        .clk(clk),
        .reset_n(reset_n),
        .select(flash_sel),
        .wstrb(mem_wstrb),
        .addr(mem_addr[16:2]), // word address, 9-bits row, 6 bits col
        .data_i(mem_wdata),
        .ready(flash_ready),
        .data_o(flash_data_o),
        .cache_hit(cache_hit),
        .cache_miss(cache_miss));

    uart uart_periph (
        .clk(clk),
        .reset_n(reset_n),
        .select(uart_sel),
        .wstrb(mem_wstrb),
        .addr(mem_addr[4:0]),
        .data_i(mem_wdata),
        .ready(uart_ready),
        .data_o(uart_data_o),
        .rx(rx_gpio),
        .tx(tx_gpio),
        .irq_rx(uart_rx_irq),
        .irq_tx(uart_tx_irq));

    wire trap_unconnected;
    wire mem_la_read_unconnected;
    wire mem_la_write_unconnected;
    wire [31:0] mem_la_addr_unconnected;
    wire [31:0] mem_la_wdata_unconnected;
    wire [ 3:0] mem_la_wstrb_unconnected;
    wire pcpi_valid_unconnected;
    wire [31:0] pcpi_insn_unconnected;
    wire [31:0] pcpi_rs1_unconnected;
    wire [31:0] pcpi_rs2_unconnected;
    wire [31:0] eoi_unconnected;
    wire trace_valid_unconnected;
	wire [35:0] trace_data_unconnected;

    picorv32 #(
        .STACKADDR(STACKADDR),
        .PROGADDR_RESET(PROGADDR_RESET),
        .PROGADDR_IRQ(PROGADDR_IRQ),
        .BARREL_SHIFTER(BARREL_SHIFTER),
        .COMPRESSED_ISA(ENABLE_COMPRESSED),
        .ENABLE_MUL(ENABLE_MUL),
        .ENABLE_DIV(ENABLE_DIV),
        .ENABLE_FAST_MUL(ENABLE_FAST_MUL),
        .ENABLE_IRQ(ENABLE_IRQ),
        .ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS),
        .MASKED_IRQ(MASKED_IRQ),
        .LATCHED_IRQ(LATCHED_IRQ)
    ) cpu (
        .clk         (clk),
        .resetn      (reset_n),
        .mem_valid   (mem_valid),
        .mem_instr   (mem_instr),
        .mem_ready   (mem_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (mem_rdata),
        .irq         ({26'b0, uart_tx_irq, uart_rx_irq, systick_irq, 3'b0}),
        .trap           (trap_unconnected),
        .mem_la_read    (mem_la_read_unconnected),
        .mem_la_write   (mem_la_write_unconnected),
        .mem_la_addr    (mem_la_addr_unconnected),
        .mem_la_wdata   (mem_la_wdata_unconnected),
        .mem_la_wstrb   (mem_la_wstrb_unconnected),
        .pcpi_wr        (1'b0),
        .pcpi_rd        (32'b0),
        .pcpi_wait      (1'b0),
        .pcpi_ready     (1'b0),
        .pcpi_valid     (pcpi_valid_unconnected),
        .pcpi_insn      (pcpi_insn_unconnected),
        .pcpi_rs1       (pcpi_rs1_unconnected),
        .pcpi_rs2       (pcpi_rs2_unconnected),
        .eoi            (eoi_unconnected),
        .trace_valid    (trace_valid_unconnected),
        .trace_data     (trace_data_unconnected));


    assign leds = ~leds_data_o[5:0];

endmodule // top