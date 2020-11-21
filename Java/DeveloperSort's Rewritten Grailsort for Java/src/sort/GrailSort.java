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
 *                       EilrahcF
 *                       Enver
 *                       lovebuny
 *                       MP
 *                       phoenixbound
 *                       thatsOven
 *                       DeveloperSort
 *                       Morwenn
 *
 * Special thanks to "The Studio" Discord community!
 */

// Credit to phoenixbound for this clever idea
enum Subarray {
    LEFT,
    RIGHT;
}

// REWRITTEN GRAILSORT FOR JAVA - A heavily refactored C/C++-to-Java version of
//                                Andrey Astrelin's GrailSort.h, aiming to be as
//                                readable and intuitive as possible.
//
// ** Written and maintained by The Holy Grail Sort Project
//
// Primary author: Summer Dragonfly, with the incredible aid from the rest of
//                 the team mentioned throughout this file!
//
// Editor: Bee sort
//
// Current status: EVERY VERSION PASSING ALL TESTS / POTENTIALLY FIXED as of
//                 10/23/20
public class GrailSort<K> {
    private Comparator<K> grailComp;
    
    final protected static int GRAIL_STATIC_EXT_BUF_LEN = 512;
    
    private K[] externalBuffer;
    private int externalBufferLen;
    
    private int currentBlockLen;
    private Subarray currentBlockOrigin;
    
    public GrailSort(Comparator<K> grailComp) {
        this.grailComp = grailComp;
    }
    
    private void grailSwap(K[] array, int a, int b) {
        K temp   = array[a];
        array[a] = array[b];
        array[b] = temp;
    }
    
    private void grailBlockSwap(K[] array, int a, int b, int blockLen) {
        for(int i = 0; i < blockLen; i++) {
            this.grailSwap(array, a + i, b + i);
        }
    }
    
    private void grailRotate(K[] array, int start, int leftLen, int rightLen) {
        while(leftLen > 0 && rightLen > 0) {
            if(leftLen <= rightLen) {
                this.grailBlockSwap(array, start, start + leftLen, leftLen);
                start += leftLen;
                rightLen -= leftLen;
            } 
            else {
                this.grailBlockSwap(array, start + leftLen - rightLen, start + leftLen, rightLen);
                leftLen -= rightLen;
            }
        }
    }
    
    // Variant of Insertion Sort that utilizes swaps instead of overwrites.
    // Also known as "Optimized Gnomesort".
    private void grailInsertSort(K[] array, int start, int length) {
        for(int item = 1; item < length; item++) {
            int left  = start + item - 1;
            int right = start + item;
            
            while(left >= start && this.grailComp.compare(array[ left],
                                                          array[right]) > 0) {
                this.grailSwap(array, left, right);
                left--;
                right--;
            }
        }
    }

