module tile_generator (
    input clk,
    input rst_n,
    input [9:0] pos_x,
    input [8:0] pos_y,
    output reg [7:0] red,
    output reg [7:0] green,
    output reg [7:0] blue);

`ifdef SIM
    localparam
    SCREEN_WIDTH = 64,
    SCREEN_HEIGHT = 32;
`else
    localparam
    SCREEN_WIDTH = 480,
    SCREEN_HEIGHT = 272;
`endif

localparam
TILE_WIDTH = 8,
TILE_HEIGHT = 8;

localparam
TILE_COLUMNS = SCREEN_WIDTH / TILE_WIDTH,
TILE_ROWS = SCREEN_HEIGHT / TILE_HEIGHT;


/* 5 tiles (8x8, each 16bit rgb - 565RGB) */
reg [15:0] tile_memory [0:(5*8*8-1)];

/* Screen buffer - stores displayed tiles for each field of size TILE_WIDTH * TILE_HEIGHT */
/* Each memory cell stores 4 consequtive tiles (4 bits for rotation and mirroring and 4 bits for tile ID - up to 16 tiles) */
reg [31:0] screen_memory [0:(TILE_COLUMNS * TILE_ROWS / 4 - 1)];

integer i;
initial begin
    $readmemh("../tiles/tiles.hex", tile_memory);
    for (i = 0; i < (TILE_COLUMNS * TILE_ROWS / 4 - 1); i = i + 1) begin
        screen_memory[i] = 32'h03020100;
    end
end

/* Position inside tile field */
wire [2:0] tile_x;
wire [2:0] tile_y;

/* Screen x and y position defined in character fields */
wire [6:0] screen_x;
wire [5:0] screen_y;

assign tile_x = pos_x[2:0];
assign screen_x = pos_x[9:3];
assign tile_y = pos_y[2:0];
assign screen_y = pos_y[8:3];

reg [15:0] rgb_value; /* in same format as in memory */

reg [31:0] offset;
reg [31:0] tile_id;
reg [31:0] tile_offset;

/* Pixel value pipeline (4 clk delay) */
/* Because of delay in pipeline, the rising edge of lcd_dclk should come when pixel_value is valid 
    (what is 4 clock after valid pos_x and pos_y - falling edge of lcd_dclk) */
always @(posedge clk) begin
    if (!rst_n) begin
        offset <= 32'd0;
        tile_id <= 32'd0;
        tile_offset <= 32'd0;
        rgb_value <= 16'd0;
    end else begin
        offset <= screen_y * TILE_COLUMNS + screen_x;
        tile_id <= screen_memory[offset[31:2]][{offset[1:0], 3'b110} -: 7];
        /* Ofsset by tile_id * 64 (tile size in pixels) + tile_y * 8 (tile width) + tile_y */
        tile_offset <= {tile_id[25:0], 6'h0} + {tile_y, 3'h0} + tile_x; 
        rgb_value <= tile_memory[tile_offset];
    end
end

assign mem_cell = offset[31:2];
assign mem_bus_upper_bit = {offset[1:0], 3'b110};

/* Convert 565RGB into 24 bit RGB */
always @(*) begin
    red = {rgb_value[15:11], 3'h0};
    green = {rgb_value[10:5], 2'h0};
    blue = {rgb_value[4:0], 3'h0};
end


endmodule