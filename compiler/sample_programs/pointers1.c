
int main()
{
    int array[10];
    int *p = array;

    for (int i = 0; i < 10; i = i + 1)
    {
        *p = i;
        p = p + 1;
    }

    for (int i = 0; i < 10; i = i + 1)
    {
        putchar(array[i] + '0');
        putchar('\n');
    }

    putchar('\n');
    putchar(*(p - 5) + '0');
    putchar('\n');
    putchar('\n');
    
    array[5] = 'X' - '0';
    *(p - 7) = 'Y' - '0';
    *(array + 8) = 'Z' - '0';

    for (int i = 0; i < 10; i = i + 1)
    {
        putchar(*(array + i) + '0');
        putchar('\n');
    }

    return 0;
}