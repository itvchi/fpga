`timescale 1ns / 100ps
`include "top.v"

module top_tb;

    reg clk_ref;
    reg rst_n;
    reg clk_meas;

    top uut (
        .clk_ref(clk_ref),
        .rst_n(rst_n),
        .clk_meas(clk_meas)
    );

    // Reference clock: 100 MHz
    initial begin
        clk_ref = 0;
        forever #5 clk_ref = ~clk_ref;
    end

    // Measured clock: 25 MHz
    initial begin
        clk_meas = 0;
        forever #207 clk_meas = ~clk_meas;
    end

    initial begin
        rst_n = 0;
        #1000;
        rst_n = 1;
        #1010000;
        $finish;
    end

    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);
    end

endmodule