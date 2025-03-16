module pixel_generator(
    input clk,
    input rst_n,
    input [9:0] pos_x,
    input [8:0] pos_y,
    output [7:0] red,
    output [7:0] green,
    output [7:0] blue);

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
FONT_WIDTH = 8,
FONT_HEIGHT = 16;

localparam
CHAR_COLUMNS = SCREEN_WIDTH / FONT_WIDTH,
CHAR_ROWS = SCREEN_HEIGHT / FONT_HEIGHT;


/* 96 ASCII characters (16x8 - 16 lines, each byte codes one line like in I2C display) */
reg [7:0] font_memory [0:(95*16-1)];

/* Screen buffer - stores displayed character for each field of size FONT_WIDTH * FONT_HEIGHT */
reg [6:0] screen_memory [0:(CHAR_COLUMNS * CHAR_ROWS - 1)];


initial begin
    $readmemh("../font/ascii.hex", font_memory);
    $readmemh("../font/screen.hex", screen_memory);
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
        character <= screen_memory[offset];
        font_offset <= character * 16 + char_y;
        pixel_value <= font_memory[font_offset][char_x];
    end
end

/* Display white or black pixel */
assign red = pixel_value ? 8'hFF : 8'h00;
assign green = pixel_value ? 8'hFF : 8'h00;
assign blue = pixel_value ? 8'hFF : 8'h00;

endmodule