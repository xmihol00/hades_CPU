#include <stdbool.h>
#include "colors.h"
#define CURSOR_SPEED 1

int abs(int x)
{
    if (x < 0)
    {
        return 0 - x;
    }
    else
    {
        return x;
    }
}

int draw_line(int x1, int y1, int x2, int y2) // Bresenham's line algorithm
{
    int steep = abs(y2 - y1) < abs(x2 - x1);

    if (steep)
    {
        // swap x1 and y1
        x1 = x1 ^ y1;
        y1 = y1 ^ x1;
        x1 = x1 ^ y1;
        
        // swap x2 and y2
        x2 = x2 ^ y2;
        y2 = y2 ^ x2;
        x2 = x2 ^ y2;
    }

    if (x1 > x2)
    {
        // swap x1 and x2
        x1 = x1 ^ x2;
        x2 = x2 ^ x1;
        x1 = x1 ^ x2;

        // swap y1 and y2
        y1 = y1 ^ y2;
        y2 = y2 ^ y1;
        y1 = y1 ^ y2;
    }

    int dx = x2 - x1;
    int dy = abs(y2 - y1);
    int P1 = 2 * dy;
    int P2 = P1 - 2 * dx;
    int P = P1 - dx;
    int y = y1;

    int y_step = 1;
    if (y1 > y2)
    {
        y_step = y_step - 2;
    }

    for (int x = x1; x <= x2; x = x + 1)
    {
        if (steep)
        {
            draw_pixel(y, x, CURRENT_COLOR);
        }
        else
        {
            draw_pixel(x, y, CURRENT_COLOR);
        }

        if (P >= 0)
        {
            P = P + P2;
            y = y + y_step;
        }
        else
        {
            P = P + P1;
        }
    }

    return 0;
}

int main()
{
    int point_marked_message[16];
    point_marked_message[0] = 'P'; point_marked_message[1] = 'o'; point_marked_message[2] = 'i'; point_marked_message[3] = 'n'; point_marked_message[4] = 't'; point_marked_message[5] = ' '; point_marked_message[6] = 'm'; point_marked_message[7] = 'a'; point_marked_message[8] = 'r'; point_marked_message[9] = 'k'; point_marked_message[10] = 'e'; point_marked_message[11] = 'd'; point_marked_message[12] = '.'; point_marked_message[13] = '.'; point_marked_message[14] = '.'; point_marked_message[15] = '\n';
    int drawing_message[12];
    drawing_message[0] = 'D'; drawing_message[1] = 'r'; drawing_message[2] = 'a'; drawing_message[3] = 'w'; drawing_message[4] = 'i'; drawing_message[5] = 'n'; drawing_message[6] = 'g'; drawing_message[7] = '.'; drawing_message[8] = '.'; drawing_message[9] = '.'; drawing_message[10] = '\n'; drawing_message[11] = '\0'; 

    int x_buffer[32];
    int y_buffer[32];
    int coordinate_offset = 0;
    int set_coordinates = 0;

    while (init_mouse()) { }
    init_paint_console();

    int cursor_buffer[18];
    int x = 320;
    int y = 240;
    reset_cursor(x, y, cursor_buffer);

    while (true)
    {
        move_cursor(x, y, cursor_buffer);
        
        int buttons = buttons_status();
        y = y - (buttons & 1) * CURSOR_SPEED;
        y = y + ((buttons >> 2) & 1) * CURSOR_SPEED;
        x = x + ((buttons >> 1) & 1) * CURSOR_SPEED;
        x = x - ((buttons >> 3) & 1) * CURSOR_SPEED;

        // make sure the cursor is within the height of the screen
        if (y < 5)
        {
            y = 5;
        }
        else if (y > 475)
        {
            y = 475;
        }

        // make sure the cursor is within the width of the screen
        if (x < 5)
        {
            x = 5;
        }
        else if (x > 635)
        {
            x = 635;
        }

        int mouse = mouse_status();
        if (mouse & 1)
        {
            for (int i = y -1; i <= y + 1; i = i + 1)
            {
                for (int j = x - 1; j <= x + 1; j = j + 1)
                {
                    draw_pixel(j, i, CURRENT_COLOR);
                }
            }
            
            x_buffer[coordinate_offset] = x;
            y_buffer[coordinate_offset] = y;
            coordinate_offset = coordinate_offset + 1;
            if (coordinate_offset == 32)
            {
                coordinate_offset = 0;
            }
            set_coordinates = set_coordinates + 1;
            print(point_marked_message);
        }
        else if (mouse & 2)
        {
            if (set_coordinates > 0)
            {
                print(drawing_message);
                draw_line(x_buffer[coordinate_offset - 2], y_buffer[coordinate_offset - 2], 
                          x_buffer[coordinate_offset - 1], y_buffer[coordinate_offset - 1]);
                set_coordinates = 0;
            }
        }
        else if (mouse & 4)
        {
            putchar('M');
        }
    }

    return 0;
}