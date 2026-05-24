module top(
    input clk,
    output pwm,
    output sigma_delta
);

    wire pll_clk;
    wire rst_n;

`ifdef TESTBENCH
    assign pll_clk = clk;
`else
    Gowin_rPLL pll(
        .clkout(pll_clk),
        .clkin(clk)
    );
`endif

    reset global_reset (
        .clk(pll_clk),
        .rst_n(rst_n)
    );

    reg [8:0] addr;
    wire [9:0] value;
    wire loaded;
    wire data_ready;

    /* Achieving of value from LUT can be pipelined, because loaded signal that triggers this
        is asserted once per PWM_DAC period and at currently calculated value is copied to local register */ 
    sine_lut sine(
        .clk(pll_clk),
        .clk_en(loaded),
        .addr(addr),
        .value(value),
        .data_ready(data_ready)
    );

    always @(posedge pll_clk) begin
        if (!rst_n) begin
            addr <= 8'd0;
        end else if (loaded) begin
            addr <= addr + 8'd1;
        end
    end

    pwm_dac pwm_dac_inst(
        .clk(pll_clk),
        .rst_n(rst_n),
        .value(value),
        .out(pwm),
        .loaded(loaded)
    );

    sigma_delta_dac sigma_delta_dac_inst(
        .clk(clk),
        .rst_n(rst_n),
        .load(data_ready),
        .value(value),
        .out(sigma_delta)
    );

endmodule