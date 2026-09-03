`timescale 1ns / 100ps
`include "signal_shifter.v"

module signal_shifter_tb;

    localparam CLOCK_COUNT = 5;
    localparam CLOCK_PERIOD = 100;
    localparam CLOCK_PERIOD_HALF = CLOCK_PERIOD/2;
    localparam CLOCK_PHASE_SHIFT = CLOCK_PERIOD/CLOCK_COUNT;

    reg rst_n;  
    reg [CLOCK_COUNT-1:0] clk;
    reg signal;
    reg [3:0] shift;
    wire shifted;

    genvar g;
    generate
        for (g = 0; g < CLOCK_COUNT; g = g + 1) begin
            initial begin
                clk[g] = 0;
                #(CLOCK_PHASE_SHIFT*g);
                forever begin
                    #(CLOCK_PERIOD_HALF); clk[g] = ~clk[g];
                end 
            end
        end
    endgenerate

    task do_test;
        input [7:0] _shift;
        begin
            shift <= _shift;
            #100;
            signal <= 1'b1;
            #(20*CLOCK_PERIOD);
            signal <= 1'b0;
            #(50*CLOCK_PERIOD);
        end
    endtask

    integer i;
    initial begin
        rst_n = 1'b0;
        signal <= 1'b0;
        shift <= 4'b0000;
        #1000;
        rst_n = 1'b1;
        #345;
        for (i = 0; i < 16; i = i + 1) begin
            do_test(i);
        end
        #1000;
        $finish;
    end

    time t_a;
    time edge_delay;

    always @(posedge signal)
        t_a = $time;

    always @(posedge shifted)
        edge_delay = ($time - t_a)/CLOCK_PHASE_SHIFT;

    signal_shifter #(
        .CLOCK_COUNT(CLOCK_COUNT)
    ) UUT (
        .rst_n(rst_n),
        .clk(clk),
        .signal(signal),
        .shift(shift),
        .shifted(shifted)
    );

    initial begin
        $dumpfile("signal_shifter_tb.vcd");
        $dumpvars(0, signal_shifter_tb);
    end

endmodule