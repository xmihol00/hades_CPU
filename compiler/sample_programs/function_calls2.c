
int add(int a, int b)
{
    return a + b;
}

int random()
{
    return 42;
}

int main()
{
    int a = add(1 + 3 * 4, 2);
    int b = a - add(1, 2);
    int c = random();
    a = add(a, b) - random();
    b = add(random(), random()) - random();
    c = random() * add(add(a - random(), b), c) + random();
    random();
    add(random(), add(random() + 1, random() - 1));
    return add(2 + random() * (a + b + c), (a - b) * ((c + a) - ((a + a) * ((b + c) * ((c - a) * -(b + a) + (b + c))) & c) + a) * c);
}
