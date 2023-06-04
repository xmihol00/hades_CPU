
int putnum(int n)
{
    if (n == 0)
    {
        putchar('0');
        return 0;
    }

    int quotient = (n >> 1) + (n >> 2);
    quotient = quotient + (quotient >> 4);
    quotient = quotient + (quotient >> 8);
    quotient = quotient + (quotient >> 16);
    quotient = quotient >> 3;
    int remainder = n - quotient * 10;
    quotient = quotient + ((remainder + 6) >> 4);
    if (quotient != 0)
    {
        putnum(quotient);
    }

    if (remainder >= 10)
    {
        remainder = remainder - 10;
    }
    putchar(remainder + '0');
    return 0;
}

int main()
{
    putnum(200);
    putchar('\n');
    putnum(201);
    putchar('\n');
    putnum(202);
    putchar('\n');
    putnum(203);
    putchar('\n');
    putnum(204);
    putchar('\n');
    putnum(205);
    putchar('\n');
    putnum(206);
    putchar('\n');
    putnum(207);
    putchar('\n');
    putnum(208);
    putchar('\n');
    putnum(209);
    putchar('\n');
    putnum(210);
    putchar('\n');
    putnum(211);
    putchar('\n');
    putnum(212);
    putchar('\n');
    int a = 9999 * 1000;
    putnum(a);
    putchar('\n');

    return 0;
}