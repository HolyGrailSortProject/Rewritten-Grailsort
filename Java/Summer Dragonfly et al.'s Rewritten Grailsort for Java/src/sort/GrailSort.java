package sort;

import java.lang.reflect.Array;
import java.util.Comparator;

/*
 * MIT License
 * 
 * Copyright (c) 2013 Andrey Astrelin
 * Copyright (c) 2020 The Holy Grail Sort Project
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
 *                       dani_dlg
 *                       DeveloperSort
 *                       EilrahcF
 *                       Enver
 *                       lovebuny
 *                       Morwenn
 *                       MP
 *                       phoenixbound
 *                       thatsOven
 *                       _fluffyy
 *
 * Special thanks to "The Studio" Discord community!
 */

// REWRITTEN GRAILSORT FOR JAVA - A heavily refactored C/C++-to-Java version of
//                                Andrey Astrelin's GrailSort.h, aiming to be as
//                                readable and intuitive as possible.
//
// ** Written and maintained by The Holy Grail Sort Project
//
// Primary author: Summer Dragonfly, with the incredible aid from the rest of
//                 the team mentioned throughout this file!
//
// Current status: EVERY VERSION PASSING ALL TESTS / POTENTIALLY FIXED as of
//                 10/23/20

//Credit to phoenixbound for this clever idea
enum Subarray {
    LEFT,
    RIGHT;
}

final public class GrailSort<K> {
    private Comparator<K> cmp;

    final static int GRAIL_STATIC_EXT_BUFFER_LEN = 512;

    private K[] extBuffer;
    private int extBufferLen;

    private int currBlockLen;
    private Subarray currBlockOrigin;

    public GrailSort(Comparator<K> cmp) {
        this.cmp = cmp;
    }

    private static <K> void grailSwap(K[] array, int a, int b) {
        K temp   = array[a];
        array[a] = array[b];
        array[b] = temp;
    }

    private static <K> void grailBlockSwap(K[] array, int a, int b, int blockLen) {
        for(int i = 0; i < blockLen; i++) {
            grailSwap(array, a + i, b + i);
        }
    }

    // Swaps the order of two adjacent blocks whose lengths may or may not be equal.
    // Variant of the Gries-Mills algorithm, which is basically recursive block swaps.
    private static <K> void grailRotate(K[] array, int start, int leftLen, int rightLen) {
        while(leftLen > 0 && rightLen > 0) {
            if(leftLen <= rightLen) {
                grailBlockSwap(array, start, start + leftLen, leftLen);
                start    += leftLen;
                rightLen -= leftLen;
            } 
            else {
                grailBlockSwap(array, start + leftLen - rightLen, start + leftLen, rightLen);
                leftLen  -= rightLen;
            }
        }
    }

    
    // Variant of Insertion Sort that utilizes swaps instead of overwrites.
    // Also known as "Optimized Gnomesort".
    private static <K> void grailInsertSort(K[] array, int start, int length, Comparator<K> cmp) {
        for(int item = 1; item < length; item++) {
            int  left = start + item - 1;
            int right = start + item;

            while(left >= start && cmp.compare(array[ left],
                                               array[right]) > 0) {
                grailSwap(array, left, right);
                left--;
                right--;
            }
        }
    }

    
    private static <K> int grailBinarySearchLeft(K[] array, int start, int length, K target, Comparator<K> cmp) {
        int  left = 0;
        int right = length;

        while(left < right) {
            // equivalent to (left + right) / 2 with added overflow protection
            int middle = left + ((right - left) / 2);
            
            if(cmp.compare(array[start + middle], target) < 0) {
                left = middle + 1;
            }
            else {
                right = middle;
            }
        }
        return left;
    }
    
    // Credit to Anonymous0726 for debugging
    private static <K> int grailBinarySearchRight(K[] array, int start, int length, K target, Comparator<K> cmp) {
        int  left = 0;
        int right = length;

        while(left < right) {
            // equivalent to (left + right) / 2 with added overflow protection
            int middle = left + ((right - left) / 2);
            
            if(cmp.compare(array[start + middle], target) > 0) {
                right = middle;
            }
            else {
                left = middle + 1;
            }
        }
        // OFF-BY-ONE BUG FIXED: used to be `return right - 1;`
        return right;
    }

    
    // cost: 2 * length + idealKeys^2 / 2
    private static <K> int grailCollectKeys(K[] array, int start, int length, int idealKeys, Comparator<K> cmp) {
        int keysFound = 1; // by itself, the first item in the array is our first unique key
        int  firstKey = 0; // the first item in the array is at the first position in the array
        int   currKey = 1; // the index used for finding potentially unique items ("keys") in the array

        while(currKey < length && keysFound < idealKeys) {

            // Find the location in the key-buffer where our current key can be inserted in sorted order.
            // If the key at insertPos is equal to currKey, then currKey isn't unique and we move on.
            int insertPos = grailBinarySearchLeft(array, start + firstKey, keysFound, array[start + currKey], cmp);

            // The second part of this conditional does the equal check we were just talking about; however,
            // if currKey is larger than everything in the key-buffer (meaning insertPos == keysFound),
            // then that also tells us it wasn't *equal* to anything in the key-buffer. Magic! :) 
            if(insertPos == keysFound || cmp.compare(array[start +  currKey            ],
                                                     array[start + firstKey + insertPos]) != 0) {

                // First, rotate the key-buffer over to currKey's immediate left...
                // (this helps save a TON of swaps/writes!!!)
                grailRotate(array, start + firstKey, keysFound, currKey - (firstKey + keysFound));

                // Update the new position of firstKey...
                firstKey = currKey - keysFound;

                // Then, "insertion sort" currKey to its spot in the key-buffer!
                grailRotate(array, start + firstKey + insertPos, keysFound - insertPos, 1);

                // One step closer to idealKeys.
                keysFound++;
            }
            // Move on and test the next key...
            currKey++;
        }

        // Bring however many keys we found back to the beginning of our array,
        // and return the number of keys collected.
        grailRotate(array, start, firstKey, keysFound);
        return keysFound;
    }

    
    private static <K> void grailPairwiseSwaps(K[] array, int start, int length, Comparator<K> cmp) {
        int index;
        for(index = 1; index < length; index += 2) {
            int  left = start + index - 1;
            int right = start + index;

            if(cmp.compare(array[left], array[right]) > 0) {
                grailSwap(array,  left - 2, right);
                grailSwap(array, right - 2,  left);
            }
            else {
                grailSwap(array,  left - 2,  left);
                grailSwap(array, right - 2, right);
            }
        }

        int left = start + index - 1;
        if(left < start + length) {
            grailSwap(array, left - 2, left);
        }
    }
    
