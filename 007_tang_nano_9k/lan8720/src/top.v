module top (
    input clk,
    input rst_btn_n,
    output [1:0] eth_txd,
    output eth_txen,
    inout [2:0] eth_rxd,
    input eth_rxerr,
    inout eth_crsdv,
    output reg led);

/* Boot Mode config (mode 111) */
assign eth_crsdv  = (!rst_n) ? 1 : 1'bz;
assign eth_rxd[0] = (!rst_n) ? 1 : 1'bz;
assign eth_rxd[1] = (!rst_n) ? 1 : 1'bz;

wire rst_n;
wire packet_enable;
reg [31:0] packet_counter;

eth_rst_gen reset_gen (
    .clk(clk),
    .rst_btn_n(rst_btn_n),
    .rst_n(rst_n)
);

packet_timer timer(
    .clk(clk),
    .rst_n(rst_n),
    .packet_enable(packet_enable));

always @(negedge clk) begin
    if (!rst_n) begin
        packet_counter <= 32'd0;
    end else begin
        if(packet_enable) begin
            packet_counter <= packet_counter + 32'd1;
        end
    end
end

packet_generator #(
    .MII_WIDTH(2)
) pg (
    .clk(clk),
    .rst_n(rst_n),
    .start(packet_enable),
    .data(packet_counter),
    .tx(eth_txd),
    .tx_en(eth_txen));

/* Blink led on packet */
always @(negedge clk) begin
    if (!rst_n) begin
        led <= 1'b1;
    end else begin
        if(packet_enable) begin
            led <= ~led;
        end
    end
end

endmodule