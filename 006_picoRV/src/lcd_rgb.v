module lcd_rgb (
    input clk,
    input reset_n,
    /* Bus interface */
    input select,
    input [3:0] wstrb,
    input [11:0] addr,
    input [31:0] data_i,
    output ready,
    output [31:0] data_o,
    /* Lcd interface */
    output [7:0] red,
    output [7:0] green,
    output [7:0] blue, 
    output dclk,
    output de);

wire [9:0] pos_x;
wire [8:0] pos_y;
wire pixel_data;

lcd display(
    .clk(clk),
    .rst_n(reset_n),
    .dclk(dclk),
    .de(de),
    .pos_x(pos_x),
    .pos_y(pos_y));

lcd_memory display_memory(
    .clk(clk),
    .rst_n(reset_n),
    .select(select),
    .wstrb(wstrb),
    .addr(addr),
    .data_i(data_i),
    .ready(ready),
    .data_o(data_o),
    .pos_x(pos_x),
    .pos_y(pos_y),
    .pixel_data(pixel_data));

/* Display background data or black pixel of character */
assign red = pixel_data ? 8'hFF : 8'h00;
assign green = pixel_data ? 8'hFF : 8'h00;
assign blue = pixel_data ? 8'hFF : 8'h00;

endmodule

module lcd (
    input clk,
    input rst_n,
    output dclk,
    output de,
    output [9:0] pos_x,
    output [8:0] pos_y);

/* 480x272px */ 
localparam 
TOTAL_HORIZONTAL = 10'd525,
TOTAL_VERTICAL = 10'd290,
HORIZONTAL_BLANKING = 10'd45,
VERTICAL_BLANKING = 10'd18;

localparam integer CLK_DIV = 5;
/* For pixel_generator pipeline clk should have at least 4 clock cycles between falling and rising edge of lcd_dclk
    (what is equal to clock division of clk_en signal, but safer option will be 5 clock cycles between edges) 
    -> during simulation i do not care about lcd_dclk frequency (which should be 8-12MHz)
    -> during tests on hardware i see that lcd works properly even on lower lcd_dclk frequency */

reg [31:0] clk_counter;
reg clk_en;
reg o_clk;

reg [9:0] h_counter;
reg [8:0] v_counter;

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

/* Horizontal and vertical counter */
always @(posedge clk) begin
    if (!rst_n) begin
        h_counter <= 10'd0;
        v_counter <= 9'd0;
    end else if (clk_en & o_clk) begin
        /* Update counterf on falling edge of dclk, to have nex pos_xy before latching edge (rising) */
        if (h_counter == TOTAL_HORIZONTAL-1) begin
            h_counter <= 10'd0;
            if(v_counter == TOTAL_VERTICAL-1) begin
                v_counter <= 9'd0;
            end else begin
                v_counter <= v_counter + 9'd1;
            end
        end else begin 
            h_counter <= h_counter + 10'd1;
        end 
    end
end

/* hsync and vsync outputs are tied to ground in top module, because lcd is unsed in DE mode */
assign hsync = (h_counter < HORIZONTAL_BLANKING) ? 1'b0 : 1'b1;
assign vsync = (v_counter < VERTICAL_BLANKING) ? 1'b0 : 1'b1;
assign de = (hsync & vsync);

/* Calculate x and y coordinates */
assign pos_x = (h_counter < HORIZONTAL_BLANKING) ? 10'd0 : (h_counter - HORIZONTAL_BLANKING);
assign pos_y = (v_counter < VERTICAL_BLANKING) ? 9'd0 : (v_counter - VERTICAL_BLANKING);

endmodule

module lcd_memory (
    input clk,
    input rst_n,
    input select,
    input [3:0] wstrb,
    input [11:0] addr,
    input [31:0] data_i,
    output reg ready,
    output reg [31:0] data_o,
    input [9:0] pos_x,
    input [8:0] pos_y,
    output pixel_data);

localparam
SCREEN_WIDTH = 480,
SCREEN_HEIGHT = 272;

localparam
FONT_WIDTH = 8,
FONT_HEIGHT = 16;

localparam
CHAR_COLUMNS = SCREEN_WIDTH / FONT_WIDTH,
CHAR_ROWS = SCREEN_HEIGHT / FONT_HEIGHT;


/* 96 ASCII characters (16x8 - 16 lines, each byte codes one line like in I2C display) */
reg [7:0] font_memory [0:(95*16-1)];

/* Screen buffer - stores displayed character for each field of size FONT_WIDTH * FONT_HEIGHT */
/* Changed memory layout fo full word, for better interface with system bus 
    (and changed size of one entry from 7 to 8 bits - additional bit for font color selection, 
    which will be used with background) */
reg [31:0] screen_memory [0:(CHAR_COLUMNS * CHAR_ROWS / 4 - 1)];


initial begin
    $readmemh("../font/ascii.hex", font_memory);
end

/* Position inside character field */
wire [2:0] char_x;
wire [3:0] char_y;

/* Screen x and y position defined in character fields */
wire [6:0] screen_x;
wire [4:0] screen_y;

assign char_x = pos_x[2:0];
assign screen_x = pos_x[9:3];
assign char_y = pos_y[3:0];
assign screen_y = pos_y[8:4];

reg pixel_value;

reg [31:0] offset;
reg [31:0] font_offset;
reg [31:0] character;

/* Pixel value pipeline (4 clk delay) */
/* Because of delay in pipeline, the rising edge of lcd_dclk should come when pixel_value is valid 
    (what is 4 clock after valid pos_x and pos_y - falling edge of lcd_dclk) */
always @(posedge clk) begin
    if (!rst_n) begin
        offset <= 32'd0;
        font_offset <= 32'd0;
        character <= 32'd0;
        pixel_value <= 1'b0;
    end else begin
        offset <= screen_y * CHAR_COLUMNS + screen_x;
        /* Screen_memory cell (modulo 4 of offset) and byte (offset lower bits+1 * 8, then -2, which is same as 
            offset lower bits * 8 + 6 - the operation is for range and omitt color bit and take 7 bit of data) selection */
        character <= screen_memory[offset[31:2]][{offset[1:0], 3'b110} -: 7];
        font_offset <= {character[31:0], 4'h0} + char_y; /* Same as *16, but saved 4 registers */
        pixel_value <= font_memory[font_offset][char_x];
    end
end

assign pixel_data = pixel_value;

reg mem_valid;
reg [11:0] mem_addr;
reg [6:0] mem_data;

/* Bus interface */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b0;
            mem_valid <= 1'b0;
        end else begin
            ready <= 1'b0;

            if (select) begin
                if (wstrb == 'd0) begin
                    data_o <= 32'd0;
                end else begin
                    if (addr[11:2] < (CHAR_COLUMNS * CHAR_ROWS / 4 - 1)) begin
                        if (wstrb[0]) begin
                            screen_memory[addr[11:2]][7:0] <= data_i[7:0];
                        end
                        if (wstrb[1]) begin
                            screen_memory[addr[11:2]][15:8] <= data_i[15:8];
                        end
                        if (wstrb[2]) begin
                            screen_memory[addr[11:2]][23:16] <= data_i[23:16];
                        end
                        if (wstrb[3]) begin
                            screen_memory[addr[11:2]][31:24] <= data_i[31:24];
                        end
                    end
                end
                ready <= 1'b1;
            end
        end
    end

endmodule