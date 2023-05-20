
int function1() 
{
    return 1;
}

int function2(int a) 
{
    return a + 2;
}

int function3(int a, int b) 
{
    int c = a + b;
    return c + 3;
}

int main() 
{
    int a = function1();
    int b = function2(a);
    int c = function3(a, b);
    return c;
}
