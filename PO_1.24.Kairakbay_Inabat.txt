using System;

namespace ConsoleApp4
{
    internal class Program
    {
        static void Main(string[] args)
        {
            // Exercise 1
            Console.WriteLine("Exercise 1:");
            Console.Write("Enter the first number: ");
            double num1 = Convert.ToDouble(Console.ReadLine());
            Console.Write("Enter the second number: ");
            double num2 = Convert.ToDouble(Console.ReadLine());
            if (num1 == num2)
                Console.WriteLine("The numbers are equal");
            else if (num1 > num2)
                Console.WriteLine("The first number is greater than the second");
            else
                Console.WriteLine("The second number is greater than the first");
            Console.WriteLine();

            // Exercise 2
            Console.WriteLine("Exercise 2:");
            Console.Write("Enter a number: ");
            double num3 = Convert.ToDouble(Console.ReadLine());
            if (num3 > 5 && num3 < 10)
                Console.WriteLine("The number is greater than 5 and less than 10");
            else
                Console.WriteLine("Unknown number");
            Console.WriteLine();

            // Exercise 3
            Console.WriteLine("Exercise 3:");
            Console.Write("Enter a number: ");
            double num4 = Convert.ToDouble(Console.ReadLine());
            if (num4 == 5 || num4 == 10)
                Console.WriteLine("The number is either 5 or 10");
            else
                Console.WriteLine("Unknown number");
            Console.WriteLine();

            // Exercise 4
            Console.WriteLine("Exercise 4:");
            Console.Write("Enter deposit amount: ");
            double deposit = Convert.ToDouble(Console.ReadLine());
            double interestRate = 0;
            if (deposit < 100)
                interestRate = 0.05;
            else if (deposit >= 100 && deposit <= 200)
                interestRate = 0.07;
            else
                interestRate = 0.10;
            double finalAmount = deposit + deposit * interestRate;
            Console.WriteLine($"Deposit amount including interest: {finalAmount}");
            Console.WriteLine();

            // Exercise 5
            Console.WriteLine("Exercise 5:");
            double bonus = 15;
            finalAmount += bonus;
            Console.WriteLine($"Deposit amount including interest and bonus: {finalAmount}");
            Console.WriteLine();

            // Exercise 6
            Console.WriteLine("Exercise 6:");
            Console.WriteLine("Enter operation number: 1.Addition 2.Subtraction 3.Multiplication");
            int oper = Convert.ToInt32(Console.ReadLine());
            switch (oper)
            {
                case 1:
                    Console.WriteLine("Addition");
                    break;
                case 2:
                    Console.WriteLine("Subtraction");
                    break;
                case 3:
                    Console.WriteLine("Multiplication");
                    break;
                default:
                    Console.WriteLine("Operation is undefined");
                    break;
            }
            Console.WriteLine();

            // Exercise 7
            Console.WriteLine("Exercise 7:");
            Console.Write("Enter operation number: 1.Addition 2.Subtraction 3.Multiplication: ");
            int op2 = Convert.ToInt32(Console.ReadLine());
            Console.Write("Enter the first number: ");
            double a = Convert.ToDouble(Console.ReadLine());
            Console.Write("Enter the second number: ");
            double b = Convert.ToDouble(Console.ReadLine());

            switch (op2)
            {
                case 1:
                    Console.WriteLine($"Result: {a + b}");
                    break;
                case 2:
                    Console.WriteLine($"Result: {a - b}");
                    break;
                case 3:
                    Console.WriteLine($"Result: {a * b}");
                    break;
                default:
                    Console.WriteLine("Operation is undefined");
                    break;
            }

            Console.WriteLine("\nAll exercises completed.");
        }
    }
}