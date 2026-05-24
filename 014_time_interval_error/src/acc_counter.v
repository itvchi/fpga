module acc_counter #(
    VALUE = 1000
) (
    input clk_ref,
    input rst_n,
    output clk_en
);

    reg [32:0] accumulator = 0;

    always @(posedge clk_ref) begin
        if (!rst_n) begin
            accumulator <= 33'd0;
        end else begin
            accumulator <= accumulator[31:0] + VALUE;
        end
    end

    assign clk_en = accumulator[32];

endmodule