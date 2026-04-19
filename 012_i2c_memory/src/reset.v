module reset(
    input clk,
    output reg n_rst
);

reg  [23:0] r_rst;

initial begin
    r_rst <= 24'd0;
end

always @(posedge clk) begin
    if (r_rst[23] == 1'b0) begin
        r_rst <= r_rst + 24'd1;
    end
    n_rst <= r_rst[23];
end

endmodule