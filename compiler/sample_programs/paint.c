#include <stdbool.h>
#include "colors.h"

int CURSOR_SPEED = 0;
int MARK_POINT = 0;
int DRAW_LINE = 0;
int CONNECT_POINTS = 0;
int FILL_AREA = 0;
int RASTERIZE_TRIANGLE = 0;
int CLEAR = 0;

// compile:
// python compiler.py sample_programs/paint.c -s -c -a sample_programs/paint_interrupt_handling.json 
// compile with debug info:
// python compiler.py sample_programs/paint.c -s -c -a sample_programs/paint_interrupt_handling.json -d 2>debug.txt

// main functionality:
// 1. marking points with the cursor (up to 32 points)
// 2. drawing a line between the last two marked points
// 3. connecting all drawn points into a polygon
// 4. filling the polygon with a color
// 5. rasterizing a triangle drawn with the last three marked points

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

int min(int x, int y, int z)
{
    if (x < y)
    {
        if (x < z)
        {
            return x;
        }
        else
        {
            return z;
        }
    }
    else
    {
        if (y < z)
        {
            return y;
        }
        else
        {
            return z;
        }
    }
}

int max(int x, int y, int z)
{
    if (x > y)
    {
        if (x > z)
        {
            return x;
        }
        else
        {
            return z;
        }
    }
    else
    {
        if (y > z)
        {
            return y;
        }
        else
        {
            return z;
        }
    }
}

int clear_console()
{
    for (int i = 0; i < 20; i = i + 1)
    {
        putchar('\n');
    }

    return 0;
}

int reset_cursor(int x, int y, int *cursor_buffer)
{
    cursor_buffer[0] = 320;
    cursor_buffer[1] = 240;
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
    draw_pixel(last_x - 2, last_y, overwritten[2]);
    draw_pixel(last_x - 3, last_y, overwritten[3]);
    draw_pixel(last_x - 4, last_y, overwritten[4]);
    draw_pixel(last_x - 5, last_y, overwritten[5]);

    draw_pixel(last_x + 2, last_y, overwritten[6]);
    draw_pixel(last_x + 3, last_y, overwritten[7]);
    draw_pixel(last_x + 4, last_y, overwritten[8]);
    draw_pixel(last_x + 5, last_y, overwritten[9]);

    draw_pixel(last_x, last_y - 2, overwritten[10]);
    draw_pixel(last_x, last_y - 3, overwritten[11]);
    draw_pixel(last_x, last_y - 4, overwritten[12]);
    draw_pixel(last_x, last_y - 5, overwritten[13]);

    draw_pixel(last_x, last_y + 2, overwritten[14]);
    draw_pixel(last_x, last_y + 3, overwritten[15]);
    draw_pixel(last_x, last_y + 4, overwritten[16]);
    draw_pixel(last_x, last_y + 5, overwritten[17]);

    // remember the new cursor position
    overwritten[0] = x;
    overwritten[1] = y;

    // remember the pixels that will be overwritten
    overwritten[2] = get_pixel(x - 2, y);
    overwritten[3] = get_pixel(x - 3, y);
    overwritten[4] = get_pixel(x - 4, y);
    overwritten[5] = get_pixel(x - 5, y);

    overwritten[6] = get_pixel(x + 2, y);
    overwritten[7] = get_pixel(x + 3, y);
    overwritten[8] = get_pixel(x + 4, y);
    overwritten[9] = get_pixel(x + 5, y);

    overwritten[10] = get_pixel(x, y - 2);
    overwritten[11] = get_pixel(x, y - 3);
    overwritten[12] = get_pixel(x, y - 4);
    overwritten[13] = get_pixel(x, y - 5);

    overwritten[14] = get_pixel(x, y + 2);
    overwritten[15] = get_pixel(x, y + 3);
    overwritten[16] = get_pixel(x, y + 4);
    overwritten[17] = get_pixel(x, y + 5);

    draw_cursor(x, y); // draw the cursor at the new position

    return 0;
}

int update_cursor(int *overwritten)
{
    // get the current cursor position
    int x = overwritten[0];
    int y = overwritten[1];

    // left wing
    for (int i = 2; i <= 5; i = i + 1)
    {
        int color = get_pixel(x - i, y);
        if (color != WHITE) // update the pixels of the cursor that were overwritten
        {
            overwritten[i] = color;
        }
    }
    overwritten = overwritten + 4;

    // right wing
    for (int i = 2; i <= 5; i = i + 1)
    {
        int color = get_pixel(x + i, y);
        if (color != WHITE) // update the pixels of the cursor that were overwritten
        {
            overwritten[i] = color;
        }
    }
    overwritten = overwritten + 4;

    // top wing
    for (int i = 2; i <= 5; i = i + 1)
    {
        int color = get_pixel(x, y - i);
        if (color != WHITE) // update the pixels of the cursor that were overwritten
        {
            overwritten[i] = color;
        }
    }
    overwritten = overwritten + 4;

    // bottom wing
    for (int i = 2; i <= 5; i = i + 1)
    {
        int color = get_pixel(x, y + i);
        if (color != WHITE) // update the pixels of the cursor that were overwritten
        {
            overwritten[i] = color;
        }
    }

    draw_cursor(x, y); // redraw the cursor
    return 0;
}

