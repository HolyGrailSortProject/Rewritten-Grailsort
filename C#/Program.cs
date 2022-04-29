using System;
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

    internal class GrailComparator : IComparer<int>
    {
        public int comps;
        public int Compare(int x, int y)
        {
            comps++;
            return x < y ? -1 : x > y ? 1 : 0;
        }
    }


    internal static class Program
    {
        public static int swaps;
        private static void Main()
        {
            GrailComparator gc = new();
            GrailSort<int> gs = new(gc);

            int[] arr = new int[50];
            for (int i = 0; i < arr.Length; i++)
            {
                arr[i] = i;
            }
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
            Console.WriteLine("Comps: " + gc.comps);
            Console.WriteLine("Swaps: " + swaps);
            gc.comps = 0;
            swaps = 0;
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Reversed input:");
            Array.Reverse(arr);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Sorted result:");
            gs.GrailSortInPlace(arr, 0, arr.Length);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
            Console.WriteLine("Comps: " + gc.comps);
            Console.WriteLine("Swaps: " + swaps);
            gc.comps = 0;
            swaps = 0;
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Random input with few unique (divided by 5):");
            for (int i = 0; i < arr.Length; i++)
            {
                arr[i] = (i + 1) / 5;
            }
            arr.CopyTo(arr, 0);
            //Array.Copy(basearr, arr, arr.Length);
            Shuffle(rng, arr);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
            Console.WriteLine("------------------------------------------------");
            Console.WriteLine("Sorted result:");
            gs.GrailSortInPlace(arr, 0, arr.Length);
            Console.WriteLine("[{0}]", string.Join(", ", arr));
            Console.WriteLine("Comps: " + gc.comps);
            Console.WriteLine("Swaps: " + swaps);
            gc.comps = 0;
            swaps = 0;
        }

        public static void Shuffle<T>(this Random rng, T[] array)
        {
            int n = array.Length;
            while (n > 1)
            {
                int k = rng.Next(n--);
                (array[k], array[n]) = (array[n], array[k]);
            }
        }
    }
}