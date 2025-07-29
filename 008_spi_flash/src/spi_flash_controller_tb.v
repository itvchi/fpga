
`timescale 1ns / 100ps

module spi_flash_controller_tb();

reg clk;
reg rst_n;
reg [23:0] address;
reg [7:0] size;
reg valid;
wire ready;
wire spi_clk;
wire spi_mosi;
wire spi_cs;

spi_flash_controller UUT (
    .clk(clk),
    .rst_n(rst_n),
    .req_address(address),
    .req_size(size),
    .req_valid(valid),
    .req_ready(ready),
    .spi_cs(spi_cs),
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi));


/* Generate clock signal */
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

/* Generate reset signal */
initial begin
    address <= 24'd0;
    size <= 8'd0;
    valid <= 1'b0;
    rst_n <= 1'b0;
    #20
    rst_n = 1'b1;
end

initial begin
    $dumpfile("spi_flash_controller_tb.vcd");
    $dumpvars(0, spi_flash_controller_tb);
end

// Test Scenario
initial begin
    #100;
    address <= 24'HAABBCC;
    size <= 8'd1;
    valid <= 1'b1;
    while (!ready) begin
        @(posedge clk);
    end
    #10;
    valid <= 1'b0;
    #20000;
    $finish;
end

endmodule