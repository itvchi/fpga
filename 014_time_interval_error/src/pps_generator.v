module pulse_stretching #(
    CLK = 27000000
) (
    input clk,
    input pulse_in,
    output reg pulse_out
);

    localparam integer STRETCH = 1 << $clog2(CLK / 10); // ~= CLK/10 rounded to next power-of-two
    localparam integer WIDTH = $clog2(STRETCH); // Counter width

    reg [WIDTH-1:0] counter = 0;

    always @(posedge clk) begin
        pulse_out <= 1'b0;
        
        if (pulse_in) begin
            counter <= STRETCH - 1;
            pulse_out <= 1'b1;
        end else if (counter != 0) begin
            counter <= counter - 1;
            pulse_out <= 1'b1;
        end
    end

endmodule