using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;


namespace GrailsortTester
{
    [Serializable]
    [TypeForwardedFrom("mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")]
    internal
    /*
* MIT License
* 
* Copyright (c) 2013 Andrey Astrelin
* Copyright (c) 2021 The Holy Grail Sort Project
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

    /*
     * The Holy Grail Sort Project
     * Project Manager:      Summer Dragonfly
     * Project Contributors: 666666t
     *                       Anonymous0726
     *                       aphitorite
     *                       Control
     *                       dani_dlg
     *                       DeveloperSort
     *                       EilrahcF
     *                       Enver
     *                       Gaming32
     *                       lovebuny
     *                       Morwenn
     *                       MP
     *                       phoenixbound
     *                       Spex_guy
     *                       thatsOven
     *                       _fluffyy
     *                       AceOfSpadesProduc100
     *
     * Special thanks to "The Studio" Discord community!
     */

    // REWRITTEN GRAILSORT FOR C# - A heavily refactored C/C++-to-Java-to-C# version of
    //                                Andrey Astrelin's GrailSort.h, aiming to be as
    //                                readable and intuitive as possible.
    //
    // ** Written and maintained by The Holy Grail Sort Project
    //
    // Primary author: Summer Dragonfly, with the incredible aid from the rest of
    //                 the team mentioned throughout this file!
    //
    // Editor: AceOfSpadesProduc100, from DeveloperSort's Java version
    //
    // Current status: Changed from object to angle bracket generics in 4/28/2022. Only ints tested.

    //Credit to phoenixbound for this clever idea
    enum Subarray
    {
        LEFT,
        RIGHT
    }
#nullable enable
    public class GrailSort<K>
    {
        private int currBlockLen;
        private Subarray currBlockOrigin;



        public readonly IComparer<K> cmp;

        public GrailSort(IComparer<K> cmp)
        {
            this.cmp = cmp;
        }

        private static void GrailSwap(K[] array, int a, int b)
        {
            (array[b], array[a]) = (array[a], array[b]);
            Program.swaps++;
        }

        private static void GrailBlockSwap(K[] array, int a, int b, int blockLen)
        {
            for (int i = 0; i < blockLen; i++)
            {
                GrailSwap(array, a + i, b + i);
            }
        }

        // Swaps the order of two adjacent blocks whose lengths may or may not be equal.
        // Variant of the Gries-Mills algorithm, which is basically recursive block swaps.
        private static void GrailRotate(K[] array, int start, int leftLen, int rightLen)
        {
            while (leftLen > 0 && rightLen > 0)
            {
                if (leftLen <= rightLen)
                {
                    GrailBlockSwap(array, start, start + leftLen, leftLen);
                    start += leftLen;
                    rightLen -= leftLen;
                }
                else
                {
                    GrailBlockSwap(array, start + leftLen - rightLen, start + leftLen, rightLen);
                    leftLen -= rightLen;
                }
            }
        }


        // Variant of Insertion Sort that utilizes swaps instead of overwrites.
        // Also known as "Optimized Gnomesort".
        private static void GrailInsertSort(K[] array, int start, int length, IComparer<K> cmp)
        {
            for (int item = 1; item < length; item++)
            {
                int left = start + item - 1;
                int right = start + item;

                while (left >= start && cmp.Compare(array[left],
                                                   array[right]) > 0)
                {
                    GrailSwap(array, left, right);
                    left--;
                    right--;
                }
            }
        }


        private static int GrailBinarySearchLeft(K[] array, int start, int length, K target, IComparer<K> cmp)
        {
            int left = 0;
            int right = length;

            while (left < right)
            {
                // equivalent to (left + right) / 2 with added overflow protection
                int middle = left + ((right - left) / 2);

                if (cmp.Compare(array[start + middle], target) < 0)
                {
                    left = middle + 1;
                }
                else
                {
                    right = middle;
                }
            }
            return left;
        }

        // Credit to Anonymous0726 for debugging
        private static int GrailBinarySearchRight(K[] array, int start, int length, K target, IComparer<K> cmp)
        {
            int left = 0;
            int right = length;

            while (left < right)
            {
                // equivalent to (left + right) / 2 with added overflow protection
                int middle = left + ((right - left) / 2);

                if (cmp.Compare(array[start + middle], target) > 0)
                {
                    right = middle;
                }
                else
                {
                    left = middle + 1;
                }
            }
            return right;
        }


