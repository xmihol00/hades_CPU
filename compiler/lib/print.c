
int print(int *string)
{
    while (*string != 0)
    {
        putchar(*string);
        string = string + 1;
    }
    return 0;
}
