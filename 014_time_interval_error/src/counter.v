module counter #(
    VALUE = 1000
) (
    input clk,
    input clk_en,
    input rst_n,
    output reg pps
);

    localparam integer WIDTH = $clog2(VALUE);

    reg [WIDTH-1:0] counter = 0;

    always @(posedge clk) begin
        pps <= 1'b0;

        if (!rst_n) begin
            counter <= 0;
        end else if (clk_en) begin
            if (counter == VALUE - 1) begin
                counter <= 0;
                pps <= 1'b1;
            end else begin
                counter = counter + 1;
            end
        end
    end

endmodule