        // cost: 2 * length + idealKeys^2 / 2
        private static int GrailCollectKeys(K[] array, int start, int length, int idealKeys, IComparer<K> cmp)
        {
            int keysFound = 1; // by itself, the first item in the array is our first unique key
            int firstKey = 0; // the first item in the array is at the first position in the array
            int currKey = 1; // the index used for finding potentially unique items ("keys") in the array

            while (currKey < length && keysFound < idealKeys)
            {

                // Find the location in the key-buffer where our current key can be inserted in sorted order.
                // If the key at insertPos is equal to currKey, then currKey isn't unique and we move on.
                int insertPos = GrailBinarySearchLeft(array, start + firstKey, keysFound, array[start + currKey], cmp);

                // The second part of this conditional does the equal check we were just talking about; however,
                // if currKey is larger than everything in the key-buffer (meaning insertPos == keysFound),
                // then that also tells us it wasn't equal to anything in the key-buffer. 
                if (insertPos == keysFound || cmp.Compare(array[start + currKey],
                                                         array[start + firstKey + insertPos]) != 0)
                {

                    // Rotate the key-buffer over to currKey's immediate left...
                    // (this helps save a ton of swaps/writes.)
                    GrailRotate(array, start + firstKey, keysFound, currKey - (firstKey + keysFound));

                    firstKey = currKey - keysFound;

                    // Insert currKey to its spot in the key-buffer.
                    GrailRotate(array, start + firstKey + insertPos, keysFound - insertPos, 1);

                    keysFound++;
                }
                // Test the next key
                currKey++;
            }

            // Bring however many keys we found back to the beginning of our array,
            // and return the number of keys collected.
            GrailRotate(array, start, firstKey, keysFound);
            return keysFound;
        }


        private static void GrailPairwiseSwaps(K[] array, int start, int length, IComparer<K> cmp)
        {
            int index;
            for (index = 1; index < length; index += 2)
            {
                int leftt = start + index - 1;
                int right = start + index;

                if (cmp.Compare(array[leftt], array[right]) > 0)
                {
                    GrailSwap(array, leftt - 2, right);
                    GrailSwap(array, right - 2, leftt);
                }
                else
                {
                    GrailSwap(array, leftt - 2, leftt);
                    GrailSwap(array, right - 2, right);
                }
            }

            int left = start + index - 1;
            if (left < start + length)
            {
                GrailSwap(array, left - 2, left);
            }
        }


        // array[buffer .. start - 1] <=> "scrolling buffer"
        // 
        // "scrolling buffer" + array[start, middle - 1] + array[middle, end - 1]
        // --> array[buffer, buffer + end - 1] + "scrolling buffer"
        private static void GrailMergeForwards(K[] array, int start, int leftLen, int rightLen,
                                                              int bufferOffset, IComparer<K> cmp)
        {
            int buffer = start - bufferOffset;
            int left = start;
            int middle = start + leftLen;
            int right = middle;
            int end = middle + rightLen;

            while (right < end)
            {
                if (left == middle || cmp.Compare(array[left],
                                                 array[right]) > 0)
                {
                    GrailSwap(array, buffer, right);
                    right++;
                }
                else
                {
                    GrailSwap(array, buffer, left);
                    left++;
                }
                buffer++;
            }

            if (buffer != left)
            {
                GrailBlockSwap(array, buffer, left, middle - left);
            }
        }

        // credit to 666666t for thorough bug-checking/fixing
        private static void GrailMergeBackwards(K[] array, int start, int leftLen, int rightLen,
                                                               int bufferOffset, IComparer<K> cmp)
        {
            int end = start - 1;
            int left = end + leftLen;
            int middle = left;
            int right = middle + rightLen;
            int buffer = right + bufferOffset;

            while (left > end)
            {
                if (right == middle || cmp.Compare(array[left],
                                                  array[right]) > 0)
                {
                    GrailSwap(array, buffer, left);
                    left--;
                }
                else
                {
                    GrailSwap(array, buffer, right);
                    right--;
                }
                buffer--;
            }

            if (right != buffer)
            {
                while (right > middle)
                {
                    GrailSwap(array, buffer, right);
                    buffer--;
                    right--;
                }
            }
        }

