# additional functions
def compareVal(a, b):
    return (a > b) - (a < b) 

def arrayCopy(fromArray, fromIndex, toArray, toIndex, length):
    toArray[toIndex:toIndex + length] = fromArray[fromIndex:fromIndex + length]


 #
 # MIT License
 # 
 # Copyright (c) 2013 Andrey Astrelin
 # Copyright (c) 2020 The Holy Grail Sort Project
 # 
 # Permission is hereby granted, free of charge, to any person obtaining a copy
 # of this software and associated documentation files (the "Software"), to deal
 # in the Software without restriction, including without limitation the rights
 # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 # copies of the Software, and to permit persons to whom the Software is
 # furnished to do so, subject to the following conditions:
 # 
 # The above copyright notice and this permission notice shall be included in all
 # copies or substantial portions of the Software.
 # 
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 # SOFTWARE.
 #
 #
 # The Holy Grail Sort Project
 # Project Manager:      Summer Dragonfly
 # Project Contributors: 666666t
 #                       Anonymous0726
 #                       aphitorite
 #                       dani_dlg
 #                       EilrahcF
 #                       Enver
 #                       lovebuny
 #                       MP
 #                       phoenixbound
 #                       thatsOven
 #                       
 # Special thanks to "The Studio" Discord community!
 #
class Subarray:
    LEFT = 0
    RIGHT = 0

# REWRITTEN GRAILSORT FOR PYTHON - A heavily refactored C/C++-to-Python version of
#                                  Andrey Astrelin's GrailSort.h, aiming to be as
#                                  readable and intuitive as possible.
#
# ** Written and maintained by The Holy Grail Sort Project
#
# Primary author: thatsOven
#
# Current status: Not finished yet! 

