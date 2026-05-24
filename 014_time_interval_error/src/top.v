module top (
    input clk,
    output pps_ref,
    output pps_meas1,
    output pps_meas2,
    output pps_meas3
);

    wire rst_n;

    reset global_reset (
        .clk(clk),
        .rst_n(rst_n)
    );

    // REFERENCE 1PPS
    wire ppsA;

    counter #(
        .VALUE(27000000)
    ) reference (
        .clk(clk),
        .clk_en(1'b1),
        .rst_n(rst_n),
        .pps(ppsA)
    );

    pulse_stretching #(
        .CLK(27000000)
    ) ps_ref (
        .clk(clk),
        .pulse_in(ppsA),
        .pulse_out(pps_ref)
    );

    // SLOWER
    wire ppsB;

    counter #(
        .VALUE(27000001)
    ) slower (
        .clk(clk),
        .clk_en(1'b1),
        .rst_n(rst_n),
        .pps(ppsB) //26 999 999.000 000 04 Hz (-0.999 999 06 Hz = -37 ppb)
    );

    pulse_stretching #(
        .CLK(27000000)
    ) ps_meas1 (
        .clk(clk),
        .pulse_in(ppsB),
        .pulse_out(pps_meas1)
    );

    // SLIGHTLY SLOWER
    wire clk_en_10_slow;
    wire ppsC;

    acc_counter #(
        .VALUE(1_590_728_628) //9 999 999.999 068 Hz (-0.000 932 Hz = −0.093 ppb)
    ) acc_counter_10_slow (
        .clk_ref(clk),
        .rst_n(rst_n),
        .clk_en(clk_en_10_slow)
    );

    counter #(
        .VALUE(10000000)
    ) counter_10_slow (
        .clk(clk),
        .clk_en(clk_en_10_slow),
        .rst_n(rst_n),
        .pps(ppsC)
    );

    pulse_stretching #(
        .CLK(27000000)
    ) ps_meas2 (
        .clk(clk),
        .pulse_in(ppsC),
        .pulse_out(pps_meas2)
    );

    // SLIGHTLY FASTER
    wire clk_en_10_fast;
    wire ppsD;

    acc_counter #(
        .VALUE(1_590_728_629) // 10 000 000.005 355 Hz (+0.005 355 Hz = 0.5355 ppb)
    ) acc_counter_10_fast (
        .clk_ref(clk),
        .rst_n(rst_n),
        .clk_en(clk_en_10_fast)
    );

    counter #(
        .VALUE(10000000)
    ) counter_10_fast (
        .clk(clk),
        .clk_en(clk_en_10_fast),
        .rst_n(rst_n),
        .pps(ppsD)
    );

    pulse_stretching #(
        .CLK(27000000)
    ) ps_meas3 (
        .clk(clk),
        .pulse_in(ppsD),
        .pulse_out(pps_meas3)
    );

endmodule

/* Results
    PPS drift after 15min: 
    pps_meas1: 34us (37.8 ppb)
    pps_meas2: 150ns (0.17 ppb)
    pps_meas3: 480ns (0.54 ppb)

    Meas results (specially for pps_meas2 from clock with least error) are slightly of calculated values
    because pulse_stretching resulution is 37 ns and measurement was to short to achive good resolution
*/