        private static void GrailBuildInPlace(K[] array, int start, int length, int currentLen, int bufferLen, IComparer<K> cmp)
        {
            for (int mergeLen = currentLen; mergeLen < bufferLen; mergeLen *= 2)
            {
                int fullMergee = 2 * mergeLen;

                int mergeIndex;
                int mergeEnd = start + length - fullMergee;
                int bufferOffset = mergeLen;

                for (mergeIndex = start; mergeIndex <= mergeEnd; mergeIndex += fullMergee)
                {
                    GrailMergeForwards(array, mergeIndex, mergeLen, mergeLen, bufferOffset, cmp);
                }

                int leftOver = length - (mergeIndex - start);

                if (leftOver > mergeLen)
                {
                    GrailMergeForwards(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset, cmp);
                }
                else
                {
                    GrailRotate(array, mergeIndex - mergeLen, mergeLen, leftOver);
                }

                start -= mergeLen;
            }

            int fullMerge = 2 * bufferLen;
            int lastBlock = length & (fullMerge - 1); // Length % fullMerge
            int lastOffset = start + length - lastBlock;

            if (lastBlock <= bufferLen)
            {
                GrailRotate(array, lastOffset, lastBlock, bufferLen);
            }
            else
            {
                GrailMergeBackwards(array, lastOffset, bufferLen, lastBlock - bufferLen, bufferLen, cmp);
            }

            for (int mergeIndex = lastOffset - fullMerge; mergeIndex >= start; mergeIndex -= fullMerge)
            {
                GrailMergeBackwards(array, mergeIndex, bufferLen, bufferLen, bufferLen, cmp);
            }
        }


        // build blocks of length 'bufferLen'
        // input: [start - mergeLen, start - 1] elements are buffer
        // output: first 'bufferLen' elements are buffer, blocks (2 * bufferLen) and last subblock sorted
        private static void GrailBuildBlocks(K[] array, int start, int length, int bufferLen, IComparer<K> cmp)
        {
            GrailPairwiseSwaps(array, start, length, cmp);
            GrailBuildInPlace(array, start - 2, length, 2, bufferLen, cmp);
        }


        // Returns the final position of 'medianKey'.
        // MINOR CHANGES: Change comparison order to emphasize "less-than" relation; fewer variables (Credit to Anonymous0726 for better variable names!)
        private static int GrailBlockSelectSort(K[] array, int firstKey, int start, int medianKey,
                                                               int blockCount, int blockLen, IComparer<K> cmp)
        {
            for (int firstBlock = 0; firstBlock < blockCount; firstBlock++)
            {
                int selectBlock = firstBlock;

                for (int currBlock = firstBlock + 1; currBlock < blockCount; currBlock++)
                {
                    int compare = cmp.Compare(array[start + (currBlock * blockLen)],
                                              array[start + (selectBlock * blockLen)]);

                    if (compare < 0 || (compare == 0 && cmp.Compare(array[firstKey + currBlock],
                                                                   array[firstKey + selectBlock]) < 0))
                    {
                        selectBlock = currBlock;
                    }
                }

                if (selectBlock != firstBlock)
                {
                    GrailBlockSwap(array, start + (firstBlock * blockLen), start + (selectBlock * blockLen), blockLen);
                    GrailSwap(array, firstKey + firstBlock, firstKey + selectBlock);

                    // Follow the 'medianKey' if it was swapped.

                    // ORIGINAL LOC: if(midkey==u-1 || midkey==p) midkey^=(u-1)^p;
                    // Credits to lovebuny for figuring this one out.
                    if (medianKey == firstBlock)
                    {
                        medianKey = selectBlock;
                    }
                    else if (medianKey == selectBlock)
                    {
                        medianKey = firstBlock;
                    }
                }
            }

            return medianKey;
        }


        // Swaps Grailsort's "scrolling buffer" from the right side of the array all the way back to 'start'.
        // Costs O(n) swaps.
        //
        // Credit to 666666t for debugging
        private static void GrailInPlaceBufferReset(K[] array, int start, int length, int bufferOffset)
        {
            int buffer = start + length - 1;
            int index = buffer - bufferOffset;

            while (buffer >= start)
            {
                GrailSwap(array, index, buffer);
                buffer--;
                index--;
            }
        }