class GrailSort:

    externalBuffer = [] #TODO Check these definitions
    externalBufferLength = 0
    currentBlockLen = 0

    def __init__(self, grailKeys):
        self.grailKeys = grailKeys
        self.staticExternalBufferLen = 512

    def grailSwap(self, array, a, b):
        array[a], array[b] = array[b], array[a]
    
    def grailBlockSwap(self, array, a, b, swapsLeft):
        swaps = 0
        for _ in range(swapsLeft, 0, -1):
            self.grailSwap(array, a + swaps, b + swaps)
            swaps += 1

    def grailRotate(self, array, start, leftLen, rightLen):
        while leftLen > 0 and rightLen > 0:
            if leftLen <= rightLen:
                self.grailBlockSwap(array, start, start + leftLen, leftLen)
                start += leftLen
                rightLen -= leftLen
            else:
                self.grailBlockSwap(array, start + leftLen - rightLen, start + leftLen, rightLen)
                leftLen -= rightLen
    
    def grailBinarySearchLeft(self, array, start, length, target):
        left = 0
        right = length
        while left < right:
            middle = left + ((right - left) // 2)
            if array[start + middle] < target:
                left = middle + 1
            else:
                right = middle
        return left

    def grailBinarySearchRight(self, array, start, length, target):
        left = 0
        right = length
        while left < right:
            middle = left + ((right - left) // 2)
            if array[start + middle] > target:
                right = middle
            else:
                left = middle + 1
        return right

    def grailCollectKeys(self, array, start, length, idealKeys):
        keysFound = 1
        firstKey = 0
        currentKey = 1

        while currentKey < length and keysFound < idealKeys:

            insertPos = self.grailBinarySearchLeft(array, start + firstKey, keysFound, array[start + currentKey].key)

            if insertPos == keysFound or not array[start + currentKey].key == array[start + firstKey + insertPos].key:

                self.grailRotate(array, start + firstKey, keysFound, currentKey - (firstKey + keysFound))

                firstKey = currentKey - keysFound

                self.grailRotate(array, start + firstKey + insertPos, keysFound - insertPos, 1)

                keysFound += 1

            currentKey += 1

        self.grailRotate(array, start, firstKey, keysFound)
        return keysFound

    def grailPairwiseSwaps(self, array, start, length):
        for index in range(1, length, 2):
            left = start + index - 1
            right = start + index

            if array[left].key > array[right].key:
                self.grailSwap(array,  left - 2, right)
                self.grailSwap(array, right - 2,  left)
            else:
                self.grailSwap(array,  left - 2,  left)
                self.grailSwap(array, right - 2, right)
        
        left = start + index - 1
        if left < start + length:
            self.grailSwap(array, left - 2, left)

    def grailPairwiseWrites(self, array, start, length):
        for index in range(1, length, 2):
            left = start + index - 1
            right = start + index

            if array[left] > array[right]:
                array[left - 2], array[right - 2] = array[right], array[left]
            else:
                array[left - 2], array[right - 2] = array[left], array[right]

            left = start + index - 1
            if left < start + length:
                array[left - 2] = array[left]

    def grailBlockSelectSort(self, array, keys, start, medianKey, blockCount, blockLen):
        for block in range(1, blockCount):
            left = block - 1
            right = left

            for index in range(block, blockCount):
                compare = compareVal(   array[start + (right * blockLen)], 
                                        array[start + (index * blockLen)]   )
                
                if compare > 0 or (compare == 0 and compareVal( array[keys + right], 
                                                                array[keys + index]) > 0 ):
                    right = index

                if right != left:

                    self.grailBlockSwap(array, start + (left * blockLen), start + (right * blockLen), blockLen)

                    self.grailSwap(array, keys + left, keys + right)

                    if medianKey == left: medianKey = right
                    elif medianKey == right: medianKey = left

        return medianKey

    def grailMergeForwards(self, array, start, leftLen, rightLen, bufferOffset):
        left   = start
        middle = start + leftLen
        right  = middle
        end    = middle + rightLen
        buffer = start - bufferOffset

        while right < end:
            if left == middle or array[left] > array[right]:

                self.grailSwap(array, buffer, right)
                right += 1
            else:
                self.grailSwap(array, buffer, left)
                left += 1
            buffer += 1

            if buffer != left:
                self.grailBlockSwap(array, buffer, left, middle-left)
                                
    def grailMergeBackwards(self, array, start, leftLen, rightLen, bufferOffset):
        left   = start + leftLen - 1
        middle = left
        right  = middle + rightLen
        end    = start
        buffer = right + bufferOffset

        while left >= end:
            if right == middle or array[left] > array[right]:

                self.grailSwap(array, buffer, left)
                left -= 1
            else:
                self.grailSwap(array, buffer, right)
                right -= 1
            buffer -= 1

        if right != buffer:
            while right > middle:
                self.grailSwap(array, buffer, right)
                buffer -= 1
                right -= 1
        
    def grailOutOfPlaceMerge(self, array, start, leftLen, rightLen, bufferOffset):
        left   = start
        middle = start + leftLen
        right  = middle
        end    = middle + rightLen
        buffer = start - bufferOffset
        
        while right < end:
            if left == middle or array[left] > array[right]:

                array[buffer] = array[right]
                right += 1
            else:
                array[buffer] = array[left]
                left += 1
            buffer += 1

        if buffer != left:
            while left < middle:
                array[buffer] = array[left]
                buffer += 1
                left += 1
    
    def grailInPlaceBufferReset(self, array, start, resetLen, bufferLen):
        index = start + resetLen - 1
        while index >= 0:
            self.grailSwap(array, start + index, start + index - bufferLen)
            index -= 1

    def grailOutOfPlaceBufferReset(self, array, start, resetLen, bufferLen):
        index = start + resetLen
        while index >= 0:
            array[index] = array[index - bufferLen]
            index -= 1

    def grailInPlaceBufferRewind(self, array, start, buffer, leftOvers):
        while start < buffer:
            buffer -= 1
            leftOvers -= 1
            self.grailSwap(array, buffer, leftOvers)

    def grailOutOfPlaceBufferRewind(self, array, start, buffer, leftOvers):
        while start < buffer:
            buffer -= 1
            leftOvers -= 1
            array[buffer] = array[leftOvers]

    def grailBuildBlocks(self, array, start, length, bufferLen):
        if self.externalBuffer is not None:
            if bufferLen < self.externalBufferLength:
                externLen = bufferLen
            else:
                externLen = 1
                while (externLen*2) <= self.externalBufferLength:
                    externLen *= 2
            self.grailBuildOutOfPlace(array, start, length, bufferLen, externLen)
        else:
            self.grailPairwiseSwaps(array, start, length)
            self.grailBuildInPlace(array, start - 2, length, 2, bufferLen)
        
    def grailBuildOutOfPlace(self, array, start, length, bufferLen, externLen):
        arrayCopy(array, start - externLen, self.externalBuffer, 0, externLen)

        self.grailPairwiseWrites(array, start, length)
        start -= 2

        mergeLen = 2
        while mergeLen < externLen:
            mergeEnd = start + length - (2 * mergeLen)
            bufferOffset = mergeLen

            mergeIndex = start
            while mergeIndex <= mergeEnd:
                self.grailOutOfPlaceMerge(array, mergeIndex, mergeLen, mergeLen, bufferOffset)
                mergeIndex += (2 * mergeLen)

            leftOver = length - (mergeIndex - start)

            if leftOver > mergeLen:
                self.grailOutOfPlaceMerge(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset)
            else:
                #TODO: Is this correct?? (from Java code)
                for offset in range(0, leftOver):
                    array[mergeIndex + offset - mergeLen] = array[mergeIndex + offset]
            
            start -= mergeLen
            mergeLen *= 2

        arrayCopy(self.externalBuffer, 0, array, start+length, externLen)
        self.grailBuildInPlace(array, start, length, mergeLen, bufferLen)

    def grailBuildInPlace(self, array, start, length, currentMerge, bufferLen):
        mergeLen = currentMerge
        while mergeLen < bufferLen:
            mergeEnd = start + length - (2 * mergeLen)
            bufferOffset = mergeLen

            mergeIndex = start
            while mergeIndex <= mergeEnd:
                self.grailMergeForwards(array, mergeIndex, mergeLen, mergeLen, bufferOffset)
                mergeIndex += (2 * mergeLen)

            leftOver = length - (mergeIndex - start)

            if leftOver > mergeLen:
                self.grailMergeForwards(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset)
            else:
                self.grailRotate(array, mergeIndex - mergeLen, mergeLen, leftOver)

            start -= mergeLen
            mergeLen *= 2
        
        finalBlock = length % (2 * bufferLen)
        finalOffset = start + length - finalBlock

        if finalBlock <= bufferLen:
            self.grailRotate(array, finalOffset, finalBlock, bufferLen)
        else:
            self.grailMergeBackwards(array, finalOffset, bufferLen, finalBlock - bufferLen, bufferLen)

        mergeIndex = finalOffset - (2 * bufferLen)
        while mergeIndex >= start:
            self.grailMergeBackwards(array, mergeIndex, bufferLen, bufferLen, bufferLen)
            mergeIndex -= (2 * bufferLen)

    def grailCountLeftBlocks(self, array, offset, blockCount, blockLen):
        leftBlocks = 0

        firstRightBlock = offset + (blockCount * blockLen)
        prevLeftBlock   = firstRightBlock - blockLen

        while (leftBlocks < blockCount) and (array[firstRightBlock] < array[prevLeftBlock]):
            leftBlocks += 1
            prevLeftBlock -= blockLen

        return leftBlocks

    def grailGetSubarray(self, array, currentKey, medianKey):
        if array[currentKey] < array[medianKey] : return Subarray.LEFT
        else                                    : return Subarray.RIGHT

    def grailSmartMergeOutOfPlace(self, array, start, leftLen, leftOrigin: Subarray, rightLen, bufferOffset):
        left   = start
        middle = start + leftLen
        right  = middle
        end    = middle + rightLen
        buffer = start - bufferOffset

        if leftOrigin == Subarray.LEFT:
            while (left < middle) and (right < end):
                if array[left] <= array[right]:
                    array[buffer] = array[left]
                    left += 1
                else:
                    array[buffer] = array[right]
                    right += 1
                buffer += 1

        else:
            while (left < middle) and (right < end):
                if array[left] < array[right]:
                    array[buffer] = array[left]
                    left += 1
                else:
                    array[buffer] = array[right]
                    right += 1
                buffer += 1

        if left < middle:
            self.currentBlockLen = middle - left
            self.grailOutOfPlaceBufferRewind(array, left, middle, end)
        else:
            self.currentBlockLen = end - right
            if leftOrigin == Subarray.LEFT:
                self.currentBlockOrigin = Subarray.RIGHT
            else:
                self.currentBlockOrigin = Subarray.LEFT

    def grailSmartMerge(self, array, start, leftLen, leftOrigin, rightLen, bufferOffset):
        left   = start
        middle = start + leftLen
        right  = middle
        end    = middle + rightLen
        buffer = start - bufferOffset

        if leftOrigin == Subarray.LEFT:
            while (left < middle) and (right < end):
                if array[left] <= array[right]:
                    self.grailSwap(array, buffer, left)
                    left += 1
                else:
                    self.grailSwap(array, buffer, right)
                    right += 1
                buffer += 1
        
        else:
            while (left < middle) and (right < end):
                if array[left] < array[right]:
                    self.grailSwap(array, buffer, left)
                    left += 1
                else:
                    self.grailSwap(array, buffer, right)
                    right += 1
                buffer += 1

        if left < middle:
            self.currentBlockLen = middle - left
            self.grailInPlaceBufferRewind(array, left, middle, end)
        else:
            self.currentBlockLen = end - right
            if leftOrigin < Subarray.LEFT:
                self.currentBlockOrigin = Subarray.RIGHT
            else:
                self.currentBlockOrigin = Subarray.LEFT

    def grailSmartLazyMerge(self, array, start, leftLen, leftOrigin, rightLen):
        if leftOrigin == Subarray.LEFT:
            if array[start + leftLen - 1] > array[start + leftLen]:
                while leftLen != 0:
                    insertPos = self.grailBinarySearchLeft(array, start + leftLen, rightLen, array[start])

                    if insertPos != 0:
                        self.grailRotate(array, start, leftLen, insertPos)
                        start    += insertPos
                        rightLen -= insertPos

                    if rightLen == 0:
                        self.currentBlockLen = leftLen
                        return
                    else:
                        condition = True
                        while condition:
                            start += 1
                            leftLen -= 1
                            condition = (leftLen != 0) and array[start] <= array[start + leftLen]
        else:
            if array[start + leftLen - 1] >= array[start + leftLen]:
                while leftLen != 0:
                    insertPos = self.grailBinarySearchRight(array, start + leftLen, rightLen, array[start])

                    if insertPos != 0:
                        self.grailRotate(array, start, leftLen, insertPos)
                        start    += insertPos
                        rightLen -= insertPos

                    if rightLen == 0:
                        self.currentBlockLen = leftLen
                        return
                    else:
                        condition = True
                        while condition:
                            start += 1
                            leftLen -= 1
                            condition = (leftLen !=  0) and (array[start] < array[start + leftLen])
        
        self.currentBlockLen = rightLen
        if leftOrigin == Subarray.LEFT:
            self.currentBlockOrigin = Subarray.RIGHT
        else:
            self.currentBlockOrigin = Subarray.LEFT

    
        
