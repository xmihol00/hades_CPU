#include "stdbool.h"

int fibonacci(int n)
{
    if (n < 2)
    {
        return n;
    }
    else
    {
        return fibonacci(n - 1) + fibonacci(n - 2);
    }
}

int main()
{
    while (true)
    {
        int prompt[17];
        prompt[0] = 'E';
        prompt[1] = 'n';
        prompt[2] = 't';
        prompt[3] = 'e';
        prompt[4] = 'r';
        prompt[5] = ' ';
        prompt[6] = 'a';
        prompt[7] = ' ';
        prompt[8] = 'n';
        prompt[9] = 'u';
        prompt[10] = 'm';
        prompt[11] = 'b';
        prompt[12] = 'e';
        prompt[13] = 'r';
        prompt[14] = ':';
        prompt[15] = ' ';
        prompt[16] = '\0';

        print(prompt);
        int number = getnum();
        putnum(number);
        putchar('\n');

        int result = fibonacci(number);
        prompt[0] = 'F';
        prompt[1] = '_';
        prompt[2] = '\0';
        print(prompt);
        putnum(number);
        prompt[0] = ' ';
        prompt[1] = '=';
        prompt[2] = ' ';
        prompt[3] = '\0';
        print(prompt);
        putnum(result);
        putchar('\n');
    }

    return 0;
}
