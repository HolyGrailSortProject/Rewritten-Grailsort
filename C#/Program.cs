using System;
using System.Collections;
using System.Collections.Generic;

namespace GrailsortTester
{

    // REWRITTEN GRAILSORT FOR C# - A heavily refactored C/C++-to-C# version of
    //                                Andrey Astrelin's GrailSort.h, aiming to be as
    //                                readable and intuitive as possible.
    //
    // ** Written and maintained by The Holy Grail Sort Project
    //
    // Primary author: Summer Dragonfly, with the incredible aid from the rest of
    //                 the team mentioned throughout GrailSort.cs!
    //
    // Editor: AceOfSpadesProduc100, based on DeveloperSort's Java version
    //
    // Current status: IComparers of types get conversion related errors. Only integers tested.

    class GrailComparator : IComparer
    {
        public int Compare(object x, object y)
        {
            return Convert.ToInt32(x) < Convert.ToInt32(y) ? -1 : Convert.ToInt32(x) > Convert.ToInt32(y) ? 1 : 0;
        }
    }


    internal static class Program
    {
        private static void Main()
        {
            GrailComparator gc = new();
            GrailSort gs = new(gc);
            int[] basearr = new int[50];
            object[] arr = new object[basearr.Length];
            for (int i = 0; i < basearr.Length; i++)
            {
                basearr[i] = i;
            }
            basearr.CopyTo(arr, 0);
            //Array.Copy(basearr, arr, arr.Length);
            Console.WriteLine("Testing grailsort:");
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Random input:");
            Random rng = new();
            Shuffle(rng, arr);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Sorted result:");
            gs.GrailSortInPlace(arr, 0, arr.Length);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Reversed input:");
            Array.Reverse(arr);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Sorted result:");
            gs.GrailSortInPlace(arr, 0, arr.Length);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Random input with few unique (divided by 5):");
            for (int i = 0; i < basearr.Length; i++)
            {
                basearr[i] = (i + 1) / 5;
            }
            basearr.CopyTo(arr, 0);
            //Array.Copy(basearr, arr, arr.Length);
            Shuffle(rng, arr);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Sorted result:");
            gs.GrailSortInPlace(arr, 0, arr.Length);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
        }

        public static void Shuffle<T>(this Random rng, T[] array)
        {
            int n = array.Length;
            while (n > 1)
            {
                int k = rng.Next(n--);
                T temp = array[n];
                array[n] = array[k];
                array[k] = temp;
            }
        }
    }
}