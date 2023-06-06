
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

int main()
{
    int number = getnum();
    putchar('\n');
    putnum(number);
    putchar('\n');

    return 0;
}