int draw_cursor(int x, int y)
{
    // left wing
    draw_pixel(x - 5, y, WHITE);
    draw_pixel(x - 4, y, WHITE);
    draw_pixel(x - 3, y, WHITE);
    draw_pixel(x - 2, y, WHITE);

    // right wing
    draw_pixel(x + 2, y, WHITE);
    draw_pixel(x + 3, y, WHITE);
    draw_pixel(x + 4, y, WHITE);
    draw_pixel(x + 5, y, WHITE);

    // top wing
    draw_pixel(x, y - 5, WHITE);
    draw_pixel(x, y - 4, WHITE);
    draw_pixel(x, y - 3, WHITE);
    draw_pixel(x, y - 2, WHITE);

    // bottom wing
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

int draw_line(int x1, int y1, int x2, int y2, int color) // Bresenham's line algorithm
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

    // set up predictor
    int dx = x2 - x1;
    int dy = abs(y2 - y1);
    int P1 = 2 * dy;
    int P2 = P1 - 2 * dx;
    int P = P1 - dx;
    int y = y1;

    // set up step along y axis
    int y_step = 1;
    if (y1 > y2)
    {
        y_step = y_step - 2;
    }

    for (int x = x1; x <= x2; x = x + 1) // move along x axis
    {
        if (steep)
        {
            // draw line 3 pixels thick
            draw_pixel(y - 1, x, color);
            draw_pixel(y, x, color);
            draw_pixel(y + 1, x, color);
        }
        else
        {
            // draw line 3 pixels thick
            draw_pixel(x, y - 1, color);
            draw_pixel(x, y, color);
            draw_pixel(x, y + 1, color);
        }

        // update predictor
        if (P >= 0)
        {
            P = P + P2;
            y = y + y_step; // move along y axis
        }
        else
        {
            P = P + P1;
        }
    }

    return 0;
}

int fill_area(int x, int y, int color, int max_depth)
{
    draw_pixel(x, y, color); // fill the current pixel
    max_depth = max_depth - 1;
    if (max_depth == 0)
    {
        return 0;
    }
    
    // move seeds to surrounding pixels if they are not already filled
    if (get_pixel(x - 1, y) != color) // check left
    {
        fill_area(x - 1, y, color, max_depth);
    }

    if (get_pixel(x, y - 1) != color) // check up
    {
        fill_area(x, y - 1, color, max_depth);
    }

    if (get_pixel(x, y + 1) != color) // check down
    {
        fill_area(x, y + 1, color, max_depth);
    }

    if (get_pixel(x + 1, y) != color) // check right
    {
        fill_area(x + 1, y, color, max_depth);
    }
    
    if (get_pixel(x + 1, y + 1) != color) // check bottom right
    {
        fill_area(x + 1, y + 1, color, max_depth);
    }

    if (get_pixel(x + 1, y - 1) != color) // check top right
    {
        fill_area(x + 1, y - 1, color, max_depth);
    }

    if (get_pixel(x - 1, y - 1) != color) // check top left
    {
        fill_area(x - 1, y - 1, color, max_depth);
    }

    if (get_pixel(x - 1, y + 1) != color) // check bottom left
    {
        fill_area(x - 1, y + 1, color, max_depth);
    }

    return 0;
}

