
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