    private int grailBinarySearchLeft(K[] array, int start, int length, K target) {
        int left  = 0;
        int right = length;
        while(left < right) {
            int middle = left + ((right - left) / 2);
            if(this.grailComp.compare(array[start + middle], target) < 0) {
                left = middle + 1;
            }
            else {
                right = middle;
            }
        }
        return left;
    }
    // Credit to Anonymous0726 for debugging
    private int grailBinarySearchRight(K[] array, int start, int length, K target) {
        int left  = 0;
        int right = length;
        while(left < right) {
            int middle = left + ((right - left) / 2);
            if(this.grailComp.compare(array[start + middle], target) > 0) {
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
    private int grailCollectKeys(K[] array, int start, int length, int idealKeys) {
        int keysFound  = 1; // by itself, the first item in the array is our first unique key
        int firstKey   = 0; // the first item in the array is at the first position in the array
        int currentKey = 1; // the index used for finding potentially unique items ("keys") in the array
        
        while(currentKey < length && keysFound < idealKeys) {
            
            // Find the location in the key-buffer where our current key can be inserted in sorted order.
            // If the key at insertPos is equal to currentKey, then currentKey isn't unique and we move on.
            int insertPos = this.grailBinarySearchLeft(array, start + firstKey, keysFound, array[start + currentKey]);
            
            // The second part of this conditional does the equal check we were just talking about; however,
            // if currentKey is larger than everything in the key-buffer (meaning insertPos == keysFound),
            // then that also tells us it wasn't *equal* to anything in the key-buffer. Magic! :) 
            if(insertPos == keysFound || this.grailComp.compare(array[start + currentKey            ],
                                                                array[start +   firstKey + insertPos]) != 0) {
                
                // First, rotate the key-buffer over to currentKey's immediate left...
                // (this helps save a TON of swaps/writes!!!)
                this.grailRotate(array, start + firstKey, keysFound, currentKey - (firstKey + keysFound));
                
                // Update the new position of firstKey...
                firstKey = currentKey - keysFound;
                
                // Then, "insertion sort" currentKey to its spot in the key-buffer!
                this.grailRotate(array, start + firstKey + insertPos, keysFound - insertPos, 1);
                
                // One step closer to idealKeys.
                keysFound++;
            }
            // Move on and test the next key...
            currentKey++;
        }
        
        // Bring however many keys we found back to the beginning of our array,
        // and return the number of keys collected.
        this.grailRotate(array, start, firstKey, keysFound);
        return keysFound;
    }
    
    private void grailPairwiseSwaps(K[] array, int start, int length) {
        int index;
        for(index = 1; index < length; index += 2) {
            int  left = start + index - 1;
            int right = start + index;

            if(this.grailComp.compare(array[left], array[right]) > 0) {
                this.grailSwap(array,  left - 2, right);
                this.grailSwap(array, right - 2,  left);
            }
            else {
                this.grailSwap(array,  left - 2,  left);
                this.grailSwap(array, right - 2, right);
            }
        }
        
        int left = start + index - 1;
        if(left < start + length) {
            this.grailSwap(array, left - 2, left);
        }
    }
    private void grailPairwiseWrites(K[] array, int start, int length) {
        int index;
        for(index = 1; index < length; index += 2) {
            int  left = start + index - 1;
            int right = start + index;

            if(this.grailComp.compare(array[left], array[right]) > 0) {
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
    private void grailMergeForwards(K[] array, int start, int leftLen, int rightLen, int bufferOffset) {
        int   left = start;
        int middle = start  +  leftLen;
        int  right = middle;
        int    end = middle + rightLen;
        int buffer = start  - bufferOffset;
        
        while(right < end) {
            if(left == middle || this.grailComp.compare(array[ left],
                                                        array[right]) > 0) {
                
                this.grailSwap(array, buffer, right);
                right++;
            }
            else {
                this.grailSwap(array, buffer,  left);
                left++;
            }
            buffer++;
        }
        
        if(buffer != left) {
            this.grailBlockSwap(array, buffer, left, middle - left);
        }
    }

    // credit to 666666t for thorough bug-checking/fixing
    private void grailMergeBackwards(K[] array, int start, int leftLen, int rightLen, int bufferOffset) {
        int   left = start  +  leftLen - 1;
        int middle = left;
        // OFF-BY-ONE BUG FIXED: used to be `int  right = middle + rightLen - 1;`
        int  right = middle + rightLen;
        int    end = start;
        // OFF-BY-ONE BUG FIXED: used to be `int buffer = right  + bufferOffset - 1;`
        int buffer = right  + bufferOffset;
        
        while(left >= end) {
            if(right == middle || this.grailComp.compare(array[ left],
                                                         array[right]) > 0) {
                
                this.grailSwap(array, buffer,  left);
                left--;
            }
            else {
                this.grailSwap(array, buffer, right);
                right--;
            }
            buffer--;
        }
        
        if(right != buffer) {
            while(right > middle) {
                this.grailSwap(array, buffer, right);
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
    private void grailMergeOutOfPlace(K[] array, int start, int leftLen, int rightLen, int bufferOffset) {
        int   left = start;
        int middle = start  +  leftLen;
        int  right = middle;
        int    end = middle + rightLen;
        int buffer = start  - bufferOffset;
        
        while(right < end) {
            if(left == middle || this.grailComp.compare(array[ left],
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

    private void grailBuildInPlace(K[] array, int start, int length, int currentMerge, int bufferLen) {    
        for(int mergeLen = currentMerge; mergeLen < bufferLen; mergeLen *= 2) {
            int fullMerge = 2 * mergeLen;
            
            int mergeIndex;
            int mergeEnd = start + length - fullMerge;
            int bufferOffset = mergeLen;
    
            for(mergeIndex = start; mergeIndex <= mergeEnd; mergeIndex += fullMerge) {
                this.grailMergeForwards(array, mergeIndex, mergeLen, mergeLen, bufferOffset);
            }
    
            int leftOver = length - (mergeIndex - start);
    
            if(leftOver > mergeLen) {
                this.grailMergeForwards(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset);
            }
            else {
                this.grailRotate(array, mergeIndex - mergeLen, mergeLen, leftOver);
            }
    
            start -= mergeLen;
        }
        
        int fullMerge   = 2 * bufferLen; 
        int finalBlock  = length & (fullMerge - 1); // previous version : int finalBlock  = length % fullMerge;
        int finalOffset = start + length - finalBlock;
    
        if(finalBlock <= bufferLen) {
            this.grailRotate(array, finalOffset, finalBlock, bufferLen);
        }
        else {
            this.grailMergeBackwards(array, finalOffset, bufferLen, finalBlock - bufferLen, bufferLen);
        }
    
        for(int mergeIndex = finalOffset - fullMerge; mergeIndex >= start; mergeIndex -= fullMerge) {
            this.grailMergeBackwards(array, mergeIndex, bufferLen, bufferLen, bufferLen);
        }
    }

    private void grailBuildOutOfPlace(K[] array, int start, int length, int bufferLen, int externLen) {
        System.arraycopy(array, start - externLen, this.externalBuffer, 0, externLen);
        
        this.grailPairwiseWrites(array, start, length);
        start -= 2;
        
        int mergeLen;
        for(mergeLen = 2; mergeLen < externLen; mergeLen *= 2) {
            int fullMerge = 2 * mergeLen;
            
            int mergeIndex;
            int mergeEnd = start + length - fullMerge;
            int bufferOffset = mergeLen;
    
            for(mergeIndex = start; mergeIndex <= mergeEnd; mergeIndex += fullMerge) {
                this.grailMergeOutOfPlace(array, mergeIndex, mergeLen, mergeLen, bufferOffset);
            }
    
            int leftOver = length - (mergeIndex - start);
    
            if(leftOver > mergeLen) {
                this.grailMergeOutOfPlace(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset);
            }
            else {
                // TODO: Is this correct??
                for(int offset = 0; offset < leftOver; offset++) {
                    array[mergeIndex + offset - mergeLen] = array[mergeIndex + offset];
                }
            }
    
            start -= mergeLen;
        }
        
        System.arraycopy(this.externalBuffer, 0, array, start + length, externLen);
        this.grailBuildInPlace(array, start, length, mergeLen, bufferLen);
    }

    // build blocks of length 'bufferLen'
    // input: [start - mergeLen, start - 1] elements are buffer
    // output: first 'bufferLen' elements are buffer, blocks (2 * bufferLen) and last subblock sorted
    private void grailBuildBlocks(K[] array, int start, int length, int bufferLen) {
        if(this.externalBuffer != null) {
            int externLen;
            
            if(bufferLen < this.externalBufferLen) {
                externLen = bufferLen;
            }
            else {
                //TODO: Test if this is faster than the original
                // max power of 2 -- just in case
                // Find max power where it is less or equal to this.externalBufferLen
                // Original version:
                // externLen = 1;
                // while((externLen * 2) <= this.externalBufferLen) {
                //     externLen *= 2;
                // }
                // Optimized version:
                externLen = (int) Math.ceil((double) Math.log(externalBufferLen) / Math.log(2) - 1);
                externLen = (int) Math.pow(2,externLen);
                // Line 442 Original Version:
                // if (Math.log(externalBufferLen) / Math.log(2) % 1 == 0){ externLen *= 2;}
                // Newer version (takes up O(1) memory, surely the garbage collector will know this):
                double checked = Math.log(externalBufferLen) / Math.log(2);
                if (checked == ((int) checked)){ externLen *= 2;} // check if externalBufferLen is a power of 2
                if (externalBufferLen == 0 || externalBufferLen == 1) {externLen = 1;}
            }
            
            this.grailBuildOutOfPlace(array, start, length, bufferLen, externLen);
        }
        else {
            this.grailPairwiseSwaps(array, start, length);
            this.grailBuildInPlace(array, start - 2, length, 2, bufferLen);
        }
    }

    // Returns the final position of 'medianKey'.
    private int grailBlockSelectSort(K[] array, int keys, int start, int medianKey, int blockCount, int blockLen) {
        for(int block = 1; block < blockCount; block++) {
            int  left = block - 1;
            int right = left;

            for(int index = block; index < blockCount; index++) {
                int compare = this.grailComp.compare(array[start + (right * blockLen)],
                                                     array[start + (index * blockLen)]);

                if(compare > 0 || (compare == 0 && this.grailComp.compare(array[keys + right],
                                                                          array[keys + index]) > 0)) {
                    right = index;
                }
            }

            if(right != left) {
                // Swap the left and right selected blocks...
                this.grailBlockSwap(array, start + (left * blockLen), start + (right * blockLen), blockLen);

                // Swap the keys...
                this.grailSwap(array, keys + left, keys + right);

                // ...and follow the 'medianKey' if it was swapped

                // ORIGINAL LOC: if(midkey==u-1 || midkey==p) midkey^=(u-1)^p;
                // MASSIVE, MASSIVE credit to lovebuny for figuring this one out!
                if(medianKey == left) {
                    medianKey = right;
                }
                else if(medianKey == right) {
                    medianKey = left;
                }
            }
        }

        return medianKey;
    }
    
    // Swaps Grailsort's "scrolling buffer" from the right side of the array all the way back to 'start'.
    // Costs O(n) operations.
    //
    // OFF-BY-ONE BUG FIXED: used to be `int index = start + resetLen`; credit to 666666t for debugging
    private void grailInPlaceBufferReset(K[] array, int start, int resetLen, int bufferLen) {
        for(int index = start + resetLen - 1; index >= start; index--) {
            this.grailSwap(array, index, index - bufferLen);
        }
    }
    
    // Shifts entire array over 'bufferSize' spaces to make room for the out-of-place merging buffer.
    // Costs O(n) operations.
    //
    // OFF-BY-ONE BUG FIXED: used to be `int index = start + resetLen`; credit to 666666t for debugging
    private void grailOutOfPlaceBufferReset(K[] array, int start, int resetLen, int bufferLen) {
        for(int index = start + resetLen - 1; index >= start; index--) {
            array[index] = array[index - bufferLen];
        }
    }
    
    // Rewinds Grailsort's "scrolling buffer" such that any items from a left subarray block left over by a "smart merge" are moved to
    // the right of the buffer. This is used to maintain stability and to continue an ongoing merge that has run out of buffer space.
    // Costs O(sqrt n) swaps in the *absolute* worst-case. 
    //
    // NAMING IMPROVED: the left over items are in the middle of the merge while the buffer is at the end
    private void grailInPlaceBufferRewind(K[] array, int start, int leftOvers, int buffer) {
        while(leftOvers > start) {
            leftOvers--;
            buffer--;
            this.grailSwap(array, buffer, leftOvers);
        }
    }
    
    // Rewinds Grailsort's out-of-place buffer such that any items from a left subarray block left over by a "smart merge" are moved to
    // the right of the buffer. This is used to maintain stability and to continue an ongoing merge that has run out of buffer space.
    // Costs O(sqrt n) writes in the *absolute* worst-case.
    //
    // INCORRECT ORDER OF PARAMETERS BUG FIXED: `leftOvers` should be the middle, and `buffer` should be the end
    private void grailOutOfPlaceBufferRewind(K[] array, int start, int leftOvers, int buffer) {
        while(leftOvers > start) {
            leftOvers--;
            buffer--;
            array[buffer] = array[leftOvers];
        }
    }
    
    private Subarray grailGetSubarray(K[] array, int currentKey, int medianKey) {
        if(this.grailComp.compare(array[currentKey], array[medianKey]) < 0) {
            return Subarray.LEFT;
        }
        else {
            return Subarray.RIGHT;
        }
    }

    // FUNCTION RENAMED: more clear *which* left blocks are being counted
    private int grailCountFinalLeftBlocks(K[] array, int offset, int blockCount, int blockLen) {
        int leftBlocks = 0;
        
        int firstRightBlock = offset + (blockCount * blockLen);
        int   prevLeftBlock = firstRightBlock - blockLen;
        
        while(leftBlocks < blockCount && this.grailComp.compare(array[firstRightBlock],
                                                                array[  prevLeftBlock]) < 0) {
            leftBlocks++;
            prevLeftBlock -= blockLen;
        }
        
        return leftBlocks;
    }
    
    private void grailSmartMerge(K[] array, int start, int leftLen, Subarray leftOrigin, int rightLen, int bufferOffset) {
        int   left = start;
        int middle = start  +  leftLen;
        int  right = middle;
        int    end = middle + rightLen;
        int buffer = start  - bufferOffset;
        
        if(leftOrigin == Subarray.LEFT) {
            while(left < middle && right < end) {
                if(this.grailComp.compare(array[left], array[right]) <= 0) {
                    this.grailSwap(array, buffer, left);
                    left++;
                }
                else {
                    this.grailSwap(array, buffer, right);
                    right++;
                }
                buffer++;
            }
        }
        else {
            while(left < middle && right < end) {
                if(this.grailComp.compare(array[left], array[right]) <  0) {
                    this.grailSwap(array, buffer, left);
                    left++;
                }
                else {
                    this.grailSwap(array, buffer, right);
                    right++;
                }
                buffer++;
            }            
        }
        
        if(left < middle) {
            this.currentBlockLen = middle - left;
            this.grailInPlaceBufferRewind(array, left, middle, end);
        }
        else {
            this.currentBlockLen = end - right;
            if(leftOrigin == Subarray.LEFT) {
                this.currentBlockOrigin = Subarray.RIGHT;
            }
            else {
                this.currentBlockOrigin = Subarray.LEFT;
            }
        }
    }

    private void grailSmartLazyMerge(K[] array, int start, int leftLen, Subarray leftOrigin, int rightLen) {
        if(leftOrigin == Subarray.LEFT) {
            if(this.grailComp.compare(array[start + leftLen - 1], array[start + leftLen]) >  0) {
                while(leftLen != 0) {
                    int insertPos = this.grailBinarySearchLeft(array, start + leftLen, rightLen, array[start]);
                    
                    if(insertPos != 0) {
                        this.grailRotate(array, start, leftLen, insertPos);
                        start    += insertPos;
                        rightLen -= insertPos;
                    }
                    
                    if(rightLen == 0) {
                        this.currentBlockLen = leftLen;
                        return;
                    }
                    else {
                        do {
                            start++;
                            leftLen--;
                        } while(leftLen != 0 && this.grailComp.compare(array[start          ],
                                                                       array[start + leftLen]) <= 0);
                    }
                }
            }
        }
        else {
            if(this.grailComp.compare(array[start + leftLen - 1], array[start + leftLen]) >= 0) {
                while(leftLen != 0) {
                    int insertPos = this.grailBinarySearchRight(array, start + leftLen, rightLen, array[start]);
                    
                    if(insertPos != 0) {
                        this.grailRotate(array, start, leftLen, insertPos);
                        start    += insertPos;
                        rightLen -= insertPos;
                    }
                    
                    if(rightLen == 0) {
                        this.currentBlockLen = leftLen;
                        return;
                    }
                    else {
                        do {
                            start++;
                            leftLen--;
                        } while(leftLen != 0 && this.grailComp.compare(array[start          ],
                                                                       array[start + leftLen]) < 0);
                    }
                }
            }
        }
        
        this.currentBlockLen = rightLen;
        if(leftOrigin == Subarray.LEFT) {
            this.currentBlockOrigin = Subarray.RIGHT;
        }
        else {
            this.currentBlockOrigin = Subarray.LEFT;
        }
    }

    // FUNCTION RENAMED: more consistent with other "out-of-place" merges
    private void grailSmartMergeOutOfPlace(K[] array, int start, int leftLen, Subarray leftOrigin, int rightLen, int bufferOffset) {
        int   left = start;
        int middle = start  +  leftLen;
        int  right = middle;
        int    end = middle + rightLen;
        int buffer = start  - bufferOffset;
        
        if(leftOrigin == Subarray.LEFT) {
            while(left < middle && right < end) {
                if(this.grailComp.compare(array[left], array[right]) <= 0) {
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
                if(this.grailComp.compare(array[left], array[right]) <  0) {
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
            this.currentBlockLen = middle - left;
            this.grailOutOfPlaceBufferRewind(array, left, middle, end);
        }
        else {
            this.currentBlockLen = end - right;
            if(leftOrigin == Subarray.LEFT) {
                this.currentBlockOrigin = Subarray.RIGHT;
            }
            else {
                this.currentBlockOrigin = Subarray.LEFT;
            }
        }
    }

    private void grailMergeBlocks(K[] array, int keys, int medianKey, int start, int blockCount, int blockLen, int finalLeftBlocks, int finalLen) {
        int currentBlock;
        int blockIndex = blockLen;
        
        this.currentBlockLen    = blockLen;
        this.currentBlockOrigin = this.grailGetSubarray(array, keys, medianKey);
        
        for(int keyIndex = 1; keyIndex < blockCount; keyIndex++, blockIndex += blockLen) {
            currentBlock = blockIndex - this.currentBlockLen;
            
            Subarray nextBlockOrigin = this.grailGetSubarray(array, keys + keyIndex, medianKey);
            
            if(nextBlockOrigin == this.currentBlockOrigin) {
                this.grailBlockSwap(array, start + currentBlock - blockLen, start + currentBlock, this.currentBlockLen);
                currentBlock = blockIndex;
                
                this.currentBlockLen = blockLen;
            }
            else {
                this.grailSmartMerge(array, start + currentBlock, this.currentBlockLen, this.currentBlockOrigin, blockLen, blockLen);
            }
        }
        
        currentBlock = blockIndex - this.currentBlockLen;
        
        if(finalLen != 0) {
            if(this.currentBlockOrigin == Subarray.RIGHT) {
                this.grailBlockSwap(array, start + currentBlock - blockLen, start + currentBlock, this.currentBlockLen);
                currentBlock = blockIndex;
                
                this.currentBlockLen    = blockLen * finalLeftBlocks;
                this.currentBlockOrigin = Subarray.LEFT;
            }
            else {
                this.currentBlockLen += blockLen * finalLeftBlocks;
            }
            
            this.grailMergeForwards(array, start + currentBlock, this.currentBlockLen, finalLen, blockLen);
        }
        else {
            this.grailBlockSwap(array, start + currentBlock, start + currentBlock - blockLen, this.currentBlockLen);
        }
    }

    private void grailLazyMergeBlocks(K[] array, int keys, int medianKey, int start, int blockCount, int blockLen, int finalLeftBlocks, int finalLen) {
        int currentBlock;
        int blockIndex = blockLen;
        
        this.currentBlockLen    = blockLen;
        this.currentBlockOrigin = this.grailGetSubarray(array, keys, medianKey);
        
        for(int keyIndex = 1; keyIndex < blockCount; keyIndex++, blockIndex += blockLen) {
            currentBlock = blockIndex - this.currentBlockLen;
            
            Subarray nextBlockOrigin = this.grailGetSubarray(array, keys + keyIndex, medianKey);
            
            if(nextBlockOrigin == this.currentBlockOrigin) {
                currentBlock = blockIndex;
                
                this.currentBlockLen = blockLen;
            }
            else {
                // These checks were included in the original code... but why???
                if(blockLen != 0 && this.currentBlockLen != 0) {
                    this.grailSmartLazyMerge(array, start + currentBlock, this.currentBlockLen, this.currentBlockOrigin, blockLen);
                }
            }
        }
        
        currentBlock = blockIndex - this.currentBlockLen;
        
        if(finalLen != 0) {
            if(this.currentBlockOrigin == Subarray.RIGHT) {
                currentBlock = blockIndex;
                
                this.currentBlockLen    = blockLen * finalLeftBlocks;
                this.currentBlockOrigin = Subarray.LEFT;
            }
            else {
                this.currentBlockLen += blockLen * finalLeftBlocks;
            }
            
            this.grailLazyMerge(array, start + currentBlock, this.currentBlockLen, finalLen);
        }
    }

    //TODO: For the love of god, THIS NEEDS *SO MUCH TESTING*
    private void grailMergeBlocksOutOfPlace(K[] array, int keys, int medianKey, int start, int blockCount, int blockLen, int finalLeftBlocks, int finalLen) {
        int currentBlock;
        int blockIndex = blockLen;
        
        this.currentBlockLen    = blockLen;
        this.currentBlockOrigin = this.grailGetSubarray(array, keys, medianKey);
        
        for(int keyIndex = 1; keyIndex < blockCount; keyIndex++, blockIndex += blockLen) {
            currentBlock = blockIndex - this.currentBlockLen;  
            
            Subarray nextBlockOrigin = this.grailGetSubarray(array, keys + keyIndex, medianKey);
            
            if(nextBlockOrigin == this.currentBlockOrigin) {
                System.arraycopy(array, start + currentBlock, array, start + currentBlock - blockLen, this.currentBlockLen);
                currentBlock = blockIndex;
                
                this.currentBlockLen = blockLen;
            }
            else {
                this.grailSmartMergeOutOfPlace(array, start + currentBlock, this.currentBlockLen, this.currentBlockOrigin, blockLen, blockLen);
            }
        }
        
        currentBlock = blockIndex - this.currentBlockLen;
        
        if(finalLen != 0) {
            if(this.currentBlockOrigin == Subarray.RIGHT) {
                System.arraycopy(array, start + currentBlock, array, start + currentBlock - blockLen, this.currentBlockLen);
                currentBlock = blockIndex;
                
                this.currentBlockLen    = blockLen * finalLeftBlocks;
                this.currentBlockOrigin = Subarray.LEFT;
            }
            else {
                this.currentBlockLen += blockLen * finalLeftBlocks;
            }
            
            this.grailMergeOutOfPlace(array, start + currentBlock, this.currentBlockLen, finalLen, blockLen);
        }
        else {
            System.arraycopy(array, start + currentBlock, array, start + currentBlock - blockLen, this.currentBlockLen);
        }
    }

    //TODO: Double-check "Merge Blocks" arguments
    private void grailCombineInPlace(K[] array, int keys, int start, int length, int subarrayLen, int blockLen, int mergeCount, int lastSubarray, boolean buffer) {
        int fullMerge = 2 * subarrayLen;
        
        for(int mergeIndex = 0; mergeIndex < mergeCount; mergeIndex++) {
            int offset = start + (mergeIndex * fullMerge);
            int blockCount = fullMerge / blockLen;
            
            this.grailInsertSort(array, keys, blockCount);
    
            // INCORRECT PARAMETER BUG FIXED: `block select sort` should be using `offset`, not `start`
            int medianKey = subarrayLen / blockLen;
            medianKey = this.grailBlockSelectSort(array, keys, offset, medianKey, blockCount, blockLen);
            
            if(buffer) {
                this.grailMergeBlocks(array, keys, keys + medianKey, offset, blockCount, blockLen, 0, 0);
            }
            else {
                this.grailLazyMergeBlocks(array, keys, keys + medianKey, offset, blockCount, blockLen, 0, 0);
            }
        }
    
        // INCORRECT CONDITIONAL/PARAMETER BUG FIXED: Credit to 666666t for debugging.
        if(lastSubarray != 0) {
            int offset = start + (mergeCount * fullMerge);
            int rightBlocks = lastSubarray / blockLen;
            
            this.grailInsertSort(array, keys, rightBlocks + 1);
            
            // INCORRECT PARAMETER BUG FIXED: `block select sort` should be using `offset`, not `start`
            int medianKey = subarrayLen / blockLen;
            medianKey = this.grailBlockSelectSort(array, keys, offset, medianKey, rightBlocks, blockLen);
    
            // MISSING BOUNDS CHECK BUG FIXED: `lastFragment` *can* be 0 if the `lastSubarray` is evenly
            //                                 divided into blocks. This prevents Grailsort from going
            //                                 out of bounds.
            int lastFragment = lastSubarray - (rightBlocks * blockLen);
            int leftBlocks;
            if(lastFragment != 0) {
                leftBlocks = this.grailCountFinalLeftBlocks(array, offset, rightBlocks, blockLen);
            }
            else {
                leftBlocks = 0;
            }
    
            int blockCount = rightBlocks - leftBlocks;
            
            //TODO: Double-check if this micro-optimization works correctly like the original
            if(blockCount == 0) {
                int leftLength = leftBlocks * blockLen;
                
                // INCORRECT PARAMETER BUG FIXED: these merges should be using `offset`, not `start`
                if(buffer) {
                    this.grailMergeForwards(array, offset, leftLength, lastFragment, blockLen);
                }
                else {
                    this.grailLazyMerge(array, offset, leftLength, lastFragment);
                }
            }
            else {
                if(buffer) {
                    this.grailMergeBlocks(array, keys, keys + medianKey, offset, blockCount, blockLen, leftBlocks, lastFragment);
                }
                else {
                    this.grailLazyMergeBlocks(array, keys, keys + medianKey, offset, blockCount, blockLen, leftBlocks, lastFragment);
                }
            }
        }
    
        if(buffer) {
            this.grailInPlaceBufferReset(array, start, length, blockLen);
        }
    }

    private void grailCombineOutOfPlace(K[] array, int keys, int start, int length, int subarrayLen, int blockLen, int mergeCount, int lastSubarray) {
        System.arraycopy(array, start - blockLen, this.externalBuffer, 0, blockLen);
        
        int fullMerge = 2 * subarrayLen;
        
        for(int mergeIndex = 0; mergeIndex < mergeCount; mergeIndex++) {
            int offset = start + (mergeIndex * fullMerge);
            int blockCount = fullMerge / blockLen;
            
            this.grailInsertSort(array, keys, blockCount);

            // INCORRECT PARAMETER BUG FIXED: `block select sort` should be using `offset`, not `start`
            int medianKey = subarrayLen / blockLen;
            medianKey = this.grailBlockSelectSort(array, keys, offset, medianKey, blockCount, blockLen);
            
            this.grailMergeBlocksOutOfPlace(array, keys, keys + medianKey, offset, blockCount, blockLen, 0, 0);
        }

        // INCORRECT CONDITIONAL/PARAMETER BUG FIXED: Credit to 666666t for debugging.
        if(lastSubarray != 0) {
            int offset = start + (mergeCount * fullMerge);
            int rightBlocks = lastSubarray / blockLen;
            
            this.grailInsertSort(array, keys, rightBlocks + 1);

            // INCORRECT PARAMETER BUG FIXED: `block select sort` should be using `offset`, not `start`
            int medianKey = subarrayLen / blockLen;
            medianKey = this.grailBlockSelectSort(array, keys, offset, medianKey, rightBlocks, blockLen);

            // MISSING BOUNDS CHECK BUG FIXED: `lastFragment` *can* be 0 if the `lastSubarray` is evenly
            //                                 divided into blocks. This prevents Grailsort from going
            //                                 out of bounds.
            int lastFragment = lastSubarray - (rightBlocks * blockLen);
            int leftBlocks;
            if(lastFragment != 0) {
                leftBlocks = this.grailCountFinalLeftBlocks(array, offset, rightBlocks, blockLen);
            }
            else {
                leftBlocks = 0;
            }
            
            int blockCount = rightBlocks - leftBlocks;
            
            if(blockCount == 0) {
                // INCORRECT PARAMETER BUG FIXED: this merge should be using `offset`, not `start`
                int leftLength = leftBlocks * blockLen;
                this.grailMergeOutOfPlace(array, offset, leftLength, lastFragment, blockLen);
            }
            else {
                this.grailMergeBlocksOutOfPlace(array, keys, keys + medianKey, offset, blockCount, blockLen, leftBlocks, lastFragment);
            }
        }

        this.grailOutOfPlaceBufferReset(array, start, length, blockLen);
        System.arraycopy(this.externalBuffer, 0, array, start - blockLen, blockLen);
    }

    // 'keys' are on the left side of array. Blocks of length 'subarrayLen' combined. We'll combine them in pairs
    // 'subarrayLen' is a power of 2. (2 * subarrayLen / blockLen) keys are guaranteed
    private void grailCombineBlocks(K[] array, int keys, int start, int length, int subarrayLen, int blockLen, boolean buffer) {
        int    fullMerge = 2 * subarrayLen;
        int   mergeCount = length /  fullMerge;
        int lastSubarray = length - (fullMerge * mergeCount);
    
        if(lastSubarray <= subarrayLen) {
            length -= lastSubarray;
            lastSubarray = 0;
        }
    
        // INCOMPLETE CONDITIONAL BUG FIXED: In order to combine blocks out-of-place, we must check if a full-sized
        //                                   block fits into our external buffer.
        if(buffer && blockLen <= this.externalBufferLen) {
            this.grailCombineOutOfPlace(array, keys, start, length, subarrayLen, blockLen, mergeCount, lastSubarray);
        }
        else {
            this.grailCombineInPlace(array, keys, start, length, subarrayLen, blockLen, mergeCount, lastSubarray, buffer);
        }
    }

    // "Classic" in-place merge sort using binary searches and rotations
    //
    // cost: min(leftLen, rightLen)^2 + max(leftLen, rightLen)
    private void grailLazyMerge(K[] array, int start, int leftLen, int rightLen) {
        if(leftLen < rightLen) {
            while(leftLen != 0) {
                int insertPos = this.grailBinarySearchLeft(array, start + leftLen, rightLen, array[start]);

                if(insertPos != 0) {
                    this.grailRotate(array, start, leftLen, insertPos);
                    start    += insertPos;
                    rightLen -= insertPos;
                }

                if(rightLen == 0) {
                    break;
                }
                else {
                    do {
                        start++;
                        leftLen--;
                    } while(leftLen != 0 && this.grailComp.compare(array[start          ],
                                                                   array[start + leftLen]) <= 0);
                }
            }
        }
        // INDEXING BUG FIXED: Credit to Anonymous0726 for debugging.
        else {
            int end = start + leftLen + rightLen - 1;
            while(rightLen != 0) {            
                int insertPos = this.grailBinarySearchRight(array, start, leftLen, array[end]);

                if(insertPos != leftLen) {
                    this.grailRotate(array, start + insertPos, leftLen - insertPos, rightLen);
                    end    -= leftLen - insertPos;
                    leftLen = insertPos;
                }

                if(leftLen == 0) {
                    break;
                }
                else {
                    int leftEnd = start + leftLen - 1;
                    do {
                        rightLen--;
                        end--;
                    } while(rightLen != 0 && this.grailComp.compare(array[leftEnd],
                                                                    array[    end]) <= 0);
                }
            }
        }
    }
    
    private void grailLazyStableSort(K[] array, int start, int length) {
        for(int index = 1; index < length; index += 2) {
            int  left = start + index - 1;
            int right = start + index; 
            
            if(this.grailComp.compare(array[left], array[right]) > 0) {
                this.grailSwap(array, left, right);
            }
        }
        for(int mergeLen = 2; mergeLen < length; mergeLen *= 2) {
            int fullMerge = 2 * mergeLen;
            
            int mergeIndex;
            int mergeEnd = length - fullMerge;
            
            for(mergeIndex = 0; mergeIndex <= mergeEnd; mergeIndex += fullMerge) {
                this.grailLazyMerge(array, start + mergeIndex, mergeLen, mergeLen);
            }
            
            int leftOver = length - mergeIndex;
            if(leftOver > mergeLen) {
                this.grailLazyMerge(array, start + mergeIndex, mergeLen, leftOver - mergeLen);
            }
        }
    }
    
    private static int calcMinKeys(int numKeys, long blockKeysSum) {
        int minKeys = 1;
        while(minKeys < numKeys && blockKeysSum != 0) {
           minKeys *= 2;
           blockKeysSum /= 8;
        }
        return minKeys; 
     }
    
    protected void grailCommonSort(K[] array, int start, int length, K[] extBuf, int extBufLen) {
        if(length < 16) {
            this.grailInsertSort(array, start, length);
            return;
        }
        else {
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
            int keysFound = this.grailCollectKeys(array, start, length, idealKeys);
            
            boolean idealBuffer;
            if(keysFound < idealKeys) {
                if(keysFound < 4) {
                    // GRAILSORT STRATEGY 3 -- No block swaps or scrolling buffer; resort to Lazy Stable Sort
                    this.grailLazyStableSort(array, start, length);
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
            
            if(idealBuffer && extBuf != null) {
                // GRAILSORT + EXTRA SPACE
                this.externalBuffer = extBuf;
                this.externalBufferLen = extBufLen;
            }
            
            this.grailBuildBlocks(array, start + bufferEnd, length - bufferEnd, subarrayLen);
            
            while((length - bufferEnd) > (2 * subarrayLen)) {
                subarrayLen *= 2;

                int currentBlockLen = blockLen;
                boolean scrollingBuffer = idealBuffer;

                //TODO: Credit peeps from #rewritten-grail-discussions for helping clear up ambiguity
                if(!idealBuffer) {
                    //TODO: Explain this incredibly confusing math AND credit Bee sort and Anon
                    int halfKeyLen = keyLen / 2;
                    if(halfKeyLen * halfKeyLen >= 2 * subarrayLen) {
                        currentBlockLen = halfKeyLen;
                        scrollingBuffer = true;
                    }
                    else {
                        long blockKeysSum = ((long) subarrayLen * keysFound) / 2;
                        int minKeys = GrailSort.calcMinKeys(keyLen, blockKeysSum);

                        currentBlockLen = (2 * subarrayLen) / minKeys;
                    }
                }

                // WRONG VARIABLE BUG FIXED: 4th argument should be `length - bufferEnd`, was `length - bufferLen` before.
                // Credit to 666666t and Anonymous0726 for debugging.
                this.grailCombineBlocks(array, start, start + bufferEnd, length - bufferEnd, subarrayLen, currentBlockLen, scrollingBuffer);
            }
            
            this.grailInsertSort(array, start, bufferEnd);
            this.grailLazyMerge(array, start, bufferEnd, length - bufferEnd);
        }
    }
    
    public void grailSortInPlace(K[] array, int start, int length) {
        this.grailCommonSort(array, start, length, null, 0);
    }
    
    // Credit to Anonymous0726 for `array[0].getClass()` idea
    @SuppressWarnings("unchecked")
    public void grailSortStaticOOP(K[] array, int start, int length) {
        K[] buffer = (K[]) Array.newInstance(array.getClass().getComponentType(), GRAIL_STATIC_EXT_BUF_LEN);
        this.grailCommonSort(array, start, length, buffer, GRAIL_STATIC_EXT_BUF_LEN);
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
