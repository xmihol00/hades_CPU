#include "colors.h"
#include "stdbool.h"

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