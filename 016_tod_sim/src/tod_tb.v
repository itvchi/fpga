`timescale 1ns / 100ps
`include "tod.v"

module tod_tb;

    reg clk;
    reg rst_n;
    reg pps_in;
    wire pps_out;
    wire [31:0] latched_seconds;
    wire [31:0] latched_nanoseconds;

    tod #(
        .CLK_FREQ(250_000) /* = 125_000_000/500 */
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .pps_in(pps_in),
        // .freq_adj(),
        .freq_update(1'b0),
        // .phase_offset(),
        .phase_update(1'b0),
        .pps_out(pps_out),
        .latched_seconds(latched_seconds),
        .latched_nanoseconds(latched_nanoseconds)
    );

    // Reference clock: 125 MHz
    initial begin
        clk = 0;
        forever #0.4 clk = ~clk;
    end

    // 1pps input
    initial begin
        pps_in = 0;
        #2000;
        pps_in = 1;
        forever begin
            #50000; pps_in = 0;
            #150000; pps_in = 1;
        end 
    end

    initial begin
        rst_n = 0;
        #1000;
        rst_n = 1;
        #4005000;
        $finish;
    end

    initial begin
        $dumpfile("tod_tb.vcd");
        $dumpvars(0, tod_tb);
    end

endmodule