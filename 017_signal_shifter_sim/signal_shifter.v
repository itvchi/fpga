module signal_shifter #(
    parameter CLOCK_COUNT = 5
) (
    input rst_n,
    input [CLOCK_COUNT-1:0] clk,
    input signal,
    input [3:0] shift,
    input [9:0] length,
    output reg shifted,
    output reg shifted_stretched
);

    generate
        if (CLOCK_COUNT < 2 || CLOCK_COUNT > 5) begin: INVALID_CLOCK_COUNT
            INVALID_PARAMETER_VALUE invalid_parameter_value();
        end
    endgenerate

    reg [CLOCK_COUNT-1:0] prev_signal;
    reg [CLOCK_COUNT-1:0] edge_detected;
    reg [CLOCK_COUNT-1:0] signal_drive = 0;
    reg [CLOCK_COUNT-1:0] delay_pending = 0;
    reg [2:0] delay [0:CLOCK_COUNT-1];

    function integer previous_index;
        input integer g;
        input integer count;
        input integer offset;
        begin
            previous_index = (g + count - offset) % count;
        end
    endfunction

    genvar g;
    generate
        for (g = 0; g < CLOCK_COUNT; g = g + 1) begin
            wire signal_rising_edge = !prev_signal[g] && signal;
            wire edge_detected_previous_clock = edge_detected[previous_index(g, CLOCK_COUNT, 1)];

            always @(posedge clk[g]) begin
                /* Edge detected, but previous clock phase have not seen it yet 
                    - previously i checked if "edge_detected == 0", but this creates additional combinatorial logic that introduces signal delay
                        and with such low slack (as from clock phase to phase) we need to avoid combinatorial logic and routing delays so it is sufficient
                        to only check if previous clock saw rising edge */
                edge_detected[g] <= signal_rising_edge && !edge_detected_previous_clock;
                prev_signal[g] <= signal;
            end
		end
    endgenerate

    function integer circular_prev;
        input integer index;
        input integer count;
        input integer distance;
        integer value;
        begin
            circular_prev = (index + count - (distance % count)) % count;
            value = circular_prev;
        end
    endfunction

    localparam REG_WIDTH = $clog2(CLOCK_COUNT);

    reg [REG_WIDTH-1:0] phase_offset;
    reg [3:0] period_count; //assume reg size as "shift" reg for now

    always @(*) begin
        case (shift)
            4'd0: begin period_count = 0; phase_offset = 0; end
            4'd1: begin period_count = 0 / CLOCK_COUNT; phase_offset = (0 % CLOCK_COUNT) + 1; end
            4'd2: begin period_count = 1 / CLOCK_COUNT; phase_offset = (1 % CLOCK_COUNT) + 1; end
            4'd3: begin period_count = 2 / CLOCK_COUNT; phase_offset = (2 % CLOCK_COUNT) + 1; end
            4'd4: begin period_count = 3 / CLOCK_COUNT; phase_offset = (3 % CLOCK_COUNT) + 1; end
            4'd5: begin period_count = 4 / CLOCK_COUNT; phase_offset = (4 % CLOCK_COUNT) + 1; end
            4'd6: begin period_count = 5 / CLOCK_COUNT; phase_offset = (5 % CLOCK_COUNT) + 1; end
            4'd7: begin period_count = 6 / CLOCK_COUNT; phase_offset = (6 % CLOCK_COUNT) + 1; end
            4'd8: begin period_count = 7 / CLOCK_COUNT; phase_offset = (7 % CLOCK_COUNT) + 1; end
            4'd9: begin period_count = 8 / CLOCK_COUNT; phase_offset = (8 % CLOCK_COUNT) + 1; end
            4'd10: begin period_count = 9 / CLOCK_COUNT; phase_offset = (9 % CLOCK_COUNT) + 1; end
            4'd11: begin period_count = 10 / CLOCK_COUNT; phase_offset = (10 % CLOCK_COUNT) + 1; end
            4'd12: begin period_count = 11 / CLOCK_COUNT; phase_offset = (11 % CLOCK_COUNT) + 1; end
            4'd13: begin period_count = 12 / CLOCK_COUNT; phase_offset = (12 % CLOCK_COUNT) + 1; end
            4'd14: begin period_count = 13 / CLOCK_COUNT; phase_offset = (13 % CLOCK_COUNT) + 1; end
            4'd15: begin period_count = 14 / CLOCK_COUNT; phase_offset = (14 % CLOCK_COUNT) + 1; end

            default: begin period_count = 0; phase_offset = 0; end
        endcase
    end

    generate
        for (g = 0; g < CLOCK_COUNT; g = g + 1) begin
            always @(posedge clk[g]) begin
                if (period_count == 0) begin
                    if (edge_detected[circular_prev(g, CLOCK_COUNT, phase_offset)]) begin
                        signal_drive[g] <= 1'b1;
                    end else if (!signal) begin
                        signal_drive[g] <= 1'b0;
                    end
                end else begin
                    if (edge_detected[circular_prev(g, CLOCK_COUNT, phase_offset)]) begin
                        delay_pending[g] <= 1'b1;
                        delay[g] <= period_count - 1;
                    end
                    if (delay_pending[g] && delay[g]) begin
                        delay[g] <= delay[g] - 1'b1;
                    end else if (!signal) begin
                        signal_drive[g] <= 1'b0;
                    end else if (delay_pending[g]) begin
                        delay_pending[g] <= 1'b0;
                        signal_drive[g] <= 1'b1;
                    end
                end
            end
        end
    endgenerate

    always @(*) begin
        case (shift)
            3'b000: shifted = signal;
            default: shifted = |signal_drive;
        endcase
    end

    /* Signal length tuning */
    reg stretched;
    reg [9:0] stretch_length;
    reg prev_stretched;
    wire signal_rising_edge = !prev_signal[0] && signal;
    wire stretched_rising_edge = !prev_stretched && stretched;

    always @(posedge clk[0]) begin
        prev_stretched <= stretched;
    end

    always @(posedge clk[0]) begin
        if (!stretched && signal_rising_edge) begin
            stretched <= 1'b1;
            stretch_length <= length;
        end else if (stretched_rising_edge) begin
            stretch_length <= length;
        end else if (stretch_length) begin
            stretch_length <= stretch_length - 1'd1;
        end else begin
            stretched <= 1'b0;
        end
    end

    reg shifted_was_high;

    always @(posedge clk[0]) begin
        if (shifted) begin
            shifted_was_high <= 1'b1;
        end else if (!shifted_stretched) begin
            shifted_was_high <= 1'b0;
        end
    end

    always @(*) begin
        case (length)
            3'b000: shifted_stretched = shifted;
            default: shifted_stretched = (shifted || shifted_was_high) && stretched;
        endcase
    end

endmodule
