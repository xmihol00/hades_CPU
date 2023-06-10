#include "colors.h"

int draw_frame(int color)
{
    color = color | (color << 4);
    color = color | (color << 8);
    color = color | (color << 12);

    for (int i = 0; i < 640; i = i + 4)
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

    for (int i = 4; i < 476; i = i + 1)
    {
        draw_quad_pixel(i, 0, color);
        draw_quad_pixel(i, 636, color);
    }

    return 0;
}