    private static <K> void grailPairwiseWrites(K[] array, int start, int length, Comparator<K> cmp) {
        int index;
        for(index = 1; index < length; index += 2) {
            int  left = start + index - 1;
            int right = start + index;

            if(cmp.compare(array[left], array[right]) > 0) {
                array[ left - 2] = array[right];
                array[right - 2] = array[ left];
            }
            else {
                array[ left - 2] = array[ left];
                array[right - 2] = array[right];
            }
        }

        int left = start + index - 1;
        if(left < start + length) {
            array[left - 2] = array[left];
        }
    }

    
    // array[buffer .. start - 1] <=> "scrolling buffer"
    // 
    // "scrolling buffer" + array[start, middle - 1] + array[middle, end - 1]
    // --> array[buffer, buffer + end - 1] + "scrolling buffer"
    private static <K> void grailMergeForwards(K[] array, int start, int leftLen, int rightLen,
                                                          int bufferOffset, Comparator<K> cmp) {
        int buffer = start  - bufferOffset;
        int   left = start;
        int middle = start  +  leftLen;
        int  right = middle;
        int    end = middle + rightLen;

        while(right < end) {
            if(left == middle || cmp.compare(array[ left],
                                             array[right]) > 0) {
                grailSwap(array, buffer, right);
                right++;
            }
            else {
                grailSwap(array, buffer,  left);
                left++;
            }
            buffer++;
        }

        if(buffer != left) {
            grailBlockSwap(array, buffer, left, middle - left);
        }
    }

    // credit to 666666t for thorough bug-checking/fixing
    private static <K> void grailMergeBackwards(K[] array, int start, int leftLen, int rightLen,
                                                           int bufferOffset, Comparator<K> cmp) {
        // used to be '= start'
        int    end = start  -  1;
        int   left = start  +  leftLen - 1;
        int middle = left;
        // OFF-BY-ONE BUG FIXED: used to be `int  right = middle + rightLen - 1;`
        int  right = middle + rightLen;
        // OFF-BY-ONE BUG FIXED: used to be `int buffer = right  + bufferOffset - 1;`
        int buffer = right  + bufferOffset;

        // used to be 'left >= end'
        while(left > end) {
            if(right == middle || cmp.compare(array[ left],
                                              array[right]) > 0) {
                grailSwap(array, buffer,  left);
                left--;
            }
            else {
                grailSwap(array, buffer, right);
                right--;
            }
            buffer--;
        }

        if(right != buffer) {
            while(right > middle) {
                grailSwap(array, buffer, right);
                buffer--;
                right--;
            }
        }
    }

    // array[buffer .. start - 1] <=> "free space"    
    //
    // "free space" + array[start, middle - 1] + array[middle, end - 1]
    // --> array[buffer, buffer + end - 1] + "free space"
    //
    // FUNCTION RENAMED: More consistent with "out-of-place" being at the end
    private static <K> void grailMergeOutOfPlace(K[] array, int start, int leftLen, int rightLen,
                                                            int bufferOffset, Comparator<K> cmp) {
        int buffer = start  - bufferOffset;
        int   left = start;
        int middle = start  +  leftLen;
        int  right = middle;
        int    end = middle + rightLen;

        while(right < end) {
            if(left == middle || cmp.compare(array[ left],
                                             array[right]) > 0) {
                array[buffer] = array[right];
                right++;
            }
            else {
                array[buffer] = array[ left];
                left++;
            }
            buffer++;
        }

        if(buffer != left) {
            while(left < middle) {
                array[buffer] = array[left];
                buffer++;
                left++;
            }
        }
    }

    
    private static <K> void grailBuildInPlace(K[] array, int start, int length, int currentLen, int bufferLen, Comparator<K> cmp) {
        for(int mergeLen = currentLen; mergeLen < bufferLen; mergeLen *= 2) {
            int fullMerge = 2 * mergeLen;

            int mergeIndex;
            int mergeEnd = start + length - fullMerge;
            int bufferOffset = mergeLen;

            for(mergeIndex = start; mergeIndex <= mergeEnd; mergeIndex += fullMerge) {
                grailMergeForwards(array, mergeIndex, mergeLen, mergeLen, bufferOffset, cmp);
            }

            int leftOver = length - (mergeIndex - start);

            if(leftOver > mergeLen) {
                grailMergeForwards(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset, cmp);
            }
            else {
                grailRotate(array, mergeIndex - mergeLen, mergeLen, leftOver);
            }

            start -= mergeLen;
        }

        int fullMerge  = 2 * bufferLen; 
        int lastBlock  = length % fullMerge;
        int lastOffset = start + length - lastBlock;

        if(lastBlock <= bufferLen) {
            grailRotate(array, lastOffset, lastBlock, bufferLen);
        }
        else {
            grailMergeBackwards(array, lastOffset, bufferLen, lastBlock - bufferLen, bufferLen, cmp);
        }

        for(int mergeIndex = lastOffset - fullMerge; mergeIndex >= start; mergeIndex -= fullMerge) {
            grailMergeBackwards(array, mergeIndex, bufferLen, bufferLen, bufferLen, cmp);
        }
    }