int rasterize_triangle(int x1, int y1, int x2, int y2, int x3, int y3, int color) // Pineda triangle rasterization algorithm
{
    int area = (x1 - x3) * (y2 - y1) - (x1 - x2) * (y3 - y1);
    if (area < 0) // ensure that the triangle is counter-clockwise
    {
        // swap x2 and x3
        x2 = x2 ^ x3;
        x3 = x3 ^ x2;
        x2 = x2 ^ x3;

        // swap y2 and y3
        y2 = y2 ^ y3;
        y3 = y3 ^ y2;
        y2 = y2 ^ y3;
    }

    // find the bounding box
    int x_min = min(x1, x2, x3);
    int x_max = max(x1, x2, x3);
    int y_min = min(y1, y2, y3);
    int y_max = max(y1, y2, y3);

    // compute vectors
    int A1 = y1 - y2;
    int B1 = x2 - x1;
    int A2 = y2 - y3;
    int B2 = x3 - x2;
    int A3 = y3 - y1;
    int B3 = x1 - x3;
    
    // edge = A*x + B*y + C
    int a_edge = A1 * x_min + B1 * y_min + x1 * y2 - x2 * y1;
    int b_edge = A2 * x_min + B2 * y_min + x2 * y3 - x3 * y2;
    int c_edge = A3 * x_min + B3 * y_min + x3 * y1 - x1 * y3;

    // zig zag fill
    int iterator = 1;
    for (int y = y_min; y <= y_max; y = y + 1)
    {
        for (int x = x_min; x != x_max; x = x + iterator)
        {
            if (a_edge >= 0 && b_edge >= 0 && c_edge >= 0)
            {
                draw_pixel(x, y, color);
            }

            a_edge = a_edge + A1;
            b_edge = b_edge + A2;
            c_edge = c_edge + A3;
        }

        // swap x_min and x_max
        x_min = x_min ^ x_max;
        x_max = x_max ^ x_min;
        x_min = x_min ^ x_max;
        
        iterator = 0 - iterator;
        A1 = 0 - A1;
        A2 = 0 - A2;
        A3 = 0 - A3;
        a_edge = a_edge + B1;
        b_edge = b_edge + B2;
        c_edge = c_edge + B3;
    }
    
    // draw the edges
    draw_line(x1, y1, x2, y2, color);
    draw_line(x2, y2, x3, y3, color);
    draw_line(x3, y3, x1, y1, color);

    return 0;
}

