module packet_timer(
    input clk, /* 50MHz input clock */
    input rst_n,
    output packet_enable
);

localparam PACKET_TIMER_MAX = 50000000; //1s

reg [31:0] packet_timer;

always @(negedge clk) begin
    if (!rst_n) begin
`ifdef SIM
        packet_timer <= PACKET_TIMER_MAX - 40;
`else
        packet_timer <= 32'd0;
`endif
    end else begin
        if (packet_timer == PACKET_TIMER_MAX) begin
            packet_timer <= 32'd0;
        end else begin
            packet_timer <= packet_timer + 32'd1;
        end
    end
end

assign packet_enable = (packet_timer == PACKET_TIMER_MAX);

endmodule