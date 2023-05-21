
int main()
{
    int a;
    int b;

    if (a + 5 > b - 6)
    {
        a = 2 * b - a;
    }

    if (a > b)
    {
        if (a + b > 10)
        {
            int c = a + b;
            return c;
        }
        else
        {
            int c = a - b;
            return c;
        }
        a = 2 * b - a;
    }
    else if (a < b)
    {
        return b;
    }
    else if (a == b)
    {
        return 1;
    }
    else
    {
        return 0;
    }

    return a;
}
