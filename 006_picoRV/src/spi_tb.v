`timescale 1ns / 100ps

module spi_tb ();

    /* Clock and reset signals */
    reg clk;
    reg reset_n;

    reg [3:0] wstrb;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg enable;
    wire select;
    wire ready;
    wire [31:0] rdata;
    wire spi_cs;
    wire spi_clk;
    wire spi_mosi;

    localparam SPI_BASEADDR = 32'h80000300;

    /* DUT instantiation */
    spi DUT (
        .clk(clk),
        .reset_n(reset_n),
        .select(select),
        .wstrb(wstrb),
        .addr(addr[3:0]),
        .data_i(wdata),
        .ready(ready),
        .data_o(rdata),
        .spi_cs(spi_cs),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi));

    /* Generate clock signal */
    initial begin
        clk <= 1'b0;
        forever #1 clk <= ~clk;
    end

    /* Generate reset signal */
    initial begin
        addr <= 32'd0;
        wdata <= 32'd0;
        enable <= 1'b0;
        reset_n <= 1'b0;
        #10
        reset_n <= 1'b1;
    end

    assign select = (addr >= SPI_BASEADDR) && (addr < (SPI_BASEADDR + 32'h10)) && enable;

    task write;
        input [31:0] i_addr, i_data; 
        begin
            @(posedge clk);
            addr <= i_addr;
            wdata <= i_data;
            wstrb <= 4'b1111;
            enable <= 1'b1;
            @(posedge ready);
            enable <= 1'b0;
        end
    endtask

    task read;
        input [31:0] i_addr; 
        begin
            @(posedge clk);
            addr <= i_addr;
            wstrb <= 4'd0;
            enable <= 1'b1;
            @(posedge ready);
            enable <= 1'b0;
        end
    endtask

    /* Test */
    initial begin
        $dumpfile("spi_tb.vcd");
        $dumpvars(0, spi_tb);
        #20
        write(SPI_BASEADDR, 32'h00000001); /* reset */
        #20
        write(SPI_BASEADDR, 32'h00000002); /* enable */
        #20
        write(SPI_BASEADDR + 32'h0C, {24'd0, 8'h10}); /* send 0x10 */
        #600
        write(SPI_BASEADDR + 32'h0C, {24'd0, 8'h20}); /* send 0x20 */
        #600
        #600

        $finish();
    end

endmodule