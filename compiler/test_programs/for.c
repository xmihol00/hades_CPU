
int main()
{
    int a = 0;
    for (int i = 0; i < 10; i = i + 1)
    {
        int i = 5 + 6;
        a = a + 1;
    }

    int b = 0;
    for (int i = 0; i < 10; i = i + 1)
    {
        b = b + 1;
        break;
    }

    return a + b;
}