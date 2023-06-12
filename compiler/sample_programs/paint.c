#include <stdbool.h>
#include "colors.h"

int CURSOR_SPEED = 0;
int MARK_POINT = 0;
int DRAW = 0;
int CLEAR = 0;

// compile:
// python compiler.py sample_programs/paint.c -s -c -a sample_programs/paint_interrupt_handling.json 

int reset_cursor(int x, int y, int *cursor_buffer)
{
    cursor_buffer[0] = 240;
    cursor_buffer[1] = 320;
    for (int i = 2; i < 18; i = i + 1)
    {
        cursor_buffer[i] = BLACK;
    }

    draw_cursor(x, y);

    return 0;
}

int move_cursor(int x, int y, int *overwritten)
{
    int last_x = overwritten[0];
    int last_y = overwritten[1];

    if (last_x == x && last_y == y) // position of the cursor has not changed
    {
        return 0;
    }

    // draw stored pixels over the current cursor
    draw_pixel(last_x - 5, last_y, overwritten[2]);
    draw_pixel(last_x - 4, last_y, overwritten[3]);
    draw_pixel(last_x - 3, last_y, overwritten[4]);
    draw_pixel(last_x - 2, last_y, overwritten[5]);

    draw_pixel(last_x + 2, last_y, overwritten[6]);
    draw_pixel(last_x + 3, last_y, overwritten[7]);
    draw_pixel(last_x + 4, last_y, overwritten[8]);
    draw_pixel(last_x + 5, last_y, overwritten[9]);

    draw_pixel(last_x, last_y - 5, overwritten[10]);
    draw_pixel(last_x, last_y - 4, overwritten[11]);
    draw_pixel(last_x, last_y - 3, overwritten[12]);
    draw_pixel(last_x, last_y - 2, overwritten[13]);

    draw_pixel(last_x, last_y + 2, overwritten[14]);
    draw_pixel(last_x, last_y + 3, overwritten[15]);
    draw_pixel(last_x, last_y + 4, overwritten[16]);
    draw_pixel(last_x, last_y + 5, overwritten[17]);

    // remember the new cursor position
    overwritten[0] = x;
    overwritten[1] = y;

    // remember the pixels that will be overwritten
    overwritten[2] = get_pixel(x - 5, y);
    overwritten[3] = get_pixel(x - 4, y);
    overwritten[4] = get_pixel(x - 3, y);
    overwritten[5] = get_pixel(x - 2, y);

    overwritten[6] = get_pixel(x + 2, y);
    overwritten[7] = get_pixel(x + 3, y);
    overwritten[8] = get_pixel(x + 4, y);
    overwritten[9] = get_pixel(x + 5, y);

    overwritten[10] = get_pixel(x, y - 5);
    overwritten[11] = get_pixel(x, y - 4);
    overwritten[12] = get_pixel(x, y - 3);
    overwritten[13] = get_pixel(x, y - 2);

    overwritten[14] = get_pixel(x, y + 2);
    overwritten[15] = get_pixel(x, y + 3);
    overwritten[16] = get_pixel(x, y + 4);
    overwritten[17] = get_pixel(x, y + 5);

    draw_cursor(x, y); // draw the cursor at the new position

    return 0;
}

int draw_cursor(int x, int y)
{
    draw_pixel(x - 5, y, WHITE);
    draw_pixel(x - 4, y, WHITE);
    draw_pixel(x - 3, y, WHITE);
    draw_pixel(x - 2, y, WHITE);

    draw_pixel(x + 2, y, WHITE);
    draw_pixel(x + 3, y, WHITE);
    draw_pixel(x + 4, y, WHITE);
    draw_pixel(x + 5, y, WHITE);

    draw_pixel(x, y - 5, WHITE);
    draw_pixel(x, y - 4, WHITE);
    draw_pixel(x, y - 3, WHITE);
    draw_pixel(x, y - 2, WHITE);

    draw_pixel(x, y + 2, WHITE);
    draw_pixel(x, y + 3, WHITE);
    draw_pixel(x, y + 4, WHITE);
    draw_pixel(x, y + 5, WHITE);

    return 0;
}

int draw_frame(int color)
{
    // duplicate the color to all 16 bits
    color = color | (color << 4);
    color = color | (color << 8);
    color = color | (color << 12);

    for (int i = 0; i < 640; i = i + 4) // draw the top and bottom sides
    {
        draw_quad_pixel(0, i, color);
        draw_quad_pixel(1, i, color);
        draw_quad_pixel(2, i, color);
        draw_quad_pixel(3, i, color);

        draw_quad_pixel(476, i, color);
        draw_quad_pixel(477, i, color);
        draw_quad_pixel(478, i, color);
        draw_quad_pixel(479, i, color);
    }

    for (int i = 4; i < 476; i = i + 1) // draw the left and right sides
    {
        draw_quad_pixel(i, 0, color);
        draw_quad_pixel(i, 636, color);
    }

    return 0;
}

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

    while (init_mouse()) { }
    init_paint_interrupts();
    init_7segment();
    display_number(32);

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

        int mouse = mouse_buttons_status(); // poll the mouse buttons
        if ((mouse & 1) || MARK_POINT)
        {
            MARK_POINT = false;
            for (int i = y -1; i <= y + 1; i = i + 1)
            {
                for (int j = x - 1; j <= x + 1; j = j + 1)
                {
                    draw_pixel(j, i, CURRENT_COLOR);
                }
            }
            
            if (coordinate_offset < 32)
            {
                x_buffer[coordinate_offset] = x;
                y_buffer[coordinate_offset] = y;
                coordinate_offset = coordinate_offset + 1;
                display_number(32 - coordinate_offset);
                print(point_marked_message);
            }
        }
        else if ((mouse & 2) || DRAW)
        {
            DRAW = false;
            if (coordinate_offset >= 2)
            {
                print(drawing_message);
                for (int i = 0; i < coordinate_offset - 1; i = i + 1)
                {
                    draw_line(x_buffer[i], y_buffer[i], x_buffer[i + 1], y_buffer[i + 1]);
                }
                coordinate_offset = 0;
                display_number(32);
            }
        }
        else if (mouse & 4)
        {
            putchar('M');
        }
    }

    return 0;
}
