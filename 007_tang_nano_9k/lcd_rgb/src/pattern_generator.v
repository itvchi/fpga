module pattern_generator(
    input [1:0] pattern,
    input [9:0] pos_x,
    input [8:0] pos_y,
    output reg [7:0] red,
    output reg [7:0] green,
    output reg [7:0] blue);

localparam
PATTERN_RED = 2'd0,
PATTERN_GREEN_BLUE = 2'd1,
PATTERN_VERTICAL_STRIPES = 2'd2,
PATTERN_HORIZONTAL_STRIPES = 2'd3;

localparam
XY_DELTA = 480 - 272; /* Width of stripe for PATTERN_GREEN_BLUE */

always @(*) begin
    red = 8'd0;
    green = 8'd0;
    blue = 8'd0;

    case (pattern)
        PATTERN_RED: begin
            red = 8'hFF;
        end
        PATTERN_GREEN_BLUE: begin
            green = ((pos_x > pos_y) && (pos_x < (pos_y + XY_DELTA))) ? 8'hFF : 8'h00;
            blue = ((pos_x <= pos_y) || (pos_x >= (pos_y + XY_DELTA))) ? 8'hFF : 8'h00;
        end
        PATTERN_VERTICAL_STRIPES: begin
            if (pos_x < 160) begin
                red = 8'hFF;
            end else if (pos_x < 320) begin
                red = 8'h7F;
            end else begin
                red = 8'h3F;
            end

            if (pos_x < 40) begin
                green = 8'h0F;
            end else if (pos_x < 120) begin
                green = 8'h1F;
            end else if (pos_x < 200) begin
                green = 8'h3F;
            end else if (pos_x < 280) begin
                green = 8'h7F;
            end else if (pos_x < 360) begin
                green = 8'h3F;
            end else if (pos_x < 420) begin
                green = 8'h1F;
            end else begin
                green = 8'h0F;
            end

            if (pos_x < 120) begin
                blue = 8'h1F;
            end else if (pos_x < 240) begin
                blue = 8'h3F;
            end else if (pos_x < 360) begin
                blue = 8'h7F;
            end else begin
                blue = 8'hFF;
            end
        end
        PATTERN_HORIZONTAL_STRIPES: begin
            if (pos_y < 34) begin
                red = 8'h0F;
            end else if (pos_y < 68) begin
                red = 8'h1F;
            end else if (pos_y < 136) begin
                red = 8'h3F;
            end else if (pos_y < 204) begin
                red = 8'h3F;
            end else begin
                red = 8'h1F;
            end

            if (pos_y < 90) begin
                green = 8'h1F;
            end else if (pos_y < 180) begin
                green = 8'h3F;
            end else begin
                green = 8'hFF;
            end

            if (pos_y < 68) begin
                blue = 8'hFF;
            end else if (pos_y < 136) begin
                blue = 8'h7F;
            end else if (pos_y < 204) begin
                blue = 8'h3F;
            end else begin
                blue = 8'h1F;
            end
        end
        default: begin
            red = 8'h00;
            green = 8'h00;
            blue = 8'h00;
        end
    endcase
end

endmodule