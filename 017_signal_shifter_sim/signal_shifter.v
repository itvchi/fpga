module signal_shifter (
    input rst_n,
    input [4:0] clk,
    input signal,
    input [3:0] shift,
    output reg shifted
);

    reg [4:0] prev_signal;
    reg [4:0] edge_detected;
    reg [4:0] signal_drive = 0;
    reg [4:0] delay_pending = 0;
    reg [2:0] delay [0:4];

    genvar g;
    generate
        for (g = 0; g < 5; g = g + 1) begin
            always @(posedge clk[g]) begin
                /* Edge detected, but previous clock phase have not seen it yet 
                    - previously i checked if "edge_detected == 0", but this creates additional combinatorial logic that introduces signal delay
                        and with such low slack (as from clock phase to phase) we need to avoid combinatorial logic and routing delays */
                if (!prev_signal[g] && signal && !edge_detected[(g + 4) % 5]) begin 
                    edge_detected[g] <= 1'b1;
                end else begin
                    edge_detected[g] <= 1'b0;
                end

                prev_signal[g] <= signal;
            end
		end
    endgenerate
    generate
        for (g = 0; g < 5; g = g + 1) begin
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
