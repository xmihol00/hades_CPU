#include "colors.h"
#include "stdbool.h"

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

int main()
{
    int old_cursor[18];
    old_cursor[0] = 319;
    old_cursor[1] = 239;
    for (int i = 2; i < 18; i = i + 1)
    {
        old_cursor[i] = BLACK;
    }

    int x = 320;
    int y = 240;

    while (true)
    {
        move_cursor(x, y, old_cursor);
        int buttons = buttons_status();
        x = x - (buttons & 1);
        x = x + ((buttons >> 2) & 1);
        y = y + ((buttons >> 1) & 1);
        y = y - ((buttons >> 3) & 1);
    }

    return 0;
}