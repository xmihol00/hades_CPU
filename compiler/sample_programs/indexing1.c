
int main()
{
    int a = '\65';
    int b;
    int array[26];
    
    for (a = 0; a < 26; a = a + 1)
    {
        b = array[a];
        putchar(b);
    }

    b = 5 + array[2 * 3 + 4];
    b = a * array[2 * (a + 1)] - 4;
    b = b * (5 - a) - (6 + (array[2 * (a + 1)] - a) * 4);

    return 0;
}