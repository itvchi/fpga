module top (
    input clk,
    output pps,
    output slow_clk);

wire pll_clk;
wire pll_clk_90;

Gowin_rPLL pll(
    .clkout(pll_clk),
    .clkoutp(pll_clk_90),
    .clkin(clk));

reg enable = 0;
reg [26:0] enable_counter = 0;

reg [4:0] one_sec_periods = 0;
reg [3:0] one_sec_100n = 0;
reg [6:0] one_sec_micros = 0;
reg [6:0] one_sec_100us = 0;
reg [6:0] one_sec_10ms = 0;

always @(posedge pll_clk) begin
    if (one_sec_periods == 25) begin
        one_sec_periods <= 5'd0;
        one_sec_100n <= one_sec_100n + 4'd1;
    end else begin
        one_sec_periods <= one_sec_periods + 5'd1;
    end

    if (one_sec_100n == 10) begin
        one_sec_100n <= 4'd0;
        one_sec_micros <= one_sec_micros + 7'd1;
    end

    if (one_sec_micros == 100) begin
        one_sec_micros <= 7'd0;
        one_sec_100us <= one_sec_100us + 7'd1;
    end

    if (one_sec_100us == 100) begin
        one_sec_100us <= 7'd0;
        one_sec_10ms <= one_sec_10ms + 10'd1;
    end

    if (one_sec_10ms == 100) begin
        one_sec_10ms <= 7'd0;
        enable <= 1'b1;
    end

    if (enable) begin
        if (one_sec_100us >= 10) begin
            enable <= 1'b0;
        end
    end
end

assign pps = enable;

reg [7:0] slow_counter;

always @(posedge clk) begin
    slow_counter <= slow_counter + 8'd1;
end

assign slow_clk = slow_counter[7];

endmodule