    private void grailBuildOutOfPlace(K[] array, int start, int length, int bufferLen, int extLen, Comparator<K> cmp) {
        System.arraycopy(array, start - extLen, this.extBuffer, 0, extLen);

        grailPairwiseWrites(array, start, length, cmp);
        start -= 2;

        int mergeLen;
        for(mergeLen = 2; mergeLen < extLen; mergeLen *= 2) {
            int fullMerge = 2 * mergeLen;

            int mergeIndex;
            int mergeEnd = start + length - fullMerge;
            int bufferOffset = mergeLen;

            for(mergeIndex = start; mergeIndex <= mergeEnd; mergeIndex += fullMerge) {
                grailMergeOutOfPlace(array, mergeIndex, mergeLen, mergeLen, bufferOffset, cmp);
            }

            int leftOver = length - (mergeIndex - start);

            if(leftOver > mergeLen) {
                grailMergeOutOfPlace(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset, cmp);
            }
            else {
                // MINOR CHANGE: Used to be a loop; much clearer now
                System.arraycopy(array, mergeIndex, array, mergeIndex - mergeLen, leftOver);
            }

            start -= mergeLen;
        }

        System.arraycopy(this.extBuffer, 0, array, start + length, extLen);
        grailBuildInPlace(array, start, length, mergeLen, bufferLen, cmp);
    }

    // build blocks of length 'bufferLen'
    // input: [start - mergeLen, start - 1] elements are buffer
    // output: first 'bufferLen' elements are buffer, blocks (2 * bufferLen) and last subblock sorted
    private void grailBuildBlocks(K[] array, int start, int length, int bufferLen, Comparator<K> cmp) {
        if(this.extBuffer != null) {
            int extLen;

            if(bufferLen < this.extBufferLen) {
                extLen = bufferLen;
            }
            else {
                // max power of 2 -- just in case
                extLen = 1;
                while((extLen * 2) <= this.extBufferLen) {
                    extLen *= 2;
                }
            }

            this.grailBuildOutOfPlace(array, start, length, bufferLen, extLen, cmp);
        }
        else {
            grailPairwiseSwaps(array, start, length, cmp);
            grailBuildInPlace(array, start - 2, length, 2, bufferLen, cmp);
        }
    }

    
    // Returns the final position of 'medianKey'.
    // MINOR CHANGES: Change comparison order to emphasize "less-than" relation; fewer variables (Credit to Anonymous0726 for better variable names!)
    private static <K> int grailBlockSelectSort(K[] array, int firstKey, int start, int medianKey,
                                                           int blockCount, int blockLen, Comparator<K> cmp) {
        for(int firstBlock = 0; firstBlock < blockCount; firstBlock++) {
            int selectBlock = firstBlock;

            for(int currBlock = firstBlock + 1; currBlock < blockCount; currBlock++) {
                int compare = cmp.compare(array[start + (currBlock   * blockLen)],
                                          array[start + (selectBlock * blockLen)]);

                if(compare < 0 || (compare == 0 && cmp.compare(array[firstKey +   currBlock],
                                                               array[firstKey + selectBlock]) < 0)) {
                    selectBlock = currBlock;
                }
            }

            if(selectBlock != firstBlock) {
                // Swap the left and right selected blocks...
                grailBlockSwap(array, start + (firstBlock * blockLen), start + (selectBlock * blockLen), blockLen);

                // Swap the keys...
                grailSwap(array, firstKey + firstBlock, firstKey + selectBlock);

                // ...and follow the 'medianKey' if it was swapped

                // ORIGINAL LOC: if(midkey==u-1 || midkey==p) midkey^=(u-1)^p;
                // MASSIVE, MASSIVE credit to lovebuny for figuring this one out!
                if(medianKey == firstBlock) {
                    medianKey = selectBlock;
                }
                else if(medianKey == selectBlock) {
                    medianKey = firstBlock;
                }
            }
        }

        return medianKey;
    }

    
    // Swaps Grailsort's "scrolling buffer" from the right side of the array all the way back to 'start'.
    // Costs O(n) operations.
    //
    // OFF-BY-ONE BUG FIXED: used to be `int index = start + resetLen`; credit to 666666t for debugging
    private static <K> void grailInPlaceBufferReset(K[] array, int start, int resetLen, int bufferLen) {
        for(int index = start + resetLen - 1; index >= start; index--) {
            grailSwap(array, index, index - bufferLen);
        }
    }

    // Shifts entire array over 'bufferSize' spaces to make room for the out-of-place merging buffer.
    // Costs O(n) operations.
    //
    // OFF-BY-ONE BUG FIXED: used to be `int index = start + resetLen`; credit to 666666t for debugging
    private static <K> void grailOutOfPlaceBufferReset(K[] array, int start, int resetLen, int bufferLen) {
        for(int index = start + resetLen - 1; index >= start; index--) {
            array[index] = array[index - bufferLen];
        }
    }

    // Rewinds Grailsort's "scrolling buffer" such that any items from a left subarray block left over by a "smart merge" are moved to
    // the right of the buffer. This is used to maintain stability and to continue an ongoing merge that has run out of buffer space.
    // Costs O(sqrt n) swaps in the *absolute* worst-case. 
    //
    // NAMING IMPROVED: the left over items are in the middle of the merge while the buffer is at the end
    private static <K> void grailInPlaceBufferRewind(K[] array, int start, int leftOvers, int buffer) {
        while(leftOvers > start) {
            leftOvers--;
            buffer--;
            grailSwap(array, buffer, leftOvers);
        }
    }

    // Rewinds Grailsort's out-of-place buffer such that any items from a left subarray block left over by a "smart merge" are moved to
    // the right of the buffer. This is used to maintain stability and to continue an ongoing merge that has run out of buffer space.
    // Costs O(sqrt n) writes in the *absolute* worst-case.
    //
    // INCORRECT ORDER OF PARAMETERS BUG FIXED: `leftOvers` should be the middle, and `buffer` should be the end
    private static <K> void grailOutOfPlaceBufferRewind(K[] array, int start, int leftOvers, int buffer) {
        while(leftOvers > start) {
            leftOvers--;
            buffer--;
            array[buffer] = array[leftOvers];
        }
    }

    
    private static <K> Subarray grailGetSubarray(K[] array, int currentKey, int medianKey, Comparator<K> cmp) {
        if(cmp.compare(array[currentKey], array[medianKey]) < 0) {
            return Subarray.LEFT;
        }
        else {
            return Subarray.RIGHT;
        }
    }

    
    // FUNCTION RE-RENAMED: last/final left blocks are used to calculate the length of the final merge
    private static <K> int grailCountLastMergeBlocks(K[] array, int offset, int blockCount, int blockLen, Comparator<K> cmp) {
        int blocksToMerge = 0;

        int lastRightFrag = offset + (blockCount * blockLen);
        int prevLeftBlock = lastRightFrag - blockLen;

        while(blocksToMerge < blockCount && cmp.compare(array[lastRightFrag],
                                                        array[prevLeftBlock]) < 0) {
            blocksToMerge++;
            prevLeftBlock -= blockLen;
        }

        return blocksToMerge;
    }

    
    private void grailSmartMerge(K[] array, int start, int leftLen, Subarray leftOrigin,
                                                       int rightLen, int bufferOffset,
                                                       Comparator<K> cmp) {
        int buffer = start  - bufferOffset;
        int   left = start;
        int middle = start  +  leftLen;
        int  right = middle;
        int    end = middle + rightLen;

        if(leftOrigin == Subarray.LEFT) {
            while(left < middle && right < end) {
                if(cmp.compare(array[left], array[right]) <= 0) {
                    grailSwap(array, buffer, left);
                    left++;
                }
                else {
                    grailSwap(array, buffer, right);
                    right++;
                }
                buffer++;
            }
        }
        else {
            while(left < middle && right < end) {
                if(cmp.compare(array[left], array[right]) <  0) {
                    grailSwap(array, buffer, left);
                    left++;
                }
                else {
                    grailSwap(array, buffer, right);
                    right++;
                }
                buffer++;
            }            
        }

        if(left < middle) {
            this.currBlockLen = middle - left;
            grailInPlaceBufferRewind(array, left, middle, end);
        }
        else {
            this.currBlockLen = end - right;
            if(leftOrigin == Subarray.LEFT) {
                this.currBlockOrigin = Subarray.RIGHT;
            }
            else {
                this.currBlockOrigin = Subarray.LEFT;
            }
        }
    }

    // MINOR CHANGE: better naming -- 'insertPos' is now 'mergeLen' -- and "middle" calculation simplified
    private void grailSmartLazyMerge(K[] array, int start, int leftLen, Subarray leftOrigin, int rightLen, Comparator<K> cmp) {
        int middle = start + leftLen;
        
        if(leftOrigin == Subarray.LEFT) {
            if(cmp.compare(array[middle - 1], array[middle]) >  0) {
                while(leftLen != 0) {
                    int mergeLen = grailBinarySearchLeft(array, middle, rightLen, array[start], cmp);

                    if(mergeLen != 0) {
                        grailRotate(array, start, leftLen, mergeLen);
                        start    += mergeLen;
                        rightLen -= mergeLen;
                    }
                    
                    middle += mergeLen;
                    
                    if(rightLen == 0) {
                        this.currBlockLen = leftLen;
                        return;
                    }
                    else {
                        do {
                            start++;
                            leftLen--;
                        } while(leftLen != 0 && cmp.compare(array[start ],
                                                            array[middle]) <= 0);
                    }
                }
            }
        }
        else {
            if(cmp.compare(array[middle - 1], array[middle]) >= 0) {
                while(leftLen != 0) {
                    int mergeLen = grailBinarySearchRight(array, middle, rightLen, array[start], cmp);

                    if(mergeLen != 0) {
                        grailRotate(array, start, leftLen, mergeLen);
                        start    += mergeLen;
                        rightLen -= mergeLen;
                    }

                    middle += mergeLen;
                    
                    if(rightLen == 0) {
                        this.currBlockLen = leftLen;
                        return;
                    }
                    else {
                        do {
                            start++;
                            leftLen--;
                        } while(leftLen != 0 && cmp.compare(array[start ],
                                                            array[middle]) < 0);
                    }
                }
            }
        }

        this.currBlockLen = rightLen;
        if(leftOrigin == Subarray.LEFT) {
            this.currBlockOrigin = Subarray.RIGHT;
        }
        else {
            this.currBlockOrigin = Subarray.LEFT;
        }
    }

    // FUNCTION RENAMED: more consistent with other "out-of-place" merges
    private void grailSmartMergeOutOfPlace(K[] array, int start, int leftLen, Subarray leftOrigin,
                                                                 int rightLen, int bufferOffset,
                                                                 Comparator<K> cmp) {
        int buffer = start  - bufferOffset;
        int   left = start;
        int middle = start  +  leftLen;
        int  right = middle;
        int    end = middle + rightLen;

        if(leftOrigin == Subarray.LEFT) {
            while(left < middle && right < end) {
                if(cmp.compare(array[left], array[right]) <= 0) {
                    array[buffer] = array[left];
                    left++;
                }
                else {
                    array[buffer] = array[right];
                    right++;
                }
                buffer++;
            }
        }
        else {
            while(left < middle && right < end) {
                if(cmp.compare(array[left], array[right]) <  0) {
                    array[buffer] = array[left];
                    left++;
                }
                else {
                    array[buffer] = array[right];
                    right++;
                }
                buffer++;
            }            
        }

        if(left < middle) {
            this.currBlockLen = middle - left;
            grailOutOfPlaceBufferRewind(array, left, middle, end);
        }
        else {
            this.currBlockLen = end - right;
            if(leftOrigin == Subarray.LEFT) {
                this.currBlockOrigin = Subarray.RIGHT;
            }
            else {
                this.currBlockOrigin = Subarray.LEFT;
            }
        }
    }

    
    // Credit to Anonymous0726 for better variable names such as "nextBlock"
    // Also minor change: removed unnecessary "currBlock = nextBlock" lines
    private void grailMergeBlocks(K[] array, int firstKey, int medianKey, int start,
                                             int blockCount, int blockLen, int lastMergeBlocks,
                                             int lastLen, Comparator<K> cmp) {
        int buffer;
        
        int currBlock;
        int nextBlock = start + blockLen;

        this.currBlockLen    = blockLen;
        this.currBlockOrigin = grailGetSubarray(array, firstKey, medianKey, cmp);

        Subarray nextBlockOrigin;

        for(int keyIndex = 1; keyIndex < blockCount; keyIndex++, nextBlock += blockLen) {
            currBlock       = nextBlock - this.currBlockLen;
            nextBlockOrigin = grailGetSubarray(array, firstKey + keyIndex, medianKey, cmp);

            if(nextBlockOrigin == this.currBlockOrigin) {
                buffer = currBlock - blockLen;
                
                grailBlockSwap(array, buffer, currBlock, this.currBlockLen);
                this.currBlockLen = blockLen;
            }
            else {
                this.grailSmartMerge(array, currBlock, this.currBlockLen, this.currBlockOrigin,
                                     blockLen, blockLen, cmp);
            }
        }

        currBlock = nextBlock - this.currBlockLen;
        buffer    = currBlock - blockLen;
        
        if(lastLen != 0) {
            if(this.currBlockOrigin == Subarray.RIGHT) {
                grailBlockSwap(array, buffer, currBlock, this.currBlockLen);

                currBlock            = nextBlock;
                this.currBlockLen    = blockLen * lastMergeBlocks;
                this.currBlockOrigin = Subarray.LEFT;
            }
            else {
                this.currBlockLen += blockLen * lastMergeBlocks;
            }

            grailMergeForwards(array, currBlock, this.currBlockLen, lastLen, blockLen, cmp);
        }
        else {
            grailBlockSwap(array, buffer, currBlock, this.currBlockLen);
        }
    }

    private void grailLazyMergeBlocks(K[] array, int firstKey, int medianKey, int start,
                                                 int blockCount, int blockLen, int lastMergeBlocks,
                                                 int lastLen, Comparator<K> cmp) {
        int currBlock;
        int nextBlock = start + blockLen;

        this.currBlockLen    = blockLen;
        this.currBlockOrigin = grailGetSubarray(array, firstKey, medianKey, cmp);

        Subarray nextBlockOrigin;

        for(int keyIndex = 1; keyIndex < blockCount; keyIndex++, nextBlock += blockLen) {
            currBlock       = nextBlock - this.currBlockLen;
            nextBlockOrigin = grailGetSubarray(array, firstKey + keyIndex, medianKey, cmp);

            if(nextBlockOrigin == this.currBlockOrigin) {
                this.currBlockLen = blockLen;
            }
            else {
                // These checks were included in the original code... but why???
                if(blockLen != 0 && this.currBlockLen != 0) {
                    this.grailSmartLazyMerge(array, currBlock, this.currBlockLen, this.currBlockOrigin,
                                             blockLen, cmp);
                }
            }
        }

        currBlock = nextBlock - this.currBlockLen;

        if(lastLen != 0) {
            if(this.currBlockOrigin == Subarray.RIGHT) {
                currBlock            = nextBlock;
                this.currBlockLen    = blockLen * lastMergeBlocks;
                this.currBlockOrigin = Subarray.LEFT;
            }
            else {
                this.currBlockLen += blockLen * lastMergeBlocks;
            }

            grailLazyMerge(array, currBlock, this.currBlockLen, lastLen, cmp);
        }
    }

    private void grailMergeBlocksOutOfPlace(K[] array, int firstKey, int medianKey, int start,
                                                       int blockCount, int blockLen, int lastMergeBlocks,
                                                       int lastLen, Comparator<K> cmp) {
        int buffer;
        
        int currBlock;
        int nextBlock = start + blockLen;

        this.currBlockLen    = blockLen;
        this.currBlockOrigin = grailGetSubarray(array, firstKey, medianKey, cmp);

        Subarray nextBlockOrigin;

        for(int keyIndex = 1; keyIndex < blockCount; keyIndex++, nextBlock += blockLen) {
            currBlock       = nextBlock - this.currBlockLen;  
            nextBlockOrigin = grailGetSubarray(array, firstKey + keyIndex, medianKey, cmp);

            if(nextBlockOrigin == this.currBlockOrigin) {
                buffer = currBlock - blockLen;
                
                System.arraycopy(array, currBlock, array, buffer, this.currBlockLen);
                this.currBlockLen = blockLen;
            }
            else {
                this.grailSmartMergeOutOfPlace(array, currBlock, this.currBlockLen, this.currBlockOrigin,
                                               blockLen, blockLen, cmp);
            }
        }

        currBlock = nextBlock - this.currBlockLen;
        buffer    = currBlock - blockLen;
        
        if(lastLen != 0) {
            if(this.currBlockOrigin == Subarray.RIGHT) {
                System.arraycopy(array, currBlock, array, buffer, this.currBlockLen);

                currBlock            = nextBlock;
                this.currBlockLen    = blockLen * lastMergeBlocks;
                this.currBlockOrigin = Subarray.LEFT;
            }
            else {
                this.currBlockLen += blockLen * lastMergeBlocks;
            }

            grailMergeOutOfPlace(array, currBlock, this.currBlockLen, lastLen, blockLen, cmp);
        }
        else {
            System.arraycopy(array, currBlock, array, buffer, this.currBlockLen);
        }
    }


    //TODO: Double-check "Merge Blocks" arguments
    private void grailCombineInPlace(K[] array, int firstKey, int start, int length,
                                                int subarrayLen, int blockLen,
                                                int mergeCount, int lastSubarrays,
                                                boolean buffer) { //TODO: Do collisions with hanging indents like these affect readability?
        Comparator<K> cmp = this.cmp; // local variable for performance à la Timsort

        int fullMerge  = 2 * subarrayLen;
        // SLIGHT OPTIMIZATION: 'blockCount' only needs to be calculated once for regular merges
        int blockCount = fullMerge / blockLen;
        
        for(int mergeIndex = 0; mergeIndex < mergeCount; mergeIndex++) {
            int offset = start + (mergeIndex * fullMerge);

            grailInsertSort(array, firstKey, blockCount, cmp);

            // INCORRECT PARAMETER BUG FIXED: `block select sort` should be using `offset`, not `start`
            int medianKey = subarrayLen / blockLen;
            medianKey = grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen, cmp);

            if(buffer) {
                this.grailMergeBlocks(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0, cmp);
            }
            else {
                this.grailLazyMergeBlocks(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0, cmp);
            }
        }

        // INCORRECT CONDITIONAL/PARAMETER BUG FIXED: Credit to 666666t for debugging.
        if(lastSubarrays != 0) {
            int offset = start + (mergeCount * fullMerge);
            blockCount = lastSubarrays / blockLen;

            grailInsertSort(array, firstKey, blockCount + 1, cmp);

            // INCORRECT PARAMETER BUG FIXED: `block select sort` should be using `offset`, not `start`
            int medianKey = subarrayLen / blockLen;
            medianKey = grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen, cmp);

            // MISSING BOUNDS CHECK BUG FIXED: `lastFragment` *can* be 0 if the last two subarrays are evenly
            //                                 divided into blocks. This prevents Grailsort from going out-of-bounds.
            int lastFragment = lastSubarrays - (blockCount * blockLen);
            int lastMergeBlocks;
            if(lastFragment != 0) {
                lastMergeBlocks = grailCountLastMergeBlocks(array, offset, blockCount, blockLen, cmp);
            }
            else {
                lastMergeBlocks = 0;
            }

            int smartMerges = blockCount - lastMergeBlocks;

            //TODO: Double-check if this micro-optimization works correctly like the original
            if(smartMerges == 0) {
                // MINOR CHANGE: renamed for consistency (used to be 'leftLength')
                int leftLen = lastMergeBlocks * blockLen;

                // INCORRECT PARAMETER BUG FIXED: these merges should be using `offset`, not `start`
                if(buffer) {
                    grailMergeForwards(array, offset, leftLen, lastFragment, blockLen, cmp);
                }
                else {
                    grailLazyMerge(array, offset, leftLen, lastFragment, cmp);
                }
            }
            else {
                if(buffer) {
                    this.grailMergeBlocks(array, firstKey, firstKey + medianKey, offset,
                                          smartMerges, blockLen, lastMergeBlocks, lastFragment, cmp);
                }
                else {
                    this.grailLazyMergeBlocks(array, firstKey, firstKey + medianKey, offset,
                                              smartMerges, blockLen, lastMergeBlocks, lastFragment, cmp);
                }
            }
        }

        if(buffer) {
            grailInPlaceBufferReset(array, start, length, blockLen);
        }
    }

    private void grailCombineOutOfPlace(K[] array, int firstKey, int start, int length,
                                                   int subarrayLen, int blockLen,
                                                   int mergeCount, int lastSubarrays) {
        Comparator<K> cmp = this.cmp; // local variable for performance à la Timsort
        System.arraycopy(array, start - blockLen, this.extBuffer, 0, blockLen);

        int fullMerge = 2 * subarrayLen;
        // SLIGHT OPTIMIZATION: 'blockCount' only needs to be calculated once for regular merges
        int blockCount = fullMerge / blockLen;
        
        for(int mergeIndex = 0; mergeIndex < mergeCount; mergeIndex++) {
            int offset = start + (mergeIndex * fullMerge);

            grailInsertSort(array, firstKey, blockCount, cmp);

            // INCORRECT PARAMETER BUG FIXED: `block select sort` should be using `offset`, not `start`
            int medianKey = subarrayLen / blockLen;
            medianKey = grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen, cmp);

            this.grailMergeBlocksOutOfPlace(array, firstKey, firstKey + medianKey, offset,
                                            blockCount, blockLen, 0, 0, cmp);
        }

        // INCORRECT CONDITIONAL/PARAMETER BUG FIXED: Credit to 666666t for debugging.
        if(lastSubarrays != 0) {
            int offset = start + (mergeCount * fullMerge);
            blockCount = lastSubarrays / blockLen;

            grailInsertSort(array, firstKey, blockCount + 1, cmp);

            // INCORRECT PARAMETER BUG FIXED: `block select sort` should be using `offset`, not `start`
            int medianKey = subarrayLen / blockLen;
            medianKey = grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen, cmp);

            // MISSING BOUNDS CHECK BUG FIXED: `lastFragment` *can* be 0 if the last two subarrays are evenly
            //                                 divided into blocks. This prevents Grailsort from going out-of-bounds.
            int lastFragment = lastSubarrays - (blockCount * blockLen);
            int lastMergeBlocks;
            if(lastFragment != 0) {
                lastMergeBlocks = grailCountLastMergeBlocks(array, offset, blockCount, blockLen, cmp);
            }
            else {
                lastMergeBlocks = 0;
            }

            int smartMerges = blockCount - lastMergeBlocks;

            if(smartMerges == 0) {
                // MINOR CHANGE: renamed for consistency (used to be 'leftLength')
                int leftLen = lastMergeBlocks * blockLen;
                
                // INCORRECT PARAMETER BUG FIXED: this merge should be using `offset`, not `start`
                grailMergeOutOfPlace(array, offset, leftLen, lastFragment, blockLen, cmp);
            }
            else {
                this.grailMergeBlocksOutOfPlace(array, firstKey, firstKey + medianKey, offset,
                                                smartMerges, blockLen, lastMergeBlocks, lastFragment, cmp);
            }
        }

        grailOutOfPlaceBufferReset(array, start, length, blockLen);
        System.arraycopy(this.extBuffer, 0, array, start - blockLen, blockLen);
    }

    // 'keys' are on the left side of array. Blocks of length 'subarrayLen' combined. We'll combine them in pairs
    // 'subarrayLen' is a power of 2. (2 * subarrayLen / blockLen) keys are guaranteed
    //
    // IMPORTANT RENAMES: 'lastSubarray' is now 'lastSubarrays' because it includes the length of the last left
    //                    subarray AND last right subarray (if there is a right subarray at all).
    //
    //                    *Please also check everything surrounding 'if(lastSubarrays != 0)' inside
    //                    'combine in-/out-of-place' methods for other renames!!*
    private void grailCombineBlocks(K[] array, int firstKey, int start, int length,
                                               int subarrayLen, int blockLen, boolean buffer) {
        int     fullMerge = 2 * subarrayLen;
        int    mergeCount = length /  fullMerge;
        int lastSubarrays = length - (fullMerge * mergeCount);

        if(lastSubarrays <= subarrayLen) {
            length -= lastSubarrays;
            lastSubarrays = 0;
        }

        // INCOMPLETE CONDITIONAL BUG FIXED: In order to combine blocks out-of-place, we must check if a full-sized
        //                                   block fits into our external buffer.
        if(buffer && blockLen <= this.extBufferLen) {
            this.grailCombineOutOfPlace(array, firstKey, start, length, subarrayLen, blockLen,
                                        mergeCount, lastSubarrays);
        }
        else {
            this.grailCombineInPlace(array, firstKey, start, length, subarrayLen, blockLen,
                                     mergeCount, lastSubarrays, buffer);
        }
    }


    // "Classic" in-place merge sort using binary searches and rotations
    //
    // cost: min(leftLen, rightLen)^2 + max(leftLen, rightLen)
    // MINOR CHANGES: better naming -- 'insertPos' is now 'mergeLen' -- and "middle"/"end" calculations simplified
    private static <K> void grailLazyMerge(K[] array, int start, int leftLen, int rightLen, Comparator<K> cmp) {
        if(leftLen < rightLen) {
            int middle = start + leftLen;
            
            while(leftLen != 0) {
                int mergeLen = grailBinarySearchLeft(array, middle, rightLen, array[start], cmp);

                if(mergeLen != 0) {
                    grailRotate(array, start, leftLen, mergeLen);
                    start    += mergeLen;
                    rightLen -= mergeLen;
                }
                
                middle += mergeLen;
                
                if(rightLen == 0) {
                    break;
                }
                else {
                    do {
                        start++;
                        leftLen--;
                    } while(leftLen != 0 && cmp.compare(array[start ],
                                                        array[middle]) <= 0);
                }
            }
        }
        // INDEXING BUG FIXED: Credit to Anonymous0726 for debugging.
        else {
            int end = start + leftLen + rightLen - 1;
            
            while(rightLen != 0) {            
                int mergeLen = grailBinarySearchRight(array, start, leftLen, array[end], cmp);

                if(mergeLen != leftLen) {
                    grailRotate(array, start + mergeLen, leftLen - mergeLen, rightLen);
                    end     -=  leftLen - mergeLen;
                    leftLen  = mergeLen;
                }

                if(leftLen == 0) {
                    break;
                }
                else {
                    int middle = start + leftLen;
                    do {
                        rightLen--;
                        end--;
                    } while(rightLen != 0 && cmp.compare(array[middle - 1],
                                                         array[end       ]) <= 0);
                }
            }
        }
    }

    private static <K> void grailLazyStableSort(K[] array, int start, int length, Comparator<K> cmp) {
        for(int index = 1; index < length; index += 2) {
            int  left = start + index - 1;
            int right = start + index; 

            if(cmp.compare(array[left], array[right]) > 0) {
                grailSwap(array, left, right);
            }
        }
        for(int mergeLen = 2; mergeLen < length; mergeLen *= 2) {
            int fullMerge = 2 * mergeLen;

            int mergeIndex;
            int mergeEnd = length - fullMerge;

            for(mergeIndex = 0; mergeIndex <= mergeEnd; mergeIndex += fullMerge) {
                grailLazyMerge(array, start + mergeIndex, mergeLen, mergeLen, cmp);
            }

            int leftOver = length - mergeIndex;
            if(leftOver > mergeLen) {
                grailLazyMerge(array, start + mergeIndex, mergeLen, leftOver - mergeLen, cmp);
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

    
    void grailCommonSort(K[] array, int start, int length, K[] extBuffer, int extBufferLen) {
        if(length < 16) {
            grailInsertSort(array, start, length, this.cmp);
            return;
        }

        int blockLen = 1;

        // find the smallest power of two greater than or equal to
        // the square root of the input's length
        while((blockLen * blockLen) < length) {
            blockLen *= 2;
        }

        // '((a - 1) / b) + 1' is actually a clever and very efficient
        // formula for the ceiling of (a / b)
        //
        // credit to Anonymous0726 for figuring this out!
        int keyLen = ((length - 1) / blockLen) + 1;

        // Grailsort is hoping to find `2 * sqrt(n)` unique items
        // throughout the array
        int idealKeys = keyLen + blockLen;

        //TODO: Clean up `start +` offsets
        int keysFound = grailCollectKeys(array, start, length, idealKeys, this.cmp);

        boolean idealBuffer;
        if(keysFound < idealKeys) {
            if(keysFound < 4) {
                // GRAILSORT STRATEGY 3 -- No block swaps or scrolling buffer; resort to Lazy Stable Sort
                grailLazyStableSort(array, start, length, this.cmp);
                return;
            }
            else {
                // GRAILSORT STRATEGY 2 -- Block swaps with small scrolling buffer and/or lazy merges
                keyLen = blockLen;
                blockLen = 0;
                idealBuffer = false;

                while(keyLen > keysFound) {
                    keyLen /= 2;
                }
            }
        }
        else {
            // GRAILSORT STRATEGY 1 -- Block swaps with scrolling buffer
            idealBuffer = true;
        }

        int bufferEnd = blockLen + keyLen;
        int subarrayLen;
        if(idealBuffer) {
            subarrayLen = blockLen;
        }
        else {
            subarrayLen = keyLen;
        }

        if(idealBuffer && extBuffer != null) {
            // GRAILSORT + EXTRA SPACE
            this.extBuffer    = extBuffer;
            this.extBufferLen = extBufferLen;
        }

        this.grailBuildBlocks(array, start + bufferEnd, length - bufferEnd, subarrayLen, this.cmp);

        while((length - bufferEnd) > (2 * subarrayLen)) {
            subarrayLen *= 2;

            int currentBlockLen = blockLen;
            boolean scrollingBuffer = idealBuffer;

            // Huge credit to Anonymous0726, phoenixbound, and DeveloperSort for their tireless efforts
            // towards deconstructing this math.
            if(!idealBuffer) {
                int keyBuffer = keyLen / 2;
                
                // Recall that the key-buffer is 'O(sqrt n)' items. If the key-buffer squared is greater than
                // or equal to the length of the two subarrays being merged, then we have at least 1 key per
                // item. This allows us to use a sufficient 'O(sqrt n)' scrolling buffer for 'O(n)' local
                // merges as long as possible, greatly improving the performance of Grailsort Strategy 2.
                if((keyBuffer * keyBuffer) >= (2 * subarrayLen)) {
                    currentBlockLen = keyBuffer;
                    scrollingBuffer = true;
                }
                else {
                    // This is a very recent discovery, and the math will be spelled out later, but this
                    // "minKeys" calculation is *completely unnecessary*. "minKeys" would be less than
                    // "keyLen" iff (keyBuffer * keyBuffer) >= (2 * subarrayLen)... but this situation
                    // is already covered by our scrolling buffer optimization right above!! Consequently,
                    // "minKeys" will *always* be equal to "keyLen" when Grailsort resorts to smart lazy
                    // merges. Removing this loop is by itself a decent optimization, as well!
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
            this.grailCombineBlocks(array, start, start + bufferEnd, length - bufferEnd,
                                    subarrayLen, currentBlockLen, scrollingBuffer);
        }

        grailInsertSort(array, start, bufferEnd, this.cmp);
        grailLazyMerge(array, start, bufferEnd, length - bufferEnd, this.cmp);
    }


    public void grailSortInPlace(K[] array, int start, int length) {
        this.grailCommonSort(array, start, length, null, 0);
    }

    // Credit to Anonymous0726 for 'array.getClass().getComponentType()' idea
    @SuppressWarnings("unchecked")
    public void grailSortStaticOOP(K[] array, int start, int length) {
        K[] buffer = (K[]) Array.newInstance(array.getClass().getComponentType(), GRAIL_STATIC_EXT_BUFFER_LEN);
        this.grailCommonSort(array, start, length, buffer, GRAIL_STATIC_EXT_BUFFER_LEN);
    }
    
    @SuppressWarnings("unchecked")
    public void grailSortDynamicOOP(K[] array, int start, int length) {
        int bufferLen = 1;
        while((bufferLen * bufferLen) < length) {
            bufferLen *= 2;
        }
        K[] buffer = (K[]) Array.newInstance(array.getClass().getComponentType(), bufferLen);
        this.grailCommonSort(array, start, length, buffer, bufferLen);
    }
}
