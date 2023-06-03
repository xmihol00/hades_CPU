
int main()
{
    int a = '\65';
    int b;
    int array[26];
    for (a = 0; a < 26; a = a + 1)
    {
        b = array + a;
        *b = a + 'A';
    }

    for (a = 2; a < 28; a = a + 1)
    {
        putchar(array[a - 2]);
    }

    return a + b + array;
}