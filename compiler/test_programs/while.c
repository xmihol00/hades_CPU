
int main()
{
    int a = 0;
    int iterator = 20;
    while (a < 10)
    {
        while (iterator > 0)
        {
            int a = 5;
            iterator = iterator - a;
        }
        a = a + 1;
    }
    return a;
}