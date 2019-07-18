using System;

namespace crashingapp
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello World!");
            throw new InvalidOperationException("booooo");
        }
    }
}
