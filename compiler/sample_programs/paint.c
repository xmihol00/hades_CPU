#include <stdbool.h>
#include "colors.h"

int main()
{
    while (init_mouse())
    {
    }
    init_frame_interrupts();

    int old_cursor[18];
    old_cursor[0] = 239;
    old_cursor[1] = 319;
    for (int i = 2; i < 18; i = i + 1)
    {
        old_cursor[i] = BLACK;
    }

    int x = 240;
    int y = 320;

    while (true)
    {
        move_cursor(x, y, old_cursor);
        
        int buttons = buttons_status();
        x = x - (buttons & 1);
        x = x + ((buttons >> 2) & 1);
        y = y + ((buttons >> 1) & 1);
        y = y - ((buttons >> 3) & 1);

        if (x < 5)
        {
            x = 5;
        }
        else if (x > 635)
        {
            x = 635;
        }

        if (y < 5)
        {
            y = 5;
        }
        else if (y > 475)
        {
            y = 475;
        }

        int mouse = mouse_status();
        if (mouse & 1)
        {
            putchar('L');
            for (int i = x -1; i <= x + 1; i = i + 1)
            {
                for (int j = y - 1; j <= y + 1; j = j + 1)
                {
                    draw_pixel(i, j, CURRENT_COLOR);
                }
            }
        }
        else if (mouse & 2)
        {
            putchar('R');
        }
        else if (mouse & 4)
        {
            putchar('M');
        }
    }

    return 0;
}