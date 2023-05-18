
int main(int a, int b)
{
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
    }
    else if (a < b)
    {
        return b;
    }
    else
    {
        return 0;
    }
}
