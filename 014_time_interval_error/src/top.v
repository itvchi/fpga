module top (
    input clk,
    output pps_ref,
    output pps_meas1,
    output pps_meas2,
    output pps_meas3
);

    wire pll_clk_fast; //81 MHz
    wire pll_clk_slow; //20.25 MHz

    Gowin_rPLL pll(
        .clkout(pll_clk_fast),
        .clkoutd(pll_clk_slow),
        .clkin(clk)
    );

    wire rst_n;

    reset global_reset (
        .clk(pll_clk_fast),
        .rst_n(rst_n)
    );

    // REFERENCE 1PPS
    wire ppsA;

    counter #(
        .VALUE(81000000)
    ) reference (
        .clk(pll_clk_fast),
        .clk_en(1'b1),
        .rst_n(rst_n),
        .pps(ppsA)
    );

    pulse_stretching #(
        .CLK(81000000)
    ) ps_ref (
        .clk(pll_clk_fast),
        .pulse_in(ppsA),
        .pulse_out(pps_ref)
    );

    // SLOWER
    wire ppsB;

    counter #(
        .VALUE(81000001)
    ) slower (
        .clk(pll_clk_fast),
        .clk_en(1'b1),
        .rst_n(rst_n),
        .pps(ppsB) //80 999 999.000 000 01 Hz (-0.999 999 09 Hz = -12.3 ppb)
    );

    pulse_stretching #(
        .CLK(81000000)
    ) ps_meas1 (
        .clk(pll_clk_fast),
        .pulse_in(ppsB),
        .pulse_out(pps_meas1)
    );

    // SLIGHTLY SLOWER
    wire clk_en_10_slow;
    wire ppsC;

    acc_counter #(
        .VALUE(530_242_876) //9 999 999.999 069 Hz (-0.000 931 = -0.093 ppb)
    ) acc_counter_10_slow (
        .clk_ref(pll_clk_fast),
        .rst_n(rst_n),
        .clk_en(clk_en_10_slow)
    );

    counter #(
        .VALUE(10000000)
    ) counter_10_slow (
        .clk(pll_clk_fast),
        .clk_en(clk_en_10_slow),
        .rst_n(rst_n),
        .pps(ppsC)
    );

    pulse_stretching #(
        .CLK(81000000)
    ) ps_meas2 (
        .clk(pll_clk_fast),
        .pulse_in(ppsC),
        .pulse_out(pps_meas2)
    );

    // SLIGHTLY FASTER
    wire clk_en_10_fast;
    wire ppsD;

    acc_counter #(
        .VALUE(530_242_877) // 10 000 000.018 Hz (+0.018 Hz = 1.8ppb)
    ) acc_counter_10_fast (
        .clk_ref(pll_clk_fast),
        .rst_n(rst_n),
        .clk_en(clk_en_10_fast)
    );

    counter #(
        .VALUE(10000000)
    ) counter_10_fast (
        .clk(pll_clk_fast),
        .clk_en(clk_en_10_fast),
        .rst_n(rst_n),
        .pps(ppsD)
    );

    pulse_stretching #(
        .CLK(81000000)
    ) ps_meas3 (
        .clk(pll_clk_fast),
        .pulse_in(ppsD),
        .pulse_out(pps_meas3)
    );

endmodule

/* Results
    PPS drift after 15min: 
    pps_meas1: 44.6us (12.4 ppb) 
    pps_meas2: 150ns (0.1 ppb)
    pps_meas3: 6.5us (1.8 ppb)

    Meas results (specially for pps_meas2 from clock with least error) are slightly of calculated values
    because pulse_stretching resulution is 12.3 ns and measurement was to short to achive good resolution
*/