int main()
{
    clear_console();
    set_background(BLACK); // reset the screen

    int point_marked_message[17];
    point_marked_message[0] = 'P'; point_marked_message[1] = 'o'; point_marked_message[2] = 'i'; point_marked_message[3] = 'n'; point_marked_message[4] = 't'; point_marked_message[5] = ' '; point_marked_message[6] = 'm'; point_marked_message[7] = 'a'; point_marked_message[8] = 'r'; point_marked_message[9] = 'k'; point_marked_message[10] = 'e'; point_marked_message[11] = 'd'; point_marked_message[12] = '.'; point_marked_message[13] = '.'; point_marked_message[14] = '.'; point_marked_message[15] = '\n'; point_marked_message[16] = '\0';
    int drawing_line_message[17];
    drawing_line_message[0] = 'D'; drawing_line_message[1] = 'r'; drawing_line_message[2] = 'a'; drawing_line_message[3] = 'w'; drawing_line_message[4] = 'i'; drawing_line_message[5] = 'n'; drawing_line_message[6] = 'g'; drawing_line_message[7] = ' '; drawing_line_message[8] = 'l'; drawing_line_message[9] = 'i'; drawing_line_message[10] = 'n'; drawing_line_message[11] = 'e'; drawing_line_message[12] = '.'; drawing_line_message[13] = '.'; drawing_line_message[14] = '.'; drawing_line_message[15] = '\n'; drawing_line_message[16] = '\0';
    int drawing_shape_message[18];
    drawing_shape_message[0] = 'D'; drawing_shape_message[1] = 'r'; drawing_shape_message[2] = 'a'; drawing_shape_message[3] = 'w'; drawing_shape_message[4] = 'i'; drawing_shape_message[5] = 'n'; drawing_shape_message[6] = 'g'; drawing_shape_message[7] = ' '; drawing_shape_message[8] = 's'; drawing_shape_message[9] = 'h'; drawing_shape_message[10] = 'a'; drawing_shape_message[11] = 'p'; drawing_shape_message[12] = 'e'; drawing_shape_message[13] = '.'; drawing_shape_message[14] = '.'; drawing_shape_message[15] = '.'; drawing_shape_message[16] = '\n'; drawing_shape_message[17] = '\0';
    int filling_area_message[17];
    filling_area_message[0] = 'F'; filling_area_message[1] = 'i'; filling_area_message[2] = 'l'; filling_area_message[3] = 'l'; filling_area_message[4] = 'i'; filling_area_message[5] = 'n'; filling_area_message[6] = 'g'; filling_area_message[7] = ' '; filling_area_message[8] = 'a'; filling_area_message[9] = 'r'; filling_area_message[10] = 'e'; filling_area_message[11] = 'a'; filling_area_message[12] = '.'; filling_area_message[13] = '.'; filling_area_message[14] = '.'; filling_area_message[15] = '\n'; filling_area_message[16] = '\0';
    int rasterizing_triangle_message[24];
    rasterizing_triangle_message[0] = 'R'; rasterizing_triangle_message[1] = 'a'; rasterizing_triangle_message[2] = 's'; rasterizing_triangle_message[3] = 't'; rasterizing_triangle_message[4] = 'e'; rasterizing_triangle_message[5] = 'r'; rasterizing_triangle_message[6] = 'i'; rasterizing_triangle_message[7] = 'z'; rasterizing_triangle_message[8] = 'i'; rasterizing_triangle_message[9] = 'n'; rasterizing_triangle_message[10] = 'g'; rasterizing_triangle_message[11] = ' '; rasterizing_triangle_message[12] = 't'; rasterizing_triangle_message[13] = 'r'; rasterizing_triangle_message[14] = 'i'; rasterizing_triangle_message[15] = 'a'; rasterizing_triangle_message[16] = 'n'; rasterizing_triangle_message[17] = 'g'; rasterizing_triangle_message[18] = 'l'; rasterizing_triangle_message[19] = 'e'; rasterizing_triangle_message[20] = '.'; rasterizing_triangle_message[21] = '.'; rasterizing_triangle_message[22] = '.'; rasterizing_triangle_message[23] = '\n'; rasterizing_triangle_message[24] = '\0';

    int x_buffer[32];
    int y_buffer[32];
    int coordinate_offset = 0;

    while (init_mouse()) { } // wait for the mouse to be ready
    init_paint_interrupts();
    init_7segment();
    display_number(32);

    int cursor_buffer[18];
    int x = 320;
    int y = 240;
    reset_cursor(x, y, cursor_buffer);

    while (true) // main loop of the program
    {
        move_cursor(x, y, cursor_buffer);
        
        int buttons = buttons_status(); // poll the console buttons
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
            // draw a 3x3 square
            for (int i = y -1; i <= y + 1; i = i + 1)
            {
                for (int j = x - 1; j <= x + 1; j = j + 1)
                {
                    draw_pixel(j, i, CURRENT_COLOR);
                }
            }
            
            if (coordinate_offset < 32) // ensure that the buffer is not full
            {
                x_buffer[coordinate_offset] = x;
                y_buffer[coordinate_offset] = y;
                coordinate_offset = coordinate_offset + 1;
                display_number(32 - coordinate_offset);
                print(point_marked_message);
            }
            MARK_POINT = false;
        }
        else if ((mouse & 2) || DRAW_LINE)
        {
            if (coordinate_offset >= 2) // ensure that there is something to draw
            {
                print(drawing_line_message);
                draw_line(x_buffer[coordinate_offset - 2], y_buffer[coordinate_offset - 2], 
                          x_buffer[coordinate_offset - 1], y_buffer[coordinate_offset - 1], 
                          CURRENT_COLOR);
                
                coordinate_offset = coordinate_offset - 2;
                update_cursor(cursor_buffer);
                display_number(32 - coordinate_offset);
            }
            DRAW_LINE = false;
        }
        else if (CONNECT_POINTS)
        {
            if (coordinate_offset >= 2) // ensure that there is something to draw
            {
                print(drawing_shape_message);
                for (int i = 0; i < coordinate_offset - 1; i = i + 1)
                {
                    draw_line(x_buffer[i], y_buffer[i], x_buffer[i + 1], y_buffer[i + 1], CURRENT_COLOR);
                }
                draw_line(x_buffer[0], y_buffer[0], x_buffer[coordinate_offset - 1], y_buffer[coordinate_offset - 1], CURRENT_COLOR);

                coordinate_offset = 0;
                update_cursor(cursor_buffer);
                display_number(32);
            }
            CONNECT_POINTS = false;
        }
        else if (FILL_AREA)
        {
            print(filling_area_message);
            fill_area(x, y, CURRENT_COLOR, 375);
            update_cursor(cursor_buffer);
            FILL_AREA = false;
        }
        else if (RASTERIZE_TRIANGLE)
        {
            if (coordinate_offset >= 3)
            {
                print(rasterizing_triangle_message);
                int i = coordinate_offset - 3;
                rasterize_triangle(x_buffer[i], y_buffer[i], 
                                   x_buffer[i + 1], y_buffer[i + 1], 
                                   x_buffer[i + 2], y_buffer[i + 2], 
                                   CURRENT_COLOR);
                coordinate_offset = coordinate_offset - 3;
                update_cursor(cursor_buffer);
                display_number(32 - coordinate_offset);
            }
            RASTERIZE_TRIANGLE = false;
        }
        else if ((mouse & 4) || CLEAR)
        {
            set_background(BLACK);
            draw_frame(CURRENT_COLOR);
            update_cursor(cursor_buffer);
            coordinate_offset = 0;
            display_number(32);
            clear_console();
            CLEAR = false;
        }
    }

    return 0;
}
