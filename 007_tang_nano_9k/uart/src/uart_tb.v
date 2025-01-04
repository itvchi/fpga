`timescale 10ns/1ns
`include "clock_divider.v"
`include "uart.v"
`include "uart_rx.v"
`include "uart_tx.v"

module uart_tb();

reg clk;
reg rx;
wire tx;

uart #(
    .INPUT_CLOCK(25000000),
    .BAUD_RATE(10000))
UUT (
    .clk(clk),
    .rx(rx),
    .tx(tx));

always #2 clk = ~clk; /* 25MHz clock */

initial begin
    clk = 0;
    rx = 1'b1;

    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);
    #1000
    receive(8'b10110101);
    wait_transmit();
    #1000
    receive(8'h6F);
    wait_transmit();
    #1000
    $finish;
end

task receive;
    input [7:0] i_data;
    begin
        /* Start bit */
        rx <= 1'b0;
        #10000

        /* Data bits */
        for (integer i = 0; i < 8; i = i + 1) begin
			rx <= i_data[i];
            #10000;
		end

        /* Stop bit */
        rx <= 1'b1;
        #10000;
    end
endtask

task wait_transmit;
    begin
        #10000

        repeat (8)
            #10000
        
        #10000;
    end
endtask

endmodule