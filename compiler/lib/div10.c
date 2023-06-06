
int div10(int value)
{
    int quotient = (value >> 1) + (value >> 2);
    quotient = quotient + (quotient >> 4);
    quotient = quotient + (quotient >> 8);
    quotient = quotient + (quotient >> 16);
    quotient = quotient >> 3;
    value = value - quotient * 10;
    return quotient + ((value + 6) >> 4);
}
