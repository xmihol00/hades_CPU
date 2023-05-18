
int main()
{
    int a = 0;
    for (int i = 0; i < 10; i = i + 1)
    {
        int i = 0;
        a = a + 1;
    }

    for (int i = 0; i < 10; i = i + 1)
    {
        a = a + 1;
        break;
    }

    return a;
}