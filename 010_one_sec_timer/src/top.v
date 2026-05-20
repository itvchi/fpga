module top (
    input clk,
    output pps,
    output slow_clk);

wire pll_clk;
wire pll_clk180;

Gowin_rPLL pll(
    .clkout(pll_clk),
    .clkoutp(pll_clk180),
    .clkin(clk));

reg enable = 0;
reg [27:0] ns_counter = 0;  // 0..249_999_999 (4ns step)
reg [31:0] one_sec = 0;

reg ns_top_r = 0;  // pre-registered slow bits
reg wrap_ns_r = 0;

always @(posedge pll_clk) begin

    ns_top_r <= (ns_counter[27:4] == 24'hEE6B27);  // slow upper bits (of 249_999_999) — registered early
    wrap_ns_r <= ns_top_r && (ns_counter[3:0] == 4'hF); // fast lower bits only in final compare
    // @up: ns_top_r arrive time can be greater then clock period, but it have to be valid before "ns_counter[3:0] == 4'hF"

    ns_counter <= wrap_ns_r ? 28'd0 : ns_counter + 28'd1;

    if (wrap_ns_r) begin
        one_sec <= one_sec + 32'd1;
        enable <= 1'b1;
    end

    if (enable) begin
        enable <= 1'b0;
    end
end

// Generate half period of precision (2ns @ pll_clk 250MHz)
reg main_tick, fine_tick;

always @(posedge pll_clk)    main_tick <= ~main_tick;
always @(posedge pll_clk180) fine_tick <= ~fine_tick;

assign fine_step = main_tick ^ fine_tick;

reg [29:0] latched_time;

always @(posedge pll_clk) begin
    if (enable) begin //enable only for keep during synthesis, but should be triggered by latch_req (no driver in this example)
        latched_time <= {ns_counter, fine_step, 1'b0};
    end
end

// Generate slow clock
reg [7:0] slow_counter;

always @(posedge clk) begin
    slow_counter <= slow_counter + 8'd1;
end

// Assign outputs
assign pps = enable & !fine_step; //!fine_step only for keep during synthesis
assign slow_clk = slow_counter[7];

endmodule