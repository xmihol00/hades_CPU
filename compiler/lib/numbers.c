
int putnum(int number)
{
    if (number == 0)
    {
        putchar('0');
        return 0;
    }

    int quotient = (number >> 1) + (number >> 2);
    quotient = quotient + (quotient >> 4);
    quotient = quotient + (quotient >> 8);
    quotient = quotient + (quotient >> 16);
    quotient = quotient >> 3;
    int remainder = number - quotient * 10;
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

int getnum()
{
    int number = 0;
    int digit = getchar();
    while (digit != '\n' && digit != 0)
    {
        number = number * 10 + digit - '0';
        digit = getchar();
    }

    return number;
}

int display_number(int number)
{
    if (number > 9999)
    {
        number = 9999;
    }
    
    int converted_number = 0;
    int shift = 0;

    while (number)
    {
        int quotient = (number >> 1) + (number >> 2);
        quotient = quotient + (quotient >> 4);
        quotient = quotient + (quotient >> 8);
        quotient = quotient + (quotient >> 16);
        quotient = quotient >> 3;
        int remainder = number - quotient * 10;
        quotient = quotient + ((remainder + 6) >> 4);

        if (remainder >= 10)
        {
            remainder = remainder - 10;
        }

        converted_number = converted_number | (remainder << shift);
        shift = shift + 4;
        number = quotient;
    }

    converted_number = converted_number | (1 << 31); // set the active bit
    display_7segment(converted_number);

    return 0;
}

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
