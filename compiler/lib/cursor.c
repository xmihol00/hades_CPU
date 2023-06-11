#include "colors.h"

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

    if (last_x == x && last_y == y)
    {
        return 0;
    }

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

    overwritten[0] = x;
    overwritten[1] = y;

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

    draw_cursor(x, y);

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