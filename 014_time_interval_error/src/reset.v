module reset (
    input clk,
    output rst_n
);

reg [15:0] counter = 0;

always @(posedge clk) begin
    if (!rst_n) begin
        counter <= counter + 16'd1;
    end
end

assign rst_n = counter[15];

endmodule