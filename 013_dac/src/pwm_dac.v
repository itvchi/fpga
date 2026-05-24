module pwm_dac(
    input clk,
    input rst_n,
    input [9:0] value,
    output reg out,
    output reg loaded
);

    reg [9:0] counter;
    reg [9:0] loaded_value;

    // Out driver
    always @(posedge clk) begin
        if (!rst_n) begin
            out <= 1'b0;
        end else begin
            case (1'b1)
                (counter == loaded_value): out <= 1'b0;
                (counter == 10'd0):        out <= 1'b1;
                default:                   out <= out;
            endcase
        end
    end

    // Counter
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 10'd0;
        end else begin
            counter <= counter + 10'd1;
        end
    end

    // Value loading
    always @(posedge clk) begin
        if (!rst_n) begin
            loaded <= 1'b0;
            loaded_value <= 10'd0;;
        end else if (counter == 10'h3FF) begin
            loaded <= 1'b1;
            loaded_value <= value;
        end else begin
            loaded <= 1'b0;
        end
    end

endmodule