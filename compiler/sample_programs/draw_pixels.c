#include "colors.h"

int main()
{
    for (int i = 235; i < 245; i = i + 1)
    {
        for (int j = 315; j < 325; j = j + 1)
        {
            draw_pixel(i, j, GREEN);
        }
    }

    return 0;
}