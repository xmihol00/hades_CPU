
int global_A = 1;
int global_B = 2;

int sum_globals() 
{
    return global_A + global_B;
}

int sum(int x, int y) 
{
    return x + y;
}

int largest(int x, int y, int z)
{
    if (x > y) 
    {
        if (x > z) 
        {
            return x;
        } 
        else 
        {
            return z;
        }
    } 
    else 
    {
        if (y > z) 
        {
            return y;
        } 
        else 
        {
            return z;
        }
    }
}

int main() 
{
    int a = 1;
    int b = 2;
    int c = 3;
    global_A = sum(a, b);
    global_B = largest(a, b, c);
    int f = sum_globals();
    for (int i = 65; i < 91; i = i + 1) 
    {
        putchar(i);
    }
    
    while (global_A + global_B > 0)
    {
        if (global_A > global_B)
        {
            global_A = global_A - 1;
        }
        else
        {
            global_B = global_B - 1;
        }
    }

    return 0;
}
