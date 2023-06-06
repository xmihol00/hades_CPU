
int load(int *p, int value)
{
    *p = value;
    return 0;
}

int div10(int value, int *remainder)
{
    int quotient = (value >> 1) + (value >> 2);
    quotient = quotient + (quotient >> 4);
    quotient = quotient + (quotient >> 8);
    quotient = quotient + (quotient >> 16);
    quotient = quotient >> 3;
    int r = value - quotient * 10;
    quotient = quotient + ((r + 6) >> 4);
    
    if (r >= 10)
    {
        r = r - 10;
    }
    
    *remainder = r;
    return quotient;
}

int main()
{
    int array[1];
    array[0] = 'A';
    putchar(array[0]);

    load(array, 'B');
    putchar(array[0]);
    putchar('\n');

    int res = div10(25, array);
    putchar(res + '0');
    putchar('\n');
    putchar(array[0] + '0');
    putchar('\n');

    return 0;
}