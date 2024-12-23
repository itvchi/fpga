module top (
    input clk,
    input rst_btn_n,
    output [5:0] leds);
    
    parameter [0:0] BARREL_SHIFTER = 0;
    parameter [0:0] ENABLE_MUL = 0;
    parameter [0:0] ENABLE_DIV = 0;
    parameter [0:0] ENABLE_FAST_MUL = 0;
    parameter [0:0] ENABLE_COMPRESSED = 0;
    parameter [0:0] ENABLE_IRQ_QREGS = 0;

    parameter integer MEMBYTES = 8192;
    parameter [31:0] STACKADDR = (MEMBYTES);
    parameter [31:0] PROGADDR_RESET = 32'h0000_0000;
    parameter [31:0] PROGADDR_IRQ = 32'h0000_0000;

    wire        reset_n; 
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    wire [3:0]  mem_wstrb;
    wire        mem_ready;
    wire        mem_instr;
    wire        leds_sel;
    wire        leds_ready;
    wire [31:0] leds_data_o;
    wire        sram_sel;
    wire        sram_ready;
    wire [31:0] sram_data_o;

    /* Assign slave select signal basing on mem_addr */
    /* Memory map for all slaves:
     * SRAM     00000000 - 0001ffff
     * MM_LED   80000000
    */
    assign sram_sel = mem_valid && (mem_addr < 32'h00002000);
    assign leds_sel = mem_valid && (mem_addr == 32'h80000000);

    /* Assign mem_ready signal */
    assign mem_ready = mem_valid & (sram_ready | leds_ready);

    /* mem_rdata bus multiplexer */
    assign mem_rdata = sram_sel ? sram_data_o :
                        leds_sel ? leds_data_o : 32'h0;

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
        .data_i(mem_wdata[5:0]),
        .write_en(mem_wstrb[0]),
        .ready(leds_ready),
        .data_o(leds_data_o));

    picorv32 #(
        .STACKADDR(STACKADDR),
        .PROGADDR_RESET(PROGADDR_RESET),
        .PROGADDR_IRQ(PROGADDR_IRQ),
        .BARREL_SHIFTER(BARREL_SHIFTER),
        .COMPRESSED_ISA(ENABLE_COMPRESSED),
        .ENABLE_MUL(ENABLE_MUL),
        .ENABLE_DIV(ENABLE_DIV),
        .ENABLE_FAST_MUL(ENABLE_FAST_MUL),
        .ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
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
        .irq         ('b0));


    assign leds = ~leds_data_o[5:0];

endmodule // top