        // Rewinds Grailsort's "scrolling buffer" to the left of any items belonging to the left subarray block
        // left over by a "smart merge". This is used to continue an ongoing merge that has run out of buffer space.
        // Costs O(sqrt n) swaps in the *absolute* worst-case. 
        //
        // BETTER ORDER-OF-OPERATIONS, NAMING IMPROVED: the leftover items (leftBlock) are in the
        //                                              middle of the merge while the buffer is at the end
        private static void GrailInPlaceBufferRewind(K[] array, int start, int leftBlock, int buffer)
        {
            while (leftBlock >= start)
            {
                GrailSwap(array, buffer, leftBlock);
                leftBlock--;
                buffer--;
            }
        }

        private static Subarray GrailGetSubarray(K[] array, int currentKey, int medianKey, IComparer<K> cmp)
        {
            if (cmp.Compare(array[currentKey], array[medianKey]) < 0)
            {
                return Subarray.LEFT;
            }
            else
            {
                return Subarray.RIGHT;
            }
        }


        // Last/final left blocks are used to calculate the length of the final merge
        private static int GrailCountLastMergeBlocks(K[] array, int offset, int blockCount, int blockLen, IComparer<K> cmp)
        {
            int blocksToMerge = 0;

            int lastRightFrag = offset + (blockCount * blockLen);
            int prevLeftBlock = lastRightFrag - blockLen;

            while (blocksToMerge < blockCount && cmp.Compare(array[lastRightFrag],
                                                            array[prevLeftBlock]) < 0)
            {
                blocksToMerge++;
                prevLeftBlock -= blockLen;
            }

            return blocksToMerge;
        }


        private void GrailSmartMerge(K[] array, int start, int leftLen, Subarray leftOrigin,
                                                           int rightLen, int bufferOffset,
                                                           IComparer<K> cmp)
        {
            int buffer = start - bufferOffset;
            int left = start;
            int middle = start + leftLen;
            int right = middle;
            int end = middle + rightLen;

            if (leftOrigin == Subarray.LEFT)
            {
                while (left < middle && right < end)
                {
                    if (cmp.Compare(array[left], array[right]) <= 0)
                    {
                        GrailSwap(array, buffer, left);
                        left++;
                    }
                    else
                    {
                        GrailSwap(array, buffer, right);
                        right++;
                    }
                    buffer++;
                }
            }
            else
            {
                while (left < middle && right < end)
                {
                    if (cmp.Compare(array[left], array[right]) < 0)
                    {
                        GrailSwap(array, buffer, left);
                        left++;
                    }
                    else
                    {
                        GrailSwap(array, buffer, right);
                        right++;
                    }
                    buffer++;
                }
            }

            if (left < middle)
            {
                currBlockLen = middle - left;
                GrailInPlaceBufferRewind(array, left, middle - 1, end - 1);
            }
            else
            {
                currBlockLen = end - right;
                if (leftOrigin == Subarray.LEFT)
                {
                    currBlockOrigin = Subarray.RIGHT;
                }
                else
                {
                    currBlockOrigin = Subarray.LEFT;
                }
            }
        }

        private void GrailSmartLazyMerge(K[] array, int start, int leftLen, Subarray leftOrigin, int rightLen, IComparer<K> cmp)
        {
            int middle = start + leftLen;

            if (leftOrigin == Subarray.LEFT)
            {
                if (cmp.Compare(array[middle - 1], array[middle]) > 0)
                {
                    while (leftLen != 0)
                    {
                        int mergeLen = GrailBinarySearchLeft(array, middle, rightLen, array[start], cmp);

                        if (mergeLen != 0)
                        {
                            GrailRotate(array, start, leftLen, mergeLen);

                            start += mergeLen;
                            middle += mergeLen;
                            rightLen -= mergeLen;
                        }

                        if (rightLen == 0)
                        {
                            currBlockLen = leftLen;
                            return;
                        }
                        else
                        {
                            do
                            {
                                start++;
                                leftLen--;
                            } while (leftLen != 0 && cmp.Compare(array[start],
                                                                array[middle]) <= 0);
                        }
                    }
                }
            }
            else
            {
                if (cmp.Compare(array[middle - 1], array[middle]) >= 0)
                {
                    while (leftLen != 0)
                    {
                        int mergeLen = GrailBinarySearchRight(array, middle, rightLen, array[start], cmp);

                        if (mergeLen != 0)
                        {
                            GrailRotate(array, start, leftLen, mergeLen);

                            start += mergeLen;
                            middle += mergeLen;
                            rightLen -= mergeLen;
                        }

                        if (rightLen == 0)
                        {
                            currBlockLen = leftLen;
                            return;
                        }
                        else
                        {
                            do
                            {
                                start++;
                                leftLen--;
                            } while (leftLen != 0 && cmp.Compare(array[start],
                                                                array[middle]) < 0);
                        }
                    }
                }
            }

            currBlockLen = rightLen;
            if (leftOrigin == Subarray.LEFT)
            {
                currBlockOrigin = Subarray.RIGHT;
            }
            else
            {
                currBlockOrigin = Subarray.LEFT;
            }
        }

        // Credit to Anonymous0726 for better variable names such as "nextBlock"
        private void GrailMergeBlocks(K[] array, int firstKey, int medianKey, int start,
                                                 int blockCount, int blockLen, int lastMergeBlocks,
                                                 int lastLen, IComparer<K> cmp)
        {
            int buffer;

            int currBlock;
            int nextBlock = start + blockLen;

            currBlockLen = blockLen;
            currBlockOrigin = GrailGetSubarray(array, firstKey, medianKey, cmp);

            for (int keyIndex = 1; keyIndex < blockCount; keyIndex++, nextBlock += blockLen)
            {
                Subarray nextBlockOrigin;

                currBlock = nextBlock - currBlockLen;
                nextBlockOrigin = GrailGetSubarray(array, firstKey + keyIndex, medianKey, cmp);

                if (nextBlockOrigin == currBlockOrigin)
                {
                    buffer = currBlock - blockLen;

                    GrailBlockSwap(array, buffer, currBlock, currBlockLen);
                    currBlockLen = blockLen;
                }
                else
                {
                    GrailSmartMerge(array, currBlock, currBlockLen, currBlockOrigin,
                                         blockLen, blockLen, cmp);
                }
            }

            currBlock = nextBlock - currBlockLen;
            buffer = currBlock - blockLen;

            if (lastLen != 0)
            {
                if (currBlockOrigin == Subarray.RIGHT)
                {
                    GrailBlockSwap(array, buffer, currBlock, currBlockLen);

                    currBlock = nextBlock;
                    currBlockLen = blockLen * lastMergeBlocks;
                    currBlockOrigin = Subarray.LEFT;
                }
                else
                {
                    currBlockLen += blockLen * lastMergeBlocks;
                }

                GrailMergeForwards(array, currBlock, currBlockLen, lastLen, blockLen, cmp);
            }
            else
            {
                GrailBlockSwap(array, buffer, currBlock, currBlockLen);
            }
        }

        private void GrailLazyMergeBlocks(K[] array, int firstKey, int medianKey, int start,
                                                     int blockCount, int blockLen, int lastMergeBlocks,
                                                     int lastLen, IComparer<K> cmp)
        {
            int currBlock;
            int nextBlock = start + blockLen;

            currBlockLen = blockLen;
            currBlockOrigin = GrailGetSubarray(array, firstKey, medianKey, cmp);

            for (int keyIndex = 1; keyIndex < blockCount; keyIndex++, nextBlock += blockLen)
            {
                Subarray nextBlockOrigin;

                currBlock = nextBlock - currBlockLen;
                nextBlockOrigin = GrailGetSubarray(array, firstKey + keyIndex, medianKey, cmp);

                if (nextBlockOrigin == currBlockOrigin)
                {
                    currBlockLen = blockLen;
                }
                else
                {
                    // These checks were included in the original code, but why?
                    if (blockLen != 0 && currBlockLen != 0)
                    {
                        GrailSmartLazyMerge(array, currBlock, currBlockLen, currBlockOrigin,
                                                 blockLen, cmp);
                    }
                }
            }

            currBlock = nextBlock - currBlockLen;

            if (lastLen != 0)
            {
                if (currBlockOrigin == Subarray.RIGHT)
                {
                    currBlock = nextBlock;
                    currBlockLen = blockLen * lastMergeBlocks;
                    currBlockOrigin = Subarray.LEFT;
                }
                else
                {
                    currBlockLen += blockLen * lastMergeBlocks;
                }

                GrailLazyMerge(array, currBlock, currBlockLen, lastLen, cmp);
            }
        }

        //TODO: Double-check "Merge Blocks" arguments
        private void GrailCombineInPlace(K[] array, int firstKey, int start, int length,
                                                    int subarrayLen, int blockLen,
                                                    int mergeCount, int lastSubarrays,
                                                    bool buffer)
        { //TODO: Do collisions with hanging indents like these affect readability?
            IComparer<K> cmp = this.cmp; // local variable for performance à la Timsort

            int fullMerge = 2 * subarrayLen;
            int blockCount = fullMerge / blockLen;

            for (int mergeIndex = 0; mergeIndex < mergeCount; mergeIndex++)
            {
                int offset = start + (mergeIndex * fullMerge);

                GrailInsertSort(array, firstKey, blockCount, cmp);

                int medianKey = subarrayLen / blockLen;
                medianKey = GrailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen, cmp);

                if (buffer)
                {
                    GrailMergeBlocks(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0, cmp);
                }
                else
                {
                    GrailLazyMergeBlocks(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0, cmp);
                }
            }

            // INCORRECT CONDITIONAL/PARAMETER BUG FIXED: Credit to 666666t for debugging.
            if (lastSubarrays != 0)
            {
                int offset = start + (mergeCount * fullMerge);
                blockCount = lastSubarrays / blockLen;

                GrailInsertSort(array, firstKey, blockCount + 1, cmp);

                int medianKey = subarrayLen / blockLen;
                medianKey = GrailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen, cmp);

                // MISSING BOUNDS CHECK BUG FIXED: `lastFragment` can be 0 if the last two subarrays are evenly
                //                                 divided into blocks. This prevents Grailsort from going out-of-bounds.
                int lastFragment = lastSubarrays - (blockCount * blockLen);
                int lastMergeBlocks;
                if (lastFragment != 0)
                {
                    lastMergeBlocks = GrailCountLastMergeBlocks(array, offset, blockCount, blockLen, cmp);
                }
                else
                {
                    lastMergeBlocks = 0;
                }

                int smartMerges = blockCount - lastMergeBlocks;

                //TODO: Double-check if this micro-optimization works correctly like the original
                if (smartMerges == 0)
                {
                    int leftLen = lastMergeBlocks * blockLen;

                    if (buffer)
                    {
                        GrailMergeForwards(array, offset, leftLen, lastFragment, blockLen, cmp);
                    }
                    else
                    {
                        GrailLazyMerge(array, offset, leftLen, lastFragment, cmp);
                    }
                }
                else
                {
                    if (buffer)
                    {
                        GrailMergeBlocks(array, firstKey, firstKey + medianKey, offset,
                                              smartMerges, blockLen, lastMergeBlocks, lastFragment, cmp);
                    }
                    else
                    {
                        GrailLazyMergeBlocks(array, firstKey, firstKey + medianKey, offset,
                                                  smartMerges, blockLen, lastMergeBlocks, lastFragment, cmp);
                    }
                }
            }

            if (buffer)
            {
                GrailInPlaceBufferReset(array, start, length, blockLen);
            }
        }


        // 'keys' are on the left side of array. Blocks of length 'subarrayLen' combined. We'll combine them in pairs
        // 'subarrayLen' is a power of 2. (2 * subarrayLen / blockLen) keys are guaranteed
        //
        // IMPORTANT RENAME: 'lastSubarray' is now 'lastSubarrays' because it includes the length of the last left
        //                   subarray AND last right subarray (if there is a right subarray at all).
        //
        //                   Please also check everything surrounding 'if(lastSubarrays != 0)' inside
        //                   'combine in-/out-of-place' methods for other renames.
        private void GrailCombineBlocks(K[] array, int firstKey, int start, int length,
                                                   int subarrayLen, int blockLen, bool buffer)
        {
            int fullMerge = 2 * subarrayLen;
            int mergeCount = length / fullMerge;
            int lastSubarrays = length - (fullMerge * mergeCount);

            if (lastSubarrays <= subarrayLen)
            {
                length -= lastSubarrays;
                lastSubarrays = 0;
            }

            // INCOMPLETE CONDITIONAL BUG FIXED: In order to combine blocks out-of-place, we must check if a full-sized
            //                                   block fits into our external buffer.
            //if (buffer && blockLen <= this.extBufferLen)
            //{
            //    this.GrailCombineOutOfPlace(array, firstKey, start, length, subarrayLen, blockLen,
            //                                mergeCount, lastSubarrays);
            //}
            //else
            //{
            GrailCombineInPlace(array, firstKey, start, length, subarrayLen, blockLen,
                                     mergeCount, lastSubarrays, buffer);
            //}
        }


        // "Classic" in-place merge sort using binary searches and rotations
        //
        // cost: min(leftLen, rightLen)^2 + max(leftLen, rightLen)
        // MINOR CHANGES: better naming -- 'insertPos' is now 'mergeLen' -- and "middle"/"end" calculations simplified
        private static void GrailLazyMerge(K[] array, int start, int leftLen, int rightLen, IComparer<K> cmp)
        {
            if (leftLen < rightLen)
            {
                int middle = start + leftLen;

                while (leftLen != 0)
                {
                    int mergeLen = GrailBinarySearchLeft(array, middle, rightLen, array[start], cmp);

                    if (mergeLen != 0)
                    {
                        GrailRotate(array, start, leftLen, mergeLen);

                        start += mergeLen;
                        middle += mergeLen;
                        rightLen -= mergeLen;
                    }

                    if (rightLen == 0)
                    {
                        break;
                    }
                    else
                    {
                        do
                        {
                            start++;
                            leftLen--;
                        } while (leftLen != 0 && cmp.Compare(array[start],
                                                            array[middle]) <= 0);
                    }
                }
            }
            // INDEXING BUG FIXED: Credit to Anonymous0726 for debugging.
            else
            {
                int end = start + leftLen + rightLen - 1;

                while (rightLen != 0)
                {
                    int mergeLen = GrailBinarySearchRight(array, start, leftLen, array[end], cmp);

                    if (mergeLen != leftLen)
                    {
                        GrailRotate(array, start + mergeLen, leftLen - mergeLen, rightLen);

                        end -= leftLen - mergeLen;
                        leftLen = mergeLen;
                    }

                    if (leftLen == 0)
                    {
                        break;
                    }
                    else
                    {
                        int middle = start + leftLen;
                        do
                        {
                            rightLen--;
                            end--;
                        } while (rightLen != 0 && cmp.Compare(array[middle - 1],
                                                             array[end]) <= 0);
                    }
                }
            }
        }

        private static void GrailLazyStableSort(K[] array, int start, int length, IComparer<K> cmp)
        {
            for (int index = 1; index < length; index += 2)
            {
                int left = start + index - 1;
                int right = start + index;

                if (cmp.Compare(array[left], array[right]) > 0)
                {
                    GrailSwap(array, left, right);
                }
            }
            for (int mergeLen = 2; mergeLen < length; mergeLen *= 2)
            {
                int fullMerge = 2 * mergeLen;

                int mergeIndex;
                int mergeEnd = length - fullMerge;

                for (mergeIndex = 0; mergeIndex <= mergeEnd; mergeIndex += fullMerge)
                {
                    GrailLazyMerge(array, start + mergeIndex, mergeLen, mergeLen, cmp);
                }

                int leftOver = length - mergeIndex;
                if (leftOver > mergeLen)
                {
                    GrailLazyMerge(array, start + mergeIndex, mergeLen, leftOver - mergeLen, cmp);
                }
            }
        }


        // Calculates the minimum between numKeys and cbrt(2 * subarrayLen * keysFound).
        // Math will be further explained later, but just like in grailCommonSort, this
        // loop is rendered completely useless by the scrolling buffer optimization;
        // minKeys will always equal numKeys.
        //
        // Code still here for preservation purposes.
        /*
         * private static int grailCalcMinKeys(int numKeys, long subarrayKeys) {
         *     int minKeys = 1;
         *     while(minKeys < numKeys && subarrayKeys != 0) {
         *         minKeys      *= 2;
         *         subarrayKeys /= 8;
         *     }
         *     return minKeys; 
         * }
         */


        public void GrailCommonSort(K[] array, int start, int length)
        {
            if (length < 16)
            {
                GrailInsertSort(array, start, length, cmp);
                return;
            }

            int blockLen = 1;

            while ((blockLen * blockLen) < length)
            {
                blockLen <<= 1;
            }

            // '((a - 1) / b) + 1' is a clever and very efficient
            // formula for the ceiling of (a / b)
            //
            // credit to Anonymous0726 for figuring this out!
            int keyLen = ((length - 1) / blockLen) + 1;

            // Grailsort is hoping to find `2 * sqrt(n)` unique items
            // throughout the array
            int idealKeys = keyLen + blockLen;

            //TODO: Clean up `start +` offsets
            int keysFound = GrailCollectKeys(array, start, length, idealKeys, cmp);

            bool idealBuffer;
            if (keysFound < idealKeys)
            {
                if (keysFound < 4)
                {
                    // GRAILSORT STRATEGY 3 -- No block swaps or scrolling buffer; resort to Lazy Stable Sort
                    GrailLazyStableSort(array, start, length, cmp);
                    return;
                }
                else
                {
                    // GRAILSORT STRATEGY 2 -- Block swaps with small scrolling buffer and/or lazy merges
                    keyLen = blockLen;
                    blockLen = 0;
                    idealBuffer = false;

                    while (keyLen > keysFound)
                    {
                        keyLen /= 2;
                    }
                }
            }
            else
            {
                // GRAILSORT STRATEGY 1 -- Block swaps with scrolling buffer
                idealBuffer = true;
            }

            int bufferEnd = blockLen + keyLen;
            int subarrayLen;
            if (idealBuffer)
            {
                subarrayLen = blockLen;
            }
            else
            {
                subarrayLen = keyLen;
            }

            GrailBuildBlocks(array, start + bufferEnd, length - bufferEnd, subarrayLen, cmp);

            while ((length - bufferEnd) > (2 * subarrayLen))
            {
                subarrayLen *= 2;

                int currentBlockLen = blockLen;
                bool scrollingBuffer = idealBuffer;

                // Credits to Anonymous0726, phoenixbound, and DeveloperSort for their tireless efforts
                // towards deconstructing this math.
                if (!idealBuffer)
                {
                    int keyBuffer = keyLen / 2;

                    // TODO: Rewrite explanation for this math
                    if (keyBuffer >= ((2 * subarrayLen) / keyBuffer))
                    {
                        currentBlockLen = keyBuffer;
                        scrollingBuffer = true;
                    }
                    else
                    {
                        // This is a recent discovery, and the math will be spelled out later, but this
                        // "minKeys" calculation is completely unnecessary. "minKeys" would be less than
                        // "keyLen" iff ((keyBuffer >= (2 * subarrayLen)) / keyBuffer)... but this situation
                        // is already covered by our scrolling buffer optimization right above. Consequently,
                        // "minKeys" will always be equal to "keyLen" when Grailsort resorts to smart lazy
                        // merges. Removing this loop is by itself a decent optimization, as well.
                        //
                        // Code still here for preservation purposes.
                        /*
                         * long subarrayKeys = ((long) subarrayLen * keysFound) / 2;
                         * int minKeys = grailCalcMinKeys(keyLen, subarrayKeys);
                         *
                         * currentBlockLen = (2 * subarrayLen) / minKeys;
                         */

                        currentBlockLen = (2 * subarrayLen) / keyLen;
                    }
                }

                // WRONG VARIABLE BUG FIXED: 4th argument should be `length - bufferEnd`, was `length - bufferLen` before.
                // Credit to 666666t and Anonymous0726 for debugging.
                GrailCombineBlocks(array, start, start + bufferEnd, length - bufferEnd,
                                        subarrayLen, currentBlockLen, scrollingBuffer);
            }

            GrailInsertSort(array, start, bufferEnd, cmp);
            GrailLazyMerge(array, start, bufferEnd, length - bufferEnd, cmp);
        }


        public void GrailSortInPlace(K[] array, int start, int length)
        {
            GrailCommonSort(array, start, length);
        }
    }
}
