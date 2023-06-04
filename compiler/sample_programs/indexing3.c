
int main()
{
    int array[26];
    int tuple[3];
    tuple[0] = 1;
    tuple[1] = 2;
    
    for (int i = 0; i < 26; i = i + 1)
    {
        if (i < 13)
        {
            array[i] = i + 'A';
        }
        else
        {
            array[i] = i + 'a' - 13;
        }
    }

    for (int i = 2; i < 28; i = i + 1)
    {
        putchar(array[i - 2]);
    }

    int a = 3;
    tuple[(tuple[1] - tuple[0]) * a] = '#'; 
    putchar('\x0A');
    putchar(tuple[(tuple[1] - tuple[0]) * a]);
    putchar('\n');

    return 0;
}