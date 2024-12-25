`timescale 1ns / 100ps

module systick_tb ();

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
    wire irq;

    /* DUT instantiation */
    systick timer (
        .clk(clk),
        .reset_n(reset_n),
        .select(select),
        .wstrb(wstrb),
        .addr(addr[3:0]),
        .data_i(wdata),
        .ready(ready),
        .data_o(rdata),
        .irq(irq));

    /* Generate clock signal */
    initial begin
        clk = 1'b0;
        forever #1 clk = ~clk;
    end

    /* Generate reset signal */
    initial begin
        addr <= 32'd0;
        wdata <= 32'd0;
        enable = 1'b0;
        reset_n = 1'b0;
        #10
        reset_n = 1'b1;
    end

    assign select = (addr >= 32'h80000100) && (addr < 32'h80000110) && enable;

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
        $dumpfile("systick_tb.vcd");
        $dumpvars(0, systick_tb);
        #20
        write(32'h80000108, 32'd32);
        #20
        read(32'h80000108);
        #20
        write(32'h80000100, 32'h00020002); /* prescaler = 2 & enable_bit */
        read(32'h80000104);
        #20
        read(32'h80000100);
        #20
        read(32'h80000104);
        #50
        read(32'h80000104);
        #50
        read(32'h80000104);
        #50
        read(32'h80000104);
        #50
        read(32'h80000104);
        #20
        write(32'h80000100, 32'h00020006); /* prescaler = 2, irq & enable_bit */
        read(32'h80000104);
        #20
        read(32'h80000100);
        #20
        read(32'h80000104);
        #50
        read(32'h80000104);
        #50
        read(32'h80000104);
        #50
        read(32'h80000104);
        #50
        read(32'h80000104);

        #100
        $finish();
    end

endmodule