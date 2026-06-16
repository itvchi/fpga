`timescale 1ns / 100ps
`include "tod_nco.v"

module tod_nco_tb;

    reg clk;
    reg rst_n;
    reg pps_in;
    wire pps_out;
    wire [31:0] latched_seconds;
    wire [31:0] latched_nanoseconds;
    reg [31:0] freq_adj;
    reg freq_update;
    reg [31:0] phase_adj;
    reg phase_update;

    localparam CLOCK_PERIOD = 0.8;
    localparam ONE_SEC_PERIOD = 1_000_000_000;
    localparam ONE_MILISEC_PERIOD = ONE_SEC_PERIOD/1000;
    localparam ONE_MICROSEC_PERIOD = ONE_MILISEC_PERIOD/1000;

    tod_nco #(
        .CLK_FREQ(1_250_000) /* = 125_000_000/100 */
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .pps_in(pps_in),
        .freq_adj(freq_adj),
        .freq_update(freq_update),
        .phase_adj(phase_adj),
        .phase_update(phase_update),
        .pps_out(pps_out),
        .latched_seconds(latched_seconds),
        .latched_nanoseconds(latched_nanoseconds)
    );

    // Reference clock
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end

    // 1pps input
    initial begin
        pps_in = 0;
        #1200;
        pps_in = 1;
        forever begin
            #(ONE_MILISEC_PERIOD/2); pps_in = 0;
            #(ONE_MILISEC_PERIOD/2); pps_in = 1;
        end 
    end

    initial begin
        freq_adj = -32'd100;
        freq_update = 1'b0;
        #(2*ONE_MILISEC_PERIOD + 2000)
        freq_update = 1'b1;
        #10;
        freq_update = 1'b0;
    end

    initial begin
        phase_adj = 32'd1;
        phase_update = 1'b0;
        #(ONE_MILISEC_PERIOD + 1000)
        phase_update = 1'b1;
        #10;
        phase_update = 1'b0;
    end

    initial begin
        rst_n = 0;
        #1000;
        rst_n = 1;
        #8005000;
        $finish;
    end

    initial begin
        $dumpfile("tod_nco_tb.vcd");
        $dumpvars(0, tod_nco_tb);
    end


endmodule