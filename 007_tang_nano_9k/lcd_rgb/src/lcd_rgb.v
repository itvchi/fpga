module lcd_rgb (
    input clk,
    input rst_n,
    output [7:0] red,
    output [7:0] green,
    output [7:0] blue, 
    output dclk,
    output de,
    output vsync,
    output hsync);

`ifdef SIM
    /* 64x32px */ 
    localparam 
    TOTAL_HORIZONTAL = 10'd69,
    TOTAL_VERTICAL = 10'd35,
    HORIZONTAL_BLANKING = 10'd5,
    VERTICAL_BLANKING = 10'd3;
`else
    /* 480x272px */ 
    localparam 
    TOTAL_HORIZONTAL = 10'd525,
    TOTAL_VERTICAL = 10'd290,
    HORIZONTAL_BLANKING = 10'd45,
    VERTICAL_BLANKING = 10'd18;
`endif

localparam integer CLK_DIV = 5;
/* For pixel_generator pipeline clk should have at least 4 clock cycles between falling and rising edge of lcd_dclk
    (what is equal to clock division of clk_en signal, but safer option will be 5 clock cycles between edges) 
    -> during simulation i do not care about lcd_dclk frequency (which should be 8-12MHz)
    -> during tests on hardware i see that lcd works properly even on lower lcd_dclk frequency */

reg [31:0] clk_counter;
reg clk_en;
reg o_clk;

reg [11:0] pattern_counter;
reg [9:0] h_counter;
reg [8:0] v_counter;

wire [9:0] pos_x;
wire [8:0] pos_y;

/* Generate clk_en signal */
always @(posedge clk) begin
    if (!rst_n) begin
        clk_counter <= 32'd0;
        clk_en <= 1'b0;
    end else begin
        if (clk_counter >= (CLK_DIV - 1)) begin
            clk_counter <= 32'd0;
            clk_en <= 1'b1;
        end else begin
            clk_counter <= clk_counter + 32'd1;
            clk_en <= 1'b0;
        end
    end
end

/* Generate o_clk signal (dclk output) */
always @(posedge clk) begin
    if (!rst_n) begin
        o_clk <= 1'b0;
    end else begin
        if (clk_en) begin
            o_clk <= ~o_clk;
        end
    end
end

assign dclk = o_clk;

/* Horizontal, vertical and pattern counter */
always @(posedge clk) begin
    if (!rst_n) begin
        h_counter <= 10'd0;
        v_counter <= 9'd0;
        pattern_counter <= 12'd0;
    end else if (clk_en & o_clk) begin
        /* Update counterf on falling edge of dclk, to have nex pos_xy before latching edge (rising) */
        if (h_counter == TOTAL_HORIZONTAL-1) begin
            h_counter <= 10'd0;
            if(v_counter == TOTAL_VERTICAL-1) begin
                v_counter <= 9'd0;
                pattern_counter <= pattern_counter + 12'd1;
            end else begin
                v_counter <= v_counter + 9'd1;
            end
        end else begin 
            h_counter <= h_counter + 10'd1;
        end 
    end
end

/* Assign de signal - in DE mode hsync and vsync are not used but exported outside of the module */
assign hsync = (h_counter < HORIZONTAL_BLANKING) ? 1'b0 : 1'b1;
assign vsync = (v_counter < VERTICAL_BLANKING) ? 1'b0 : 1'b1;
assign de = (hsync & vsync);

/* Calculate x and y coordinates */
assign pos_x = (h_counter < HORIZONTAL_BLANKING) ? 10'd0 : (h_counter - HORIZONTAL_BLANKING);
assign pos_y = (v_counter < VERTICAL_BLANKING) ? 9'd0 : (v_counter - VERTICAL_BLANKING);

/* Drive rgb outputs */
wire [7:0] red_data;
wire [7:0] green_data;
wire [7:0] blue_data;

// pattern_generator pattern_gen (
//     .pattern(pattern_counter[8:7]),
//     .pos_x(pos_x),
//     .pos_y(pos_y),
//     .red(red_data),
//     .green(green_data),
//     .blue(blue_data));

/* Generate characters pixel_data */
wire pixel_data;

pixel_generator pixel_gen (
    .clk(clk),
    .rst_n(rst_n),
    .pos_x(pos_x),
    .pos_y(pos_y),
    .pixel_data(pixel_data));

tile_generator tile_gen (
    .clk(clk),
    .rst_n(rst_n),
    .pos_x(pos_x),
    .pos_y(pos_y),
    .red(red_data),
    .green(green_data),
    .blue(blue_data));

/* Display background data or black pixel of character */
assign red = pixel_data ? 8'h00 : red_data;
assign green = pixel_data ? 8'h00 : green_data;
assign blue = pixel_data ? 8'h00 : blue_data;

endmodule