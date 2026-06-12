module tod #(
    parameter CLK_FREQ = 125_000_000
) (
    input clk,
    input rst_n,
    input pps_in,
    input [31:0] freq_adj,
    input freq_update,
    input [31:0] phase_offset,
    input phase_update,
    output reg pps_out,
    output reg [31:0] latched_seconds,
    output reg [31:0] latched_nanoseconds);

    /* Control signal CDC */
    reg [31:0] freq_adj_local;
    reg [31:0] phase_offset_local;
    reg freq_update_meta, freq_update_stable, freq_update_prev;
    reg phase_update_meta, phase_update_stable, phase_update_prev;
    reg do_freq_update;
    reg do_phase_update;
    reg phase_update_done;

    always @(posedge clk) begin
        if (!rst_n) begin
            freq_adj_local <= 32'd0;
            {freq_update_meta, freq_update_stable, freq_update_prev} <= 3'b000;
            do_freq_update <= 1'b0;
        end else begin
            {freq_update_meta, freq_update_stable, freq_update_prev} <= {freq_update, freq_update_meta, freq_update_stable};

            /* Detect update event and perform update outside regulation region */
            if ({freq_update_prev, freq_update_stable} == 2'b01) begin
                do_freq_update <= 1'b1;
            end
            if (do_freq_update && !ns_half_top_r) begin
                do_freq_update <= 1'b0;
                freq_adj_local <= freq_adj;
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            phase_offset_local <= 32'd0;
            {phase_update_meta, phase_update_stable, phase_update_prev} <= 3'b000;
            do_phase_update <= 1'b0;
        end else begin
            {phase_update_meta, phase_update_stable, phase_update_prev} <= {phase_update, phase_update_meta, phase_update_stable};

            /* Detect update event and perform update outside regulation region */
            if ({phase_update_prev, phase_update_stable} == 2'b01) begin
                do_phase_update <= 1'b1;
            end
            if (do_phase_update && !ns_half_top_r && !phase_update_done) begin
                do_phase_update <= 1'b0;
                phase_offset_local <= phase_offset;
            end else if (phase_update_done) begin
                phase_offset_local <= 32'd0;
            end
        end
    end

    reg [26:0] ns_counter;      // 0..124_999_999 (8ns step)
    reg [26:0] next_ns_counter;
    reg [31:0] one_sec;

    reg ns_top_r;  // pre-registered slow bits
    // reg wrap_ns_r;
    reg ns_half_top_r;  // pre-registered slow bits
    // reg wrap_half_ns_r;
    reg adj_prepared;
    reg adj_done;

    localparam COUNTER_HALF = CLK_FREQ/2;
    localparam COUNTER_HALF_TOP = (COUNTER_HALF - 1) >> 4;
    localparam COUNTER_HALF_BOTTOM = (COUNTER_HALF - 1) & 4'hF;
    localparam COUNTER_TOP = (CLK_FREQ - 1) >> 4;
    localparam COUNTER_BOTTOM = (CLK_FREQ - 1) & 4'hF;

    /* Used combinatorial logic, to have signal valid before next edge after the condition is valid */
    assign wrap_ns_r = ns_top_r && (ns_counter[3:0] == COUNTER_BOTTOM);
    assign wrap_half_ns_r = ns_half_top_r && (ns_counter[3:0] == COUNTER_HALF_BOTTOM);

    always @(posedge clk) begin
        if (!rst_n) begin
            ns_counter <= 27'd0;
            one_sec <= 32'd0;
            pps_out <= 1'b0;
            ns_top_r <= 1'b0;
            
            adj_prepared <= 1'b0;
            adj_done <= 1'b0;
            phase_update_done <= 1'd0;
        end else begin
            ns_half_top_r <= (ns_counter[26:4] == COUNTER_HALF_TOP);  // slow upper bits (of 62_499_999) — registered early
            ns_top_r <= (ns_counter[26:4] == COUNTER_TOP);  // slow upper bits (of 124_999_999) — registered early

            phase_update_done <= 1'b0;

            if (ns_half_top_r && !adj_prepared) begin
                adj_prepared <= 1'b1;
                phase_update_done <= 1'b1;
                next_ns_counter <= COUNTER_HALF +
                    (freq_adj_local[31] ? -freq_adj_local[23:0] : +{freq_adj_local[23:0], 3'b000}) +
                    (phase_offset_local[31] ? -phase_offset_local[23:0] : +phase_offset_local[23:0]);
            end

            if (wrap_ns_r) begin
                ns_counter <= 27'd0; 
            end else if (wrap_half_ns_r && !adj_done) begin
                adj_done <= 1'b1;
                ns_counter <= next_ns_counter;
            end else begin
                ns_counter <= ns_counter + 27'd1;
            end

            if (wrap_ns_r) begin
                adj_prepared <= 1'b0;
                adj_done <= 1'b0;
                one_sec <= one_sec + 32'd1;
                pps_out <= 1'b1;
            end

            if (pps_out && ns_counter[10] == 1) begin
                pps_out <= 1'b0; /* Deassert after 1024 clk period */
            end
        end
    end

    reg pps_meta, pps_stable, pps_prev;

    always @(posedge clk) begin
        if (!rst_n) begin
            {pps_meta, pps_stable, pps_prev} <= 3'b000;
        end else begin
            {pps_meta, pps_stable, pps_prev} <= {pps_in, pps_meta, pps_stable};
        end 
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            latched_seconds <= 31'd0;
            latched_nanoseconds <= 31'd0;
        end else if ({pps_prev, pps_stable} == 2'b01) begin
            latched_seconds <= one_sec;
            latched_nanoseconds <= {ns_counter, 3'd0};
        end
    end

endmodule