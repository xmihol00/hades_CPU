#include "stdbool.h"

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

        int result = div10(number);
        putnum(number);
        prompt[0] = ' ';
        prompt[1] = '/';
        prompt[2] = ' ';
        prompt[3] = '1';
        prompt[4] = '0';
        prompt[5] = ' ';
        prompt[6] = '=';
        prompt[7] = ' ';
        prompt[8] = '\0';
        print(prompt);
        putnum(result);
        putchar('\n');
    }

    return 0;
}
