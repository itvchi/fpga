`timescale 1ns / 100ps

module uart_tb ();

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
    wire rx_tx_loopback;

    /* DUT instantiation */
    uart DUT (
        .clk(clk),
        .reset_n(reset_n),
        .select(select),
        .wstrb(wstrb),
        .addr(addr[4:0]),
        .data_i(wdata),
        .ready(ready),
        .data_o(rdata),
        .rx(1'b0),
        .tx(rx_tx_loopback));

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

    assign select = (addr >= 32'h80000200) && (addr < 32'h80000220) && enable;

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
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
        
        reset_n <= 1'b0;
        #100
        reset_n <= 1'b1;
        #5
        write(32'h80000200, 32'h00000002); /* reset */
        #5
        write(32'h80000204, 32'd10); /* configure baud_prescaler */
        #5
        read(32'h80000204);
        #5
        write(32'h80000200, 32'h00000002); /* enable */
        #20
        write(32'h80000210, {24'd0, "a"}); /* tx_data = "a" */
        #600
        write(32'h80000210, {24'd0, "e"}); /* tx_data = "a" */
        #600

        reset_n <= 1'b0;
        #100
        reset_n <= 1'b1;
        #5
        write(32'h80000200, 32'h00000002); /* reset */
        #5
        write(32'h80000204, 32'd10); /* configure baud_prescaler */
        #5
        read(32'h80000204);
        #5
        write(32'h80000200, 32'h00000002); /* enable */
        #20
        write(32'h80000210, {24'd0, "a"}); /* tx_data = "a" */
        #600
        write(32'h80000210, {24'd0, "e"}); /* tx_data = "a" */
        #600

        reset_n <= 1'b0;
        #100
        reset_n <= 1'b1;
        #5
        write(32'h80000200, 32'h00000002); /* reset */
        #5
        write(32'h80000204, 32'd10); /* configure baud_prescaler */
        #5
        read(32'h80000204);
        #5
        write(32'h80000200, 32'h00000002); /* enable */
        #20
        write(32'h80000210, {24'd0, "a"}); /* tx_data = "a" */
        #600
        write(32'h80000210, {24'd0, "e"}); /* tx_data = "a" */
        #600

        $finish();
    end

endmodule