
int add(int a, int b)
{
    return a + b;
}

int mull_add(int x, int y, int z)
{
    return x * y + z;
}

int negate(int value)
{
    return -value;
}

int main()
{
    int a = add(1 + 3 * 4, 2);
    int b = a - add(1, 2);
    int c = add(b, b) - (add(b, a) * add(a, a)) + negate(a + b);
    int d = add((a - b - (c - (5 & 6) + a)) * c, 2 + (a + b + c));
    return d;
}
