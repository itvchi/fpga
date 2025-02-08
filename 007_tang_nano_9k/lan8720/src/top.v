module top (
    input clk,
    input rst_btn_n,
    output reg led);

wire rst_n;
wire packet_enable;

eth_rst_gen reset_gen (
    .clk(clk),
    .rst_btn_n(rst_btn_n),
    .rst_n(rst_n)
);

packet_timer timer(
    .clk(clk),
    .rst_n(rst_n),
    .packet_enable(packet_enable)
);

always @(posedge clk) begin
    if (!rst_n) begin
        led <= 1'b1;
    end else if(packet_enable) begin
        led <= ~led;
    end
end

endmodule