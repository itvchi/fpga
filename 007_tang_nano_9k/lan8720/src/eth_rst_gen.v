module eth_rst_gen(
    input clk, /* 50MHz input clock */
    input rst_btn_n,
    output reg rst_n);

`ifdef SIM
localparam WAIT_CYCLES_50M = 200; //4us
`else
localparam WAIT_CYCLES_50M = 2000000; //40ms
`endif

reg [31:0] wait_counter_50M;

always @(negedge clk) begin
    if (!rst_btn_n) begin
        rst_n <= 1'b0;
        wait_counter_50M <= 1'b0;
    end else begin
        if (wait_counter_50M < (WAIT_CYCLES_50M - 1)) begin
            rst_n <= 1'b0;
            wait_counter_50M <= wait_counter_50M + 32'd1;
        end else begin
            rst_n <= 1'b1;
        end
    end
end

endmodule