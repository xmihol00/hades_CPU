
int print1(int *string)
{
    int i = 0;
    while (string[i] != 0)
    {
        putchar(string[i]);
        i = i + 1;
    }
    return 0;
}

int print2(int *string)
{
    while (*string != 0)
    {
        putchar(*string);
        string = string + 1;
    }
    return 0;
}

int main()
{
    int string[14];
    string[0] = 'H';
    string[1] = 'e';
    string[2] = 'l';
    string[3] = 'l';
    string[4] = 'o';
    string[5] = ' ';
    string[6] = 'W';
    string[7] = 'o';
    string[8] = 'r';
    string[9] = 'l';
    string[10] = 'd';
    string[11] = '!';
    string[12] = '\n';
    string[13] = 0;

    print1(string);
    print2(string);

    return 0;
}