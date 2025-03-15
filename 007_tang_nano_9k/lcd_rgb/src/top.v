module top (
    input clk,
    input rst_btn_n,
    output [4:0] lcd_red,
    output [5:0] lcd_green,
    output [4:0] lcd_blue,
    output lcd_dclk,
    output lcd_de,
    output lcd_vsync,
    output lcd_hsync);

/************************
    RESET SIGNAL
************************/
reg [11:0] rst_counter = 0;
wire rst_n;

always @(posedge clk) begin
    if (rst_counter[11] == 0) begin
        rst_counter <= rst_counter + 12'd1;
    end else if (!rst_btn_n) begin
        rst_counter <= 12'd0;
    end
end

assign rst_n = rst_counter[11];


/************************
    LCD DRIVER INSTANCE
************************/
wire [7:0] red;
wire [7:0] green;
wire [7:0] blue;

lcd_rgb lcd(
    .clk(clk),
    .rst_n(rst_n),
    .red(red),
    .green(green),
    .blue(blue),
    .dclk(lcd_dclk),
    .de(lcd_de));

assign lcd_red = red[7 -: 5];
assign lcd_green = green[7 -: 6];
assign lcd_blue = blue[7 -: 5];

/* Use DE mode - hsync and vsync tied to ground */
assign lcd_hsync = 0;
assign lcd_vsync = 0;

endmodule