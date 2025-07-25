#include "st7789.h"
#include "stddef.h"
#include "assert.h"
#include <stdlib.h>

static ST7789_Conf_t lcd_conf;

static void configure(ST7789_Resolution_t resolution, ST7789_Rotation_t rotation) {

    // assert(resolution < ST7789_RESOLUTION_MAX);
    // assert(rotation < ST7789_ROTATION_MAX);

    ST7789_Conf_t conf[ST7789_RESOLUTION_MAX][ST7789_ROTATION_MAX] = {
        [ST7789_RESOLUTION_135X240] = {
            [ST7789_ROTATION_NONE]	= { .width = 135, .height = 240, .x_shift = 53, .y_shift = 40 },
            [ST7789_ROTATION_90]	= { .width = 240, .height = 135, .x_shift = 40, .y_shift = 52 },
            [ST7789_ROTATION_180]	= { .width = 135, .height = 240, .x_shift = 53, .y_shift = 40 },
            [ST7789_ROTATION_270]	= { .width = 240, .height = 135, .x_shift = 40, .y_shift = 52 }
        },
        [ST7789_RESOLUTION_240X240] = {
            [ST7789_ROTATION_NONE]	= { .width = 240, .height = 240, .x_shift = 0, .y_shift = 80 },
            [ST7789_ROTATION_90]	= { .width = 240, .height = 240, .x_shift = 80, .y_shift = 0 },
            [ST7789_ROTATION_180]	= { .width = 240, .height = 240, .x_shift = 0, .y_shift = 0 },
            [ST7789_ROTATION_270]	= { .width = 240, .height = 240, .x_shift = 0, .y_shift = 0 }
        },
        [ST7789_RESOLUTION_240X280] = {
            [ST7789_ROTATION_NONE]	= { .width = 240, .height = 280, .x_shift = 0, .y_shift = 80 }, /* To check */
            [ST7789_ROTATION_90]	= { .width = 280, .height = 240, .x_shift = 80, .y_shift = 0 }, /* To check */
            [ST7789_ROTATION_180]	= { .width = 240, .height = 280, .x_shift = 0, .y_shift = 20 }, /* Checked */
            [ST7789_ROTATION_270]	= { .width = 280, .height = 240, .x_shift = 0, .y_shift = 0 }   /* To check */
        },
        [ST7789_RESOLUTION_170X320] = {
            [ST7789_ROTATION_NONE]	= { .width = 170, .height = 320, .x_shift = 35, .y_shift = 0 },
            [ST7789_ROTATION_90]	= { .width = 320, .height = 170, .x_shift = 0, .y_shift = 35 },
            [ST7789_ROTATION_180]	= { .width = 170, .height = 320, .x_shift = 35, .y_shift = 0 },
            [ST7789_ROTATION_270]	= { .width = 320, .height = 170, .x_shift = 0, .y_shift = 35 }
        }
    };

	lcd_conf = conf[resolution][rotation];
}

/**
 * @brief Write command to ST7789 controller
 * @param cmd -> command to write
 * @return none
 */
static void ST7789_WriteCommand(uint8_t cmd)
{
	ST7789_Select();
	ST7789_DC_Clr();
	ST7789_SPI_Transmit(&cmd, sizeof(cmd));
	ST7789_UnSelect();
}

/**
 * @brief Write data to ST7789 controller
 * @param buff -> pointer of data buffer
 * @param buff_size -> size of the data buffer
 * @return none
 */
static void ST7789_WriteData(uint8_t *buff, size_t buff_size)
{
	ST7789_Select();
	ST7789_DC_Set();
	ST7789_SPI_Transmit(buff, buff_size);
	ST7789_UnSelect();
}
/**
 * @brief Write data to ST7789 controller, simplify for 8bit data.
 * data -> data to write
 * @return none
 */
static void ST7789_WriteByte(uint8_t data)
{
	ST7789_Select();
	ST7789_DC_Set();
	ST7789_SPI_Transmit(&data, sizeof(data));
	ST7789_UnSelect();
}

/**
 * @brief Set the rotation direction of the display
 * @param rotation -> rotation parameter(please refer it in st7789.h)
 * @return none
 */
void ST7789_SetRotation(ST7789_Rotation_t rotation)
{
	// assert(rotation < ST7789_ROTATION_MAX);

	uint8_t rotation_data[ST7789_ROTATION_MAX] = {
		[ST7789_ROTATION_NONE]	= (ST7789_MADCTL_MX | ST7789_MADCTL_MY | ST7789_MADCTL_RGB),
		[ST7789_ROTATION_90]	= (ST7789_MADCTL_MY | ST7789_MADCTL_MV | ST7789_MADCTL_RGB),
		[ST7789_ROTATION_180]	= (ST7789_MADCTL_RGB),
		[ST7789_ROTATION_270]	= (ST7789_MADCTL_MX | ST7789_MADCTL_MV | ST7789_MADCTL_RGB)
	};

	ST7789_WriteCommand(ST7789_MADCTL);	// MADCTL
	ST7789_WriteByte(rotation_data[rotation]);
}

/**
 * @brief Set address of DisplayWindow
 * @param xi&yi -> coordinates of window
 * @return none
 */
static void ST7789_SetAddressWindow(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1)
{
	ST7789_Select();
	uint16_t x_start = x0 + lcd_conf.x_shift, x_end = x1 + lcd_conf.x_shift;
	uint16_t y_start = y0 + lcd_conf.y_shift, y_end = y1 + lcd_conf.y_shift;
	
	/* Column Address set */
	ST7789_WriteCommand(ST7789_CASET); 
	{
		uint8_t data[] = {x_start >> 8, x_start & 0xFF, x_end >> 8, x_end & 0xFF};
		ST7789_WriteData(data, sizeof(data));
	}

	/* Row Address set */
	ST7789_WriteCommand(ST7789_RASET);
	{
		uint8_t data[] = {y_start >> 8, y_start & 0xFF, y_end >> 8, y_end & 0xFF};
		ST7789_WriteData(data, sizeof(data));
	}
	/* Write to RAM */
	ST7789_WriteCommand(ST7789_RAMWR);
	ST7789_UnSelect();
}


#define BUFFERED_LINES 10
uint16_t buffer[170*BUFFERED_LINES];

/**
 * @brief Initialize ST7789 controller
 * @param none
 * @return none
 */
void ST7789_Init(ST7789_Resolution_t resolution, ST7789_Rotation_t rotation)
{
	configure(resolution, rotation);
	lcd_conf.buffered_lines = BUFFERED_LINES;
	lcd_conf.buffers_in_height = lcd_conf.height / BUFFERED_LINES;
	lcd_conf.display_buffer = buffer; //calloc(lcd_conf.width * lcd_conf.buffered_lines, sizeof(uint16_t));

	delay_ms(25);
    ST7789_RST_Clr();
    delay_ms(25);
    ST7789_RST_Set();
    delay_ms(50);
	ST7789_WriteCommand(ST7789_SWRESET);	//	Out of sleep mode
		
//------------------------------display and color format setting--------------------------------//
    ST7789_WriteCommand(ST7789_COLMOD);		//	Set color mode
    ST7789_WriteByte(ST7789_COLOR_MODE_16bit);
	ST7789_SetRotation(rotation);	//	MADCTL (Display Rotation)

	// JLX240 display datasheet
	ST7789_WriteCommand(0xB6);
	ST7789_WriteByte(0x0A);
	ST7789_WriteByte(0x82);

	ST7789_WriteCommand(ST7789_RAMCTRL);
	ST7789_WriteByte(0x00);
	ST7789_WriteByte(0xE0); // 5 to 6 bit conversion: r0 = r5, b0 = b5

	delay_ms(10);

	//--------------------------------ST7789V Frame rate setting----------------------------------//
  	ST7789_WriteCommand(ST7789_PORCTRL);				//	Porch control
	{
		uint8_t data[] = {0x0C, 0x0C, 0x00, 0x33, 0x33};
		ST7789_WriteData(data, sizeof(data));
	}
	
	//---------------------------------ST7789V Power setting--------------------------------------//
    ST7789_WriteCommand(ST7789_GCTRL);				//	Gate Control
    ST7789_WriteByte(0x35);			//	Default value
    ST7789_WriteCommand(ST7789_VCOMS);				//	VCOM setting
    ST7789_WriteByte(0x19);			//	0.725v (default 0.75v for 0x20)
    ST7789_WriteCommand(ST7789_LCMCTRL);				//	LCMCTRL
    ST7789_WriteByte (0x2C);			//	Default value
    ST7789_WriteCommand (ST7789_VDVVRHEN);				//	VDV and VRH command Enable
    ST7789_WriteByte (0x01);			//	Default value
    ST7789_WriteCommand (ST7789_VRHS);				//	VRH set
    ST7789_WriteByte (0x12);			//	+-4.45v (defalut +-4.1v for 0x0B)
    ST7789_WriteCommand (ST7789_VDVSET);				//	VDV set
    ST7789_WriteByte (0x20);			//	Default value
    ST7789_WriteCommand (ST7789_FRCTR2);				//	Frame rate control in normal mode
    ST7789_WriteByte (0x0F);			//	Default value (60HZ)
    ST7789_WriteCommand (ST7789_PWCTRL1);				//	Power control
    ST7789_WriteByte (0xA4);			//	Default value
    ST7789_WriteByte (0xA1);			//	Default value

	//--------------------------------ST7789V gamma setting---------------------------------------//
	ST7789_WriteCommand(ST7789_PVGAMCTRL);
	{
		uint8_t data[] = {0xD0, 0x04, 0x0D, 0x11, 0x13, 0x2B, 0x3F, 0x54, 0x4C, 0x18, 0x0D, 0x0B, 0x1F, 0x23};
		ST7789_WriteData(data, sizeof(data));
	}

    ST7789_WriteCommand(ST7789_NVGAMCTRL);
	{
		uint8_t data[] = {0xD0, 0x04, 0x0C, 0x11, 0x13, 0x2C, 0x3F, 0x44, 0x51, 0x2F, 0x1F, 0x1F, 0x20, 0x23};
		ST7789_WriteData(data, sizeof(data));
	}

    ST7789_WriteCommand(ST7789_INVON);		//	Inversion ON
	ST7789_WriteCommand(ST7789_SLPOUT);		//	Out of sleep mode
  	ST7789_WriteCommand(ST7789_NORON);		//	Normal Display on
  	ST7789_WriteCommand(ST7789_DISPON);		//	Main screen turned on	

	delay_ms(50);
	ST7789_Fill_Color(BLACK);				//	Fill with Black.
}

/**
 * @brief Fill the DisplayWindow with single color
 * @param color -> color to Fill with
 * @return none
 */
void ST7789_Fill_Color(color_16bit_t color)
{
	uint16_t i;
	ST7789_SetAddressWindow(0, 0, lcd_conf.width - 1, lcd_conf.height - 1);

	size_t pixels = lcd_conf.width * lcd_conf.buffered_lines;

	color = (color << 8) | (color >> 8);

	for (i = 0; i < pixels; i++) {
		lcd_conf.display_buffer[i] = color;
	}

	ST7789_Select();
	for (i = 0; i < lcd_conf.buffers_in_height; i++) {
		ST7789_WriteData((uint8_t *)lcd_conf.display_buffer, pixels * sizeof(uint16_t));
	}
	ST7789_UnSelect();
}

/**
 * @brief Draw a Pixel
 * @param x&y -> coordinate to Draw
 * @param color -> color of the Pixel
 * @return none
 */
void ST7789_DrawPixel(uint16_t x, uint16_t y, color_16bit_t color)
{
	if ((x >= lcd_conf.width) || (y >= lcd_conf.height)) return;
	
	ST7789_SetAddressWindow(x, y, x, y);
	uint8_t data[] = {color >> 8, color & 0xFF};
	ST7789_Select();
	ST7789_WriteData(data, sizeof(data));
	ST7789_UnSelect();
}

/**
 * @brief Fill an Area with single color
 * @param xSta&ySta -> coordinate of the start point
 * @param xEnd&yEnd -> coordinate of the end point
 * @param color -> color to Fill with
 * @return none
 */
void ST7789_Fill(uint16_t xSta, uint16_t ySta, uint16_t xEnd, uint16_t yEnd, color_16bit_t color)
{
	if ((xEnd >= lcd_conf.width) || (yEnd >= lcd_conf.height)) return;
	ST7789_Select();
	uint16_t i, j;
	uint8_t line[2*lcd_conf.width];
	ST7789_SetAddressWindow(xSta, ySta, xEnd, yEnd);
	for (i = ySta; i <= yEnd; i++) {
		for (j = xSta; j <= xEnd; j++) {
			line[2*(j - xSta)] = color >> 8;
			line[2*(j - xSta) + 1] = color & 0xFF;
		}
		ST7789_WriteData(line, 2*(xEnd - xSta + 1));
	}
	ST7789_UnSelect();
}

/**
 * @brief Draw a big Pixel at a point
 * @param x&y -> coordinate of the point
 * @param color -> color of the Pixel
 * @return none
 */
void ST7789_DrawPixel_4px(uint16_t x, uint16_t y, color_16bit_t color)
{
	if ((x > lcd_conf.width) || (y > lcd_conf.height)) return;
	ST7789_Select();
	ST7789_Fill(x - 1, y - 1, x + 1, y + 1, color);
	ST7789_UnSelect();
}

/**
 * @brief Draw a line with single color
 * @param x1&y1 -> coordinate of the start point
 * @param x2&y2 -> coordinate of the end point
 * @param color -> color of the line to Draw
 * @return none
 */
void ST7789_DrawLine(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1,
        color_16bit_t color) {
	uint16_t swap;
    uint16_t steep = ABS(y1 - y0) > ABS(x1 - x0);
    if (steep) {
		swap = x0;
		x0 = y0;
		y0 = swap;

		swap = x1;
		x1 = y1;
		y1 = swap;
        //_swap_int16_t(x0, y0);
        //_swap_int16_t(x1, y1);
    }

    if (x0 > x1) {
		swap = x0;
		x0 = x1;
		x1 = swap;

		swap = y0;
		y0 = y1;
		y1 = swap;
        //_swap_int16_t(x0, x1);
        //_swap_int16_t(y0, y1);
    }

    int16_t dx, dy;
    dx = x1 - x0;
    dy = ABS(y1 - y0);

    int16_t err = dx / 2;
    int16_t ystep;

    if (y0 < y1) {
        ystep = 1;
    } else {
        ystep = -1;
    }

    for (; x0<=x1; x0++) {
        if (steep) {
            ST7789_DrawPixel(y0, x0, color);
        } else {
            ST7789_DrawPixel(x0, y0, color);
        }
        err -= dy;
        if (err < 0) {
            y0 += ystep;
            err += dx;
        }
    }
}

/**
 * @brief Draw a Rectangle with single color
 * @param xi&yi -> 2 coordinates of 2 top points.
 * @param color -> color of the Rectangle line
 * @return none
 */
void ST7789_DrawRectangle(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, color_16bit_t color)
{
	ST7789_Select();
	ST7789_DrawLine(x1, y1, x2, y1, color);
	ST7789_DrawLine(x1, y1, x1, y2, color);
	ST7789_DrawLine(x1, y2, x2, y2, color);
	ST7789_DrawLine(x2, y1, x2, y2, color);
	ST7789_UnSelect();
}

/** 
 * @brief Draw a circle with single color
 * @param x0&y0 -> coordinate of circle center
 * @param r -> radius of circle
 * @param color -> color of circle line
 * @return  none
 */
void ST7789_DrawCircle(uint16_t x0, uint16_t y0, uint8_t r, color_16bit_t color)
{
	int16_t f = 1 - r;
	int16_t ddF_x = 1;
	int16_t ddF_y = -2 * r;
	int16_t x = 0;
	int16_t y = r;

	ST7789_Select();
	ST7789_DrawPixel(x0, y0 + r, color);
	ST7789_DrawPixel(x0, y0 - r, color);
	ST7789_DrawPixel(x0 + r, y0, color);
	ST7789_DrawPixel(x0 - r, y0, color);

	while (x < y) {
		if (f >= 0) {
			y--;
			ddF_y += 2;
			f += ddF_y;
		}
		x++;
		ddF_x += 2;
		f += ddF_x;

		ST7789_DrawPixel(x0 + x, y0 + y, color);
		ST7789_DrawPixel(x0 - x, y0 + y, color);
		ST7789_DrawPixel(x0 + x, y0 - y, color);
		ST7789_DrawPixel(x0 - x, y0 - y, color);

		ST7789_DrawPixel(x0 + y, y0 + x, color);
		ST7789_DrawPixel(x0 - y, y0 + x, color);
		ST7789_DrawPixel(x0 + y, y0 - x, color);
		ST7789_DrawPixel(x0 - y, y0 - x, color);
	}
	ST7789_UnSelect();
}

/**
 * @brief Draw an Image on the screen
 * @param x&y -> start point of the Image
 * @param w&h -> width & height of the Image to Draw
 * @param data -> pointer of the Image array
 * @return none
 */
void ST7789_DrawImage(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const uint16_t *data)
{
	if ((x >= lcd_conf.width) || (y >= lcd_conf.height))
		return;
	if ((x + w - 1) >= lcd_conf.width)
		return;
	if ((y + h - 1) >= lcd_conf.height)
		return;

	ST7789_Select();
	ST7789_SetAddressWindow(x, y, x + w - 1, y + h - 1);
	ST7789_WriteData((uint8_t *)data, sizeof(uint16_t) * w * h);
	ST7789_UnSelect();
}

/**
 * @brief Invert Fullscreen color
 * @param invert -> Whether to invert
 * @return none
 */
void ST7789_InvertColors(uint8_t invert)
{
	ST7789_Select();
	ST7789_WriteCommand(invert ? 0x21 /* INVON */ : 0x20 /* INVOFF */);
	ST7789_UnSelect();
}

/** 
 * @brief Write a char
 * @param  x&y -> cursor of the start point.
 * @param ch -> char to write
 * @param font -> fontstyle of the string
 * @param color -> color of the char
 * @param bgcolor -> background color of the char
 * @return  none
 */
void ST7789_WriteChar(uint16_t x, uint16_t y, char ch, FontDef font, color_16bit_t color, uint16_t bgcolor)
{
	uint32_t i, b, j;
	ST7789_Select();
	ST7789_SetAddressWindow(x, y, x + font.width - 1, y + font.height - 1);

	for (i = 0; i < font.height; i++) {
		b = font.data[(ch - 32) * font.height + i];
		for (j = 0; j < font.width; j++) {
			if ((b << j) & 0x8000) {
				uint8_t data[] = {color >> 8, color & 0xFF};
				ST7789_WriteData(data, sizeof(data));
			}
			else {
				uint8_t data[] = {bgcolor >> 8, bgcolor & 0xFF};
				ST7789_WriteData(data, sizeof(data));
			}
		}
	}
	ST7789_UnSelect();
}

/** 
 * @brief Write a string 
 * @param  x&y -> cursor of the start point.
 * @param str -> string to write
 * @param font -> fontstyle of the string
 * @param color -> color of the string
 * @param bgcolor -> background color of the string
 * @return  none
 */
void ST7789_WriteString(uint16_t x, uint16_t y, const char *str, FontDef font, color_16bit_t color, uint16_t bgcolor)
{
	ST7789_Select();
	while (*str) {
		if (x + font.width >= lcd_conf.width) {
			x = 0;
			y += font.height;
			if (y + font.height >= lcd_conf.height) {
				break;
			}

			if (*str == ' ') {
				// skip spaces in the beginning of the new line
				str++;
				continue;
			}
		}
		ST7789_WriteChar(x, y, *str, font, color, bgcolor);
		x += font.width;
		str++;
	}
	ST7789_UnSelect();
}

/** 
 * @brief Draw a filled Rectangle with single color
 * @param  x&y -> coordinates of the starting point
 * @param w&h -> width & height of the Rectangle
 * @param color -> color of the Rectangle
 * @return  none
 */
void ST7789_DrawFilledRectangle(uint16_t x, uint16_t y, uint16_t w, uint16_t h, color_16bit_t color)
{
	ST7789_Select();
	uint8_t i;

	/* Check input parameters */
	if (x >= lcd_conf.width ||
		y >= lcd_conf.height) {
		/* Return error */
		return;
	}

	/* Check width and height */
	if ((x + w) >= lcd_conf.width) {
		w = lcd_conf.width - x;
	}
	if ((y + h) >= lcd_conf.height) {
		h = lcd_conf.height - y;
	}

	/* Draw lines */
	for (i = 0; i <= h; i++) {
		/* Draw lines */
		ST7789_DrawLine(x, y + i, x + w, y + i, color);
	}
	ST7789_UnSelect();
}

/** 
 * @brief Draw a Triangle with single color
 * @param  xi&yi -> 3 coordinates of 3 top points.
 * @param color ->color of the lines
 * @return  none
 */
void ST7789_DrawTriangle(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t x3, uint16_t y3, color_16bit_t color)
{
	ST7789_Select();
	/* Draw lines */
	ST7789_DrawLine(x1, y1, x2, y2, color);
	ST7789_DrawLine(x2, y2, x3, y3, color);
	ST7789_DrawLine(x3, y3, x1, y1, color);
	ST7789_UnSelect();
}

/** 
 * @brief Draw a filled Triangle with single color
 * @param  xi&yi -> 3 coordinates of 3 top points.
 * @param color ->color of the triangle
 * @return  none
 */
void ST7789_DrawFilledTriangle(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t x3, uint16_t y3, color_16bit_t color)
{
	ST7789_Select();
	int16_t deltax = 0, deltay = 0, x = 0, y = 0, xinc1 = 0, xinc2 = 0,
			yinc1 = 0, yinc2 = 0, den = 0, num = 0, numadd = 0, numpixels = 0,
			curpixel = 0;

	deltax = ABS(x2 - x1);
	deltay = ABS(y2 - y1);
	x = x1;
	y = y1;

	if (x2 >= x1) {
		xinc1 = 1;
		xinc2 = 1;
	}
	else {
		xinc1 = -1;
		xinc2 = -1;
	}

	if (y2 >= y1) {
		yinc1 = 1;
		yinc2 = 1;
	}
	else {
		yinc1 = -1;
		yinc2 = -1;
	}

	if (deltax >= deltay) {
		xinc1 = 0;
		yinc2 = 0;
		den = deltax;
		num = deltax / 2;
		numadd = deltay;
		numpixels = deltax;
	}
	else {
		xinc2 = 0;
		yinc1 = 0;
		den = deltay;
		num = deltay / 2;
		numadd = deltax;
		numpixels = deltay;
	}

	for (curpixel = 0; curpixel <= numpixels; curpixel++) {
		ST7789_DrawLine(x, y, x3, y3, color);

		num += numadd;
		if (num >= den) {
			num -= den;
			x += xinc1;
			y += yinc1;
		}
		x += xinc2;
		y += yinc2;
	}
	ST7789_UnSelect();
}

/** 
 * @brief Draw a Filled circle with single color
 * @param x0&y0 -> coordinate of circle center
 * @param r -> radius of circle
 * @param color -> color of circle
 * @return  none
 */
void ST7789_DrawFilledCircle(int16_t x0, int16_t y0, int16_t r, color_16bit_t color)
{
	ST7789_Select();
	int16_t f = 1 - r;
	int16_t ddF_x = 1;
	int16_t ddF_y = -2 * r;
	int16_t x = 0;
	int16_t y = r;

	ST7789_DrawPixel(x0, y0 + r, color);
	ST7789_DrawPixel(x0, y0 - r, color);
	ST7789_DrawPixel(x0 + r, y0, color);
	ST7789_DrawPixel(x0 - r, y0, color);
	ST7789_DrawLine(x0 - r, y0, x0 + r, y0, color);

	while (x < y) {
		if (f >= 0) {
			y--;
			ddF_y += 2;
			f += ddF_y;
		}
		x++;
		ddF_x += 2;
		f += ddF_x;

		ST7789_DrawLine(x0 - x, y0 + y, x0 + x, y0 + y, color);
		ST7789_DrawLine(x0 + x, y0 - y, x0 - x, y0 - y, color);

		ST7789_DrawLine(x0 + y, y0 + x, x0 - y, y0 + x, color);
		ST7789_DrawLine(x0 + y, y0 - x, x0 - y, y0 - x, color);
	}
	ST7789_UnSelect();
}


/**
 * @brief Open/Close tearing effect line
 * @param tear -> Whether to tear
 * @return none
 */
void ST7789_TearEffect(uint8_t tear)
{
	ST7789_Select();
	ST7789_WriteCommand(tear ? 0x35 /* TEON */ : 0x34 /* TEOFF */);
	ST7789_UnSelect();
}


/** 
 * @brief A Simple test function for ST7789
 * @param  none
 * @return  none
 */
void ST7789_Test(void)
{
	size_t index;
	color_16bit_t color_set[] = {
		CYAN,
		RED,
		GREEN,
		BLUE,
		YELLOW,
		BROWN,
		DARKBLUE,
		MAGENTA,
		LIGHTGREEN,
		LGRAY,
		LBBLUE,
		WHITE
	};

	ST7789_Fill_Color(WHITE);
	delay_ms(1000);
	// ST7789_WriteString(10, 20, "Speed Test", Font_11x18, RED, WHITE);
	delay_ms(1000);

	for (index = 0; index < (sizeof(color_set)/sizeof(color_16bit_t)); index++) {
		ST7789_Fill_Color(color_set[index]);
		delay_ms(500);
	}

	// ST7789_WriteString(10, 10, "Font test.", Font_16x26, GBLUE, WHITE);
	// ST7789_WriteString(10, 50, "Hello Steve!", Font_7x10, RED, WHITE);
	// ST7789_WriteString(10, 75, "Hello Steve!", Font_11x18, YELLOW, WHITE);
	// ST7789_WriteString(10, 100, "Hello Steve!", Font_16x26, MAGENTA, WHITE);
	delay_ms(1000);

	ST7789_Fill_Color(RED);
	// ST7789_WriteString(10, 10, "Rect./Line.", Font_11x18, YELLOW, BLACK);
	ST7789_DrawRectangle(30, 30, 100, 100, WHITE);
	delay_ms(1000);

	ST7789_Fill_Color(RED);
	// ST7789_WriteString(10, 10, "Filled Rect.", Font_11x18, YELLOW, BLACK);
	ST7789_DrawFilledRectangle(30, 30, 50, 50, WHITE);
	delay_ms(1000);

	ST7789_Fill_Color(RED);
	// ST7789_WriteString(10, 10, "Circle.", Font_11x18, YELLOW, BLACK);
	ST7789_DrawCircle(60, 60, 25, WHITE);
	delay_ms(1000);

	ST7789_Fill_Color(RED);
	// ST7789_WriteString(10, 10, "Filled Cir.", Font_11x18, YELLOW, BLACK);
	ST7789_DrawFilledCircle(60, 60, 25, WHITE);
	delay_ms(1000);

	ST7789_Fill_Color(RED);
	// ST7789_WriteString(10, 10, "Triangle", Font_11x18, YELLOW, BLACK);
	ST7789_DrawTriangle(30, 30, 30, 70, 60, 40, WHITE);
	delay_ms(1000);

	ST7789_Fill_Color(RED);
	// ST7789_WriteString(10, 10, "Filled Tri", Font_11x18, YELLOW, BLACK);
	ST7789_DrawFilledTriangle(30, 30, 30, 70, 60, 40, WHITE);
	delay_ms(1000);
}
