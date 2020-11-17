# additional functions
def compareVal(a, b):
    return (a > b) - (a < b) 

def arrayCopy(fromArray, fromIndex, toArray, toIndex, length):   # thanks to Bee Sort for improving readability on this function
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
 #                       Bee sort
 #                       _fluffyy
 #                       Morwenn
 #                       
 # Special thanks to "The Studio" Discord community!
 #
class Subarray:
    LEFT = 0
    RIGHT = 1

# REWRITTEN GRAILSORT FOR PYTHON - A heavily refactored C/C++-to-Python version of
#                                  Andrey Astrelin's GrailSort.h, aiming to be as
#                                  readable and intuitive as possible.
#
# ** Written and maintained by The Holy Grail Sort Project
#
# Primary author: thatsOven
#
# Current status: Potentially working 

class GrailSort:

    externalBuffer = [] #TODO Check these definitions
    externalBufferLength = 0
    currentBlockLen = 0

    GRAIL_STATIC_EXT_BUF_LEN = 512

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
                start    += leftLen
                rightLen -= leftLen
            else:
                self.grailBlockSwap(array, start + leftLen - rightLen, start + leftLen, rightLen)
                leftLen -= rightLen
    
    def grailInsertSort(self, array, start, length):
        for item in range(1, length):
            left  = start + item - 1
            right = start + item

            while left >= start and array[left] > array[right]:
                self.grailSwap(array, left, right)
                left  -= 1
                right -= 1

    def grailBinarySearchLeft(self, array, start, length, target):
        left  = 0
        right = length
        while left < right:
            middle = left + ((right - left) // 2)
            if array[start + middle] < target:
                left = middle + 1
            else: 
                right = middle
        return left

    def grailBinarySearchRight(self, array, start, length, target):
        left  = 0
        right = length
        while left < right:
            middle = left + ((right - left) // 2)
            if array[start + middle] > target:
                right = middle
            else:
                left = middle + 1
        return right

    def grailCollectKeys(self, array, start, length, idealKeys):
        keysFound  = 1
        firstKey   = 0
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
            left  = start + index - 1
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
            left  = start + index - 1
            right = start + index

            if array[left] > array[right]:
                array[left - 2], array[right - 2] = array[right], array[left]
            else:
                array[left - 2], array[right - 2] = array[left], array[right]

            left = start + index - 1
            if left < start + length:
                array[left - 2] = array[left]

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
        
    def grailMergeOutOfPlace(self, array, start, leftLen, rightLen, bufferOffset):
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

    def grailBuildOutOfPlace(self, array, start, length, bufferLen, externLen):
        arrayCopy(array, start - externLen, self.externalBuffer, 0, externLen)

        self.grailPairwiseWrites(array, start, length)
        start -= 2

        mergeLen = 2
        while mergeLen < externLen:
            mergeEnd     = start + length - (2 * mergeLen)
            bufferOffset = mergeLen

            mergeIndex = start
            while mergeIndex <= mergeEnd:
                self.grailMergeOutOfPlace(array, mergeIndex, mergeLen, mergeLen, bufferOffset)
                mergeIndex += (2 * mergeLen)

            leftOver = length - (mergeIndex - start)

            if leftOver > mergeLen:
                self.grailMergeOutOfPlace(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset)
            else:
                #TODO: Is this correct?? (from Java code)
                for offset in range(0, leftOver):
                    array[mergeIndex + offset - mergeLen] = array[mergeIndex + offset]
            
            start -= mergeLen
            mergeLen *= 2

        arrayCopy(self.externalBuffer, 0, array, start+length, externLen)
        self.grailBuildInPlace(array, start, length, mergeLen, bufferLen)

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

    def grailBlockSelectSort(self, array, keys, start, medianKey, blockCount, blockLen):
        for block in range(1, blockCount):
            left  = block - 1
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

                    if   medianKey == left:  medianKey = right
                    elif medianKey == right: medianKey = left

        return medianKey 

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

    def grailGetSubarray(self, array, currentKey, medianKey):
        if array[currentKey] < array[medianKey] : return Subarray.LEFT
        else                                    : return Subarray.RIGHT

    def grailCountFinalLeftBlocks(self, array, offset, blockCount, blockLen):
        leftBlocks = 0

        firstRightBlock = offset + (blockCount * blockLen)
        prevLeftBlock   = firstRightBlock - blockLen

        while (leftBlocks < blockCount) and (array[firstRightBlock] < array[prevLeftBlock]):
            leftBlocks += 1
            prevLeftBlock -= blockLen

        return leftBlocks

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

    def grailMergeBlocks(self, array, keys, medianKey, start, blockCount, blockLen, finalLeftBlocks, finalLen):
        blockIndex = blockLen

        self.currentBlockLen    = blockLen
        self.currentBlockOrigin = self.grailGetSubarray(array, keys, medianKey)

        for keyIndex in range(1, blockCount):
            currentBlock = blockIndex - self.currentBlockLen

            nextBlockOrigin = self.grailGetSubarray(array, keys + keyIndex, medianKey)

            if nextBlockOrigin == self.currentBlockOrigin:
                self.grailBlockSwap(array, start + currentBlock - blockLen, start + currentBlock, self.currentBlockLen)
                currentBlock = blockIndex

                self.currentBlockLen = blockLen

            else:
                self.grailSmartMerge(array, start + currentBlock, self.currentBlockLen, self.currentBlockOrigin, blockLen, blockLen)

            blockIndex += blockLen

        currentBlock = blockIndex - self.currentBlockLen

        if finalLen != 0:
            if self.currentBlockOrigin == Subarray.RIGHT:
                self.grailBlockSwap(array, start + currentBlock - blockLen, start + currentBlock, self.currentBlockLen)
                currentBlock = blockIndex

                self.currentBlockLen    = blockLen * finalLeftBlocks
                self.currentBlockOrigin = Subarray.LEFT

            else:
                self.currentBlockLen += blockLen * finalLeftBlocks

            self.grailMergeForwards(array, start + currentBlock, self.currentBlockLen, finalLen, blockLen)
        else:
            self.grailBlockSwap(array, start + currentBlock, start + currentBlock - blockLen)
            
    def grailLazyMergeBlocks(self, array, keys, medianKey, start, blockCount, blockLen, finalLeftBlocks, finalLen):
        blockIndex = blockLen

        self.currentBlockLen    = blockLen
        self.currentBlockOrigin = self.grailGetSubarray(array, keys, medianKey)

        for keyIndex in range(1, blockCount):
            currentBlock = blockIndex - self.currentBlockLen

            nextBlockOrigin = self.grailGetSubarray(array, keys + keyIndex, medianKey)

            if nextBlockOrigin == self.currentBlockOrigin:
                currentBlock = blockIndex

                self.currentBlockLen = blockLen
            
            else:
                # These checks were included in the original code... but why??? (from Java code)
                if blockLen != 0 and self.currentBlockLen != 0:
                    self.grailSmartLazyMerge(array, start + currentBlock, self.currentBlockLen, self.currentBlockOrigin, blockLen)
                
            blockIndex += blockLen

        currentBlock = blockIndex - self.currentBlockLen

        if finalLen != 0:
            if self.currentBlockOrigin == Subarray.RIGHT:
                currentBlock = blockIndex

                self.currentBlockLen = blockLen * finalLeftBlocks
                self.currentBlockOrigin = Subarray.LEFT
            
            else:
                self.currentBlockLen += blockLen * finalLeftBlocks

            self.grailLazyMerge(array, start + currentBlock, self.currentBlockLen, finalLen)

    def grailMergeBlocksOutOfPlace(self, array, keys, medianKey, start, blockCount, blockLen, finalLeftBlocks, finalLen):
        blockIndex = blockLen

        self.currentBlockLen    = blockLen
        self.currentBlockOrigin = self.grailGetSubarray(array, keys, medianKey)
    
        for keyIndex in range(1, blockCount):
            currentBlock = blockIndex - self.currentBlockLen

            nextBlockOrigin = self.grailGetSubarray(array, keys + keyIndex, medianKey)

            if nextBlockOrigin == self.currentBlockOrigin:
                arrayCopy(array, start + currentBlock, array, start + currentBlock - blockLen, self.currentBlockLen)
                currentBlock = blockIndex

                self.currentBlockLen = blockLen

            else:
                self.grailSmartMergeOutOfPlace(array, start + currentBlock, self.currentBlockLen, self.currentBlockOrigin, blockLen, blockLen)

            blockIndex += blockLen

        currentBlock = blockIndex - self.currentBlockLen

        if finalLen != 0:
            if self.currentBlockOrigin == Subarray.RIGHT:
                arrayCopy(array, start + currentBlock, array, start + currentBlock - blockLen, self.currentBlockLen)
                currentBlock = blockIndex

                self.currentBlockLen    = blockLen * finalLeftBlocks
                self.currentBlockOrigin = Subarray.LEFT

            else:
                self.currentBlockLen += blockLen * finalLeftBlocks

            self.grailMergeOutOfPlace(array, start + currentBlock, self.currentBlockLen, finalLen, blockLen)
        else:
            arrayCopy(array, start + currentBlock, array, start + currentBlock - blockLen, self.currentBlockLen)           

    def grailCombineInPlace(self, array, keys, start, length, subarrayLen, blockLen, mergeCount, lastSubarray, buffer):
        fullMerge = 2 * subarrayLen
        blockCount = fullMerge / blockLen
        
        for mergeIndex in range(0, mergeCount):
            offset = start + (mergeIndex * fullMerge)
            blockCount = fullMerge // blockLen

            self.grailInsertSort(array, keys, blockCount)

            medianKey = subarrayLen // blockLen
            medianKey = self.grailBlockSelectSort(array, keys, offset, medianKey)

            if buffer:
                self.grailMergeBlocks(array, keys, keys + medianKey, offset, blockCount, blockLen, 0, 0)
            else:
                self.grailLazyMergeBlocks(array, keys, keys + medianKey, offset, blockCount, blockLen, 0, 0)

        if lastSubarray != 0:
            offset = start + (mergeCount * fullMerge)
            rightBlocks = lastSubarray // blockLen

            self.grailInsertSort(array, keys, rightBlocks + 1)

            medianKey = subarrayLen // blockLen
            medianKey = self.grailBlockSelectSort(array, keys, offset, medianKey, rightBlocks, blockLen)

            lastFragment = lastSubarray - (rightBlocks * blockLen)
            if lastFragment != 0:
                leftBlocks = self.grailCountFinalLeftBlocks(array, offset, rightBlocks, blockLen)
            else:
                leftBlocks = 0

            blockCount = rightBlocks - leftBlocks

            if blockCount == 0:
                leftLength = leftBlocks * blockLen

                if buffer:
                    self.grailMergeForwards(array, offset, leftLength, lastFragment, blockLen)
                else:
                    self.grailLazyMerge(array, offset, leftLength, lastFragment)

            else:
                if buffer:
                    self.grailMergeBlocks(array, keys, keys + medianKey, offset, blockCount, blockLen, leftBlocks, lastFragment)
                else:
                    self.grailLazyMergeBlocks(array, keys, keys + medianKey, offset, blockCount, blockLen, leftBlocks, lastFragment)

        if buffer:
            self.grailInPlaceBufferReset(array, start, length, blockLen)

    def grailCombineOutOfPlace(self, array, keys, start, length, subarrayLen, blockLen, mergeCount, lastSubarray):
        arrayCopy(array, start - blockLen, self.externalBuffer, 0, blockLen)

        fullMerge = 2* subarrayLen

        for mergeIndex in range(0, mergeCount):
            offset     = start + (mergeIndex * fullMerge)
            blockCount = fullMerge // blockLen

            self.grailInsertSort(array, keys, blockCount)

            medianKey = subarrayLen // blockLen
            medianKey = self.grailBlockSelectSort(array, keys, offset, medianKey, blockCount, blockLen)

            self.grailMergeBlocksOutOfPlace(array, keys, keys + medianKey, offset, blockCount, blockLen, 0, 0)

        if lastSubarray != 0:
            offset = start + (mergeCount * fullMerge)
            rightBlocks = lastSubarray // blockLen

            self.grailInsertSort(array, keys, rightBlocks + 1)

            medianKey = subarrayLen // blockLen
            medianKey = self.grailBlockSelectSort(array, keys, offset, medianKey, rightBlocks, blockLen)

            lastFragment = lastSubarray - (rightBlocks * blockLen)

            if lastFragment != 0:
                leftBlocks = self.grailCountFinalLeftBlocks(array, offset, rightBlocks, blockLen)
            else:
                leftBlocks = 0

            blockCount = rightBlocks - leftBlocks

            if blockCount == 0:
                leftLength = leftBlocks * blockLen
                self.grailMergeOutOfPlace(array, offset, leftLength, lastFragment, blockLen)
            else:
                self.grailMergeBlocksOutOfPlace(array, keys, keys + medianKey, offset, blockCount, blockLen, leftBlocks, lastFragment)
        
        self.grailOutOfPlaceBufferReset(array, start, length, blockLen)
        arrayCopy(self.externalBuffer, 0, array, start - blockLen, blockLen)

    def grailCombineBlocks(self, array, keys, start, length, subarrayLen, blockLen, buffer):
        fullMerge    = 2 * subarrayLen
        mergeCount   = length // fullMerge
        lastSubarray = length - (fullMerge * mergeCount)

        if lastSubarray <= subarrayLen:
            length -= lastSubarray
            lastSubarray = 0

        if buffer and blockLen <= self.externalBufferLength:
            self.grailCombineOutOfPlace(array, keys, start, length, subarrayLen, blockLen, mergeCount, lastSubarray)
        else:
            self.grailCombineInPlace(array, keys, start, length, subarrayLen, blockLen, mergeCount, lastSubarray, buffer)

    def grailLazyMerge(self, array, start, leftLen, rightLen):
        if leftLen < rightLen:
            while leftLen != 0:
                insertPos = self.grailBinarySearchLeft(array, start + leftLen, rightLen, array[start])

                if insertPos != 0:
                    self.grailRotate(array, start, leftLen, insertPos)
                    start    += insertPos
                    rightLen -= insertPos

                if rightLen == 0: break
                else:
                    condition = True
                    while condition:
                        start += 1
                        leftLen -= 1
                        condition = leftLen != 0 and array[start] <= array[start + leftLen]

        else:
            end = start + leftLen + rightLen - 1
            while rightLen != 0:
                insertPos = self.grailBinarySearchRight(array, start, leftLen, array[end])

                if insertPos != leftLen:
                    self.grailRotate(array, start + insertPos, leftLen - insertPos, rightLen)
                    end     -= leftLen - insertPos
                    leftLen  = insertPos

                if leftLen == 0: break
                else:
                    leftEnd = start + leftLen - 1
                    condition = True
                    while condition:
                        rightLen -= 1
                        end -= 1
                        condition = rightLen != 0 and array[leftEnd] <= array[end]


    def grailLazyStableSort(self, array, start, length):
        for index in range(1, length, 2):
            left = start + index - 1
            right = start + index

            if array[left] > array[right]:
                self.grailSwap(array, left, right)

        mergeLen = 2
        while mergeLen < length:
            fullMerge = 2 * mergeLen

            mergeEnd = length -fullMerge

            for mergeIndex in range(0, mergeEnd+1, fullMerge):
                self.grailLazyMerge(array, start + mergeIndex, mergeLen, mergeLen)

            leftOver = length - mergeIndex
            if leftOver > mergeLen:
                self.grailLazyMerge(array, start + mergeIndex, mergeLen, leftOver - mergeLen)
            mergeLen *= 2

    def calcMinKeys(self, numKeys, blockKeysSum):
        minKeys = 1
        while minKeys < numKeys and blockKeysSum != 0:
            minKeys *= 2
            blockKeysSum = blockKeysSum // 8
        return minKeys

    def grailCommonSort(self, array, start, length, extBuf, extBufLen):
        if length < 16:
            self.grailInsertSort(array, start, length)
            return
        else:
            blockLen = 1

            while (blockLen ** 2) < length: blockLen *= 2

            keyLen = ((length - 1) / blockLen) + 1

            idealKeys = keyLen + blockLen

            keysFound = self.grailCollectKeys(array, start, length, idealKeys)

            if keysFound < idealKeys:
                if keysFound < 4:
                    self.grailLazyStableSort(array, start, length)
                    return
                else:
                    keyLen = blockLen
                    blockLen = 0
                    idealBuffer = False

                    while keyLen > keysFound:
                        keyLen = keyLen // 2
            
            else: idealBuffer = True

            bufferEnd = blockLen + keyLen
            if idealBuffer: subarrayLen = blockLen
            else:           subarrayLen = keyLen

            if idealBuffer and extBuf != None:
                self.externalBuffer = extBuf
                self.externalBufferLength = extBufLen

            self.grailBuildBlocks(array, start + bufferEnd, length - bufferEnd, subarrayLen)

            while (length - bufferEnd) > (2 * subarrayLen):
                subarrayLen *= 2

                currentBlockLen = blockLen
                scrollingBuffer = idealBuffer

                if not idealBuffer:
                    halfKeyLen = keyLen // 2
                    if halfKeyLen ** 2 >= 2 * subarrayLen:
                        currentBlockLen = halfKeyLen
                        scrollingBuffer = True

                    else:
                        blockKeysSum = (subarrayLen * keysFound) / 2
                        minKeys = self.calcMinKeys(keyLen, blockKeysSum)

                        currentBlockLen = (2 * subarrayLen) / minKeys

                self.grailCombineBlocks(array, start, start + bufferEnd, length - bufferEnd, subarrayLen, currentBlockLen, scrollingBuffer)

            self.grailInsertSort(array, start, bufferEnd)
            self.grailLazyMerge(array, start, bufferEnd, length - bufferEnd)

    def grailSortInPlace(array, start, length):
        self.grailCommonSort(array, start, length, None, 0)

    def grailSortStaticOOP(array, start, length):
        buffer = [0 for _ in range (self.GRAIL_STATIC_EXT_BUF_LEN)]
        self.grailCommonSort(array, start, length, buffer, self.GRAIL_STATIC_EXT_BUF_LEN)

    def grailSortDynamicOOP(array, start, length):
        bufferLen = 1
        while (bufferLen ** 2) < length: bufferLen *= 2

        buffer = [0 for _ in range(bufferLen)]

        self.grailCommonSort(array, start, length, buffer, bufferLen)
                
