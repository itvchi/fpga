`timescale 1ns/1ps
`define TESTBENCH
`include "top.v"
`include "reset.v"
`include "sine_lut.v"
`include "pwm_dac.v"
`include "sigma_delta_dac.v"

module tb;

    reg clk = 0;
    wire pwm;
    wire sigma_delta;

    top dut (
        .clk(clk),
        .pwm(pwm),
        .sigma_delta(sigma_delta)
    );

    always #1 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);
        #5000000;
        $finish;
    end

endmodule