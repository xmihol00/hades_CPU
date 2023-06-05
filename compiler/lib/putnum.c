
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
