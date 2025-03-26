#ifndef _LCD_H_
#define _LCD_H_

void lcd_clear();
void lcd_write_str(char *str);
void lcd_write_str_xy(char *str, unsigned int x, unsigned int y);

#endif /* _LCD_H_*/