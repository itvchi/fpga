`timescale 1ns / 100ps

module spiflash_reader_tb;

    /* Input signals */
    reg clk;
    reg reset_n;
    reg [23:0] addr;
    reg start;

    /* Output signals */
    wire [7:0] data_o;
    wire data_valid;
    wire busy;

    /* UUT instantiation */
    spiflash_reader UUT (
        .clk(clk),
        .reset_n(reset_n),
        .addr(addr),
        .start(start),
        .data_o(data_o),
        .data_valid(data_valid),
        .busy(busy));

    /* Generate clock signal */
    initial begin
        clk = 1'b0;
        forever #1 clk = ~clk;
    end

    /* Generate reset signal */
    initial begin
        clk <= 1'b0;
        reset_n <= 1'b0;
        addr <= 24'b0;
        start <= 1'b0;
        #5
        reset_n = 1'b1;
    end

    reg [7:0] rdata;
	integer errcount = 0;

    task expect;
        input [7:0] data;
        begin
            if (data !== data_o) begin
                $display("ERROR: Got %x (%b) but expected %x (%b).", data_o, data_o, data, data);
                errcount = errcount + 1;
            end
        end
    endtask

    task read_address;
		input [23:0] address;
		begin

            #10
            if (busy) begin
                @(negedge busy); /* Wait until reset done */
            end
            addr <= address;
            start <= 1'b1;
            #10
            start <= 1'b0;

            @(negedge busy);
            #20

			$display("--  SPI read %06x: %02x", address, data_o);
		end
	endtask 

    /* Test */
    initial begin
        $dumpfile("spiflash_reader_tb.vcd");
        $dumpvars(0, spiflash_reader_tb);

        read_address(24'h010208); expect(8'h08);
        read_address(24'h010209); expect(8'h02);
        read_address(24'h01020A); expect(8'h01);

        #5;
		if (errcount) begin
			$display("FAIL");
			$stop;
		end else begin
			$display("PASS");
		end

        $finish();
    end

endmodule