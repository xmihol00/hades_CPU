
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
    int fib5 = fibonacci(5);
    int fib6 = fibonacci(6);
    putchar(fib6 + '0');
    putchar('\n');

    putnum(fibonacci(10));
    putchar('\n');

    return fib5 + fib6;
}
