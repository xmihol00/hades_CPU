#include <stdbool.h>

int main()
{
    int enter_number_message[15];
    enter_number_message[0] = 'E'; enter_number_message[1] = 'n'; enter_number_message[2] = 't'; enter_number_message[3] = 'e'; enter_number_message[4] = 'r'; enter_number_message[5] = ' '; enter_number_message[6] = 'n'; enter_number_message[7] = 'u'; enter_number_message[8] = 'm'; enter_number_message[9] = 'b'; enter_number_message[10] = 'e'; enter_number_message[11] = 'r'; enter_number_message[12] = ':'; enter_number_message[13] = '\n'; enter_number_message[14] = 0;
    int number_is_too_large_message[22];
    number_is_too_large_message[0] = 'N'; number_is_too_large_message[1] = 'u'; number_is_too_large_message[2] = 'm'; number_is_too_large_message[3] = 'b'; number_is_too_large_message[4] = 'e'; number_is_too_large_message[5] = 'r'; number_is_too_large_message[6] = ' '; number_is_too_large_message[7] = 'i'; number_is_too_large_message[8] = 's'; number_is_too_large_message[9] = ' '; number_is_too_large_message[10] = 't'; number_is_too_large_message[11] = 'o'; number_is_too_large_message[12] = 'o'; number_is_too_large_message[13] = ' '; number_is_too_large_message[14] = 'l'; number_is_too_large_message[15] = 'a'; number_is_too_large_message[16] = 'r'; number_is_too_large_message[17] = 'g'; number_is_too_large_message[18] = 'e'; number_is_too_large_message[19] = '!'; number_is_too_large_message[20] = '\n'; number_is_too_large_message[21] = 0; 

    while (true)
    {
        print(enter_number_message);
        int number = getnum();
        putnum(number);
        putchar('\n');
        if (number > 9999)
        {
            print(number_is_too_large_message);
        }
        else
        {
            display_number(number);
        }
    }
}
