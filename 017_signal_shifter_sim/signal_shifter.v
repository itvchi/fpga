module signal_shifter #(
    parameter CLOCK_COUNT = 5
) (
    input rst_n,
    input [CLOCK_COUNT-1:0] clk,
    input signal,
    input [3:0] shift,
    output reg shifted
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
    generate
        for (g = 0; g < CLOCK_COUNT; g = g + 1) begin
            always @(posedge clk[g]) begin
                case (shift)
                    4'd1: begin
                        if (edge_detected[(g + 4) % 5]) begin /* edge detected clock phase before */
                            signal_drive[g] <= 1'b1;
                        end else if (!signal) begin
                            signal_drive[g] <= 1'b0;
                        end
                    end
                    4'd2: begin
                        if (edge_detected[(g + 3) % 5]) begin /* edge detected 2 clock phases before */
                            signal_drive[g] <= 1'b1;
                        end else if (!signal) begin
                            signal_drive[g] <= 1'b0;
                        end
                    end
                    4'd3: begin
                        if (edge_detected[(g + 2) % 5]) begin /* edge detected 3 clock phases before */
                            signal_drive[g] <= 1'b1;
                        end else if (!signal) begin
                            signal_drive[g] <= 1'b0;
                        end
                    end
                    4'd4: begin
                        if (edge_detected[(g + 1) % 5]) begin /* edge detected 4 clock phases before */
                            signal_drive[g] <= 1'b1;
                        end else if (!signal) begin
                            signal_drive[g] <= 1'b0;
                        end
                    end
                    4'd5: begin
                        if (edge_detected[g]) begin /* edge detected 5 clock phases before - self edge detector, one period later */
                            signal_drive[g] <= 1'b1;
                        end else if (!signal) begin
                            signal_drive[g] <= 1'b0;
                        end
                    end
                    4'd6: begin
                        if (edge_detected[(g + 4) % 5]) begin /* edge detected 6 clock phases before */
                            /* "delay[g]" is set to 0, because "delay_pending[g]" was set to 1 and it provides one period delay 
                                which was intended - so incrementing "delay[g]" will extends the delay by another periods of clock */
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd0;
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
                    4'd7: begin
                        if (edge_detected[(g + 3) % 5]) begin
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd0;
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
                    4'd8: begin
                        if (edge_detected[(g + 2) % 5]) begin
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd0;
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
                    4'd9: begin
                        if (edge_detected[(g + 1) % 5]) begin
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd0;
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
                    4'd10: begin
                        if (edge_detected[g]) begin
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd0;
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
                    4'd11: begin
                        if (edge_detected[(g + 4) % 5]) begin
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd1;
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
                    4'd12: begin
                        if (edge_detected[(g + 3) % 5]) begin
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd1;
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
                    4'd13: begin
                        if (edge_detected[(g + 2) % 5]) begin
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd1;
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
                    4'd14: begin
                        if (edge_detected[(g + 1) % 5]) begin
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd1;
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
                    4'd15: begin
                        if (edge_detected[g]) begin
                            delay_pending[g] <= 1'b1;
                            delay[g] <= 3'd1;
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
                endcase
            end
		end
    endgenerate

    always @(*) begin
        case (shift)
            3'b000: shifted = signal;
            default: shifted = |signal_drive;
        endcase
    end

endmodule
