// ============================================================
//  Time-of-Day with freq and phase correction
//
//  Key idea: 64-bit fixed-point phase accumulator.
//    bits [63 : FRAC_BITS]   = integer nanoseconds
//    bits [FRAC_BITS-1 : 0]  = sub-nanosecond fraction
//
//  BASE_INC = 2^FRAC_BITS * (1 / CLK_PERIOD_NS)
//           = 2^FRAC_BITS / 8   for 125 MHz (8 ns/clk)
//
//  freq_adj: signed 32-bit, units = 2^-(FRAC_BITS) ns per cycle
//            (i.e. directly added to the increment every cycle)
//            Positive -> speed up, negative -> slow down.
//
//  phase_adj: signed 32-bit, units = 1 ns (applied once per request)
// ============================================================

module tod_nco #(
    parameter CLK_FREQ = 125_000_000,
    parameter FRAC_BITS = 16 // sub-ns resolution bits (1 ns = 65536 counts)
) (
    input clk,
    input rst_n,
    input pps_in,

    // Frequency trim: signed, units = (2^-FRAC_BITS) ns / cycle
    input signed [31:0] freq_adj,
    input freq_update,

    // Phase step: signed nanoseconds
    input signed [31:0] phase_adj,
    input phase_update,

    output reg pps_out,
    output reg [31:0] latched_seconds,
    output reg [31:0] latched_nanoseconds
);

    // --------------------------------------------------------
    //  Constants
    // --------------------------------------------------------
    localparam integer ONE_SEC_NS = 1_000_000_000;

    // Full 64-bit threshold for 1s wrap (accumulator wraps when it reaches: 1e9 << FRAC_BITS)
    localparam [63:0] ACC_ONE_SEC = 64'd1_000_000_000 * (64'd1 << FRAC_BITS);

    // Base increment: 8 ns per cycle for 125 MHz, scaled by 2^FRAC_BITS = (1_000_000_000 / CLK_FREQ) << FRAC_BITS
    // For 125 MHz: (8 * 65536) = 524288
    localparam [63:0] BASE_INC = 64'd1_000_000_000 * (64'd1 << FRAC_BITS) / CLK_FREQ;

    // --------------------------------------------------------
    //  Frequency adjustment synchronizer
    // --------------------------------------------------------
    reg [1:0] freq_sync;
    reg [31:0] freq_adj_s;
    wire freq_sync_rising = (freq_sync == 2'b01);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            freq_sync <= 2'b00;
            freq_adj_s <= 32'd0;
        end else begin
            freq_sync <= {freq_sync[0],  freq_update};

            if (freq_sync_rising) begin
                freq_adj_s <= freq_adj;
            end 
        end
    end

    // --------------------------------------------------------
    //  Phase adjustment synchronizer (One-shot phase correction)
    // --------------------------------------------------------
    reg [1:0] phase_sync;
    reg signed [31:0] phase_pending;
    reg phase_valid;
    wire phase_sync_rising = (phase_sync == 2'b01);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_sync <= 2'b00;
            phase_pending <= 32'd0;
            phase_valid <= 1'b0;
        end else begin
            phase_sync <= {phase_sync[0],  phase_update};
            phase_valid <= 1'b0;

            if (phase_sync_rising) begin
                phase_pending <= phase_adj;
                phase_valid <= 1'b1;
            end
        end
    end

    // --------------------------------------------------------
    //  Phase accumulator logic
    // --------------------------------------------------------
    reg [63:0] acc;
    reg [31:0] seconds;
    wire [29:0] nanoseconds = acc[FRAC_BITS + 29 : FRAC_BITS]; // Drop sub-ns fraction; MSBs of acc are integer nanoseconds

    // Current cycle increment = BASE_INC + freq_adj_s (sign-extended to 64 bits before add)
    // Result is always positive for any sane freq trim.
    wire [63:0] cycle_inc = BASE_INC + {{32{freq_adj_s[31]}}, freq_adj_s};

    // Scaled phase: nanoseconds → accumulator units
    wire [63:0] phase_scaled = {{32{phase_pending[31]}}, phase_pending} << FRAC_BITS;

    wire [64:0] next_acc_base = {1'b0, acc} + {1'b0, cycle_inc};
    wire [64:0] next_acc_inc = {{33{phase_pending[31]}}, phase_pending, {FRAC_BITS{1'b0}}};
    wire [64:0] next_acc = phase_valid ? next_acc_base + next_acc_inc : next_acc_base;

    wire wrap = (next_acc >= {1'b0, ACC_ONE_SEC});
    wire [63:0] next_acc_wrap = next_acc[63:0] - ACC_ONE_SEC;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 64'd0;
            seconds <= 32'd0;
            pps_out <= 1'b0;
        end else begin
            // ---- Core accumulator update -------------------------
            // Each cycle: acc += cycle_inc [ + phase_step once ]
            // phase_scaled is sign-extended, so subtraction works naturally via 2's complement addition.
            // Wrap detection: the previous acc + inc crosses ACC_ONE_SEC.
            // We do the add first, then subtract ACC_ONE_SEC if needed.

            // Wrap: subtract 1 second from accumulator, tick seconds counter
            if (wrap) begin
                acc <= next_acc_wrap;
                seconds <= seconds + 32'd1;
                pps_out <= 1'b1;
            end else begin
                acc <= next_acc[63:0];
            end

            if (pps_out && acc[FRAC_BITS + 10]) begin
                pps_out <= 1'b0; // Deassert PPS after ~1024 cycles
            end
        end
    end

    // --------------------------------------------------------
    //  pps_in CDC
    // --------------------------------------------------------
    reg pps_meta, pps_stable, pps_prev;
    wire pps_rising = ({pps_prev, pps_stable} == 2'b01);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {pps_meta, pps_stable, pps_prev} <= 3'b000;
        end else begin
            {pps_meta, pps_stable, pps_prev} <= {pps_in, pps_meta, pps_stable};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latched_seconds <= 32'd0;
            latched_nanoseconds <= 32'd0;
        end else if (pps_rising) begin
            latched_seconds <= seconds;
            latched_nanoseconds <= nanoseconds;
        end
    end

endmodule