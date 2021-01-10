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
 #                       Morwenn
 #                       MP
 #                       phoenixbound
 #                       thatsOven
 #                       Bee sort
 #                       _fluffyy
 #                       
 #                       
 # Special thanks to "The Studio" Discord community!

# REWRITTEN GRAILSORT FOR PYTHON - A heavily refactored C/C++-to-Python version of
#                                  Andrey Astrelin's GrailSort.h, aiming to be as
#                                  readable and intuitive as possible.
#
# ** Written and maintained by The Holy Grail Sort Project
#
# Primary author: thatsOven
#
# Current status: Potentially working (Untested)

class Subarray:
    LEFT, RIGHT = 0, 1

class GrailSort:

    GRAIL_STATIC_EXT_BUFFER_LEN = 512

    extBuffer = None
    extBufferLen = 0

    def grailSwap(self, array, a, b):
        array[a], array[b] = array[b], array[a]
    

    def grailBlockSwap(self, array, a, b, blockLen):
        for i in range(0, blockLen):
            self.grailSwap(array, a + i, b + i)


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
        currKey    = 1

        while currKey < length and keysFound < idealKeys:

            insertPos = self.grailBinarySearchLeft(array, start + firstKey, keysFound, array[start + currentKey])

            if insertPos == keysFound or array[start + currKey] != array[start + firstKey + insertPos]:

                self.grailRotate(array, start + firstKey, keysFound, currKey - (firstKey + keysFound))

                firstKey = currKey - keysFound

                self.grailRotate(array, start + firstKey + insertPos, keysFound - insertPos, 1)

                keysFound += 1

            currKey += 1

        self.grailRotate(array, start, firstKey, keysFound)
        return keysFound


    def grailPairwiseSwaps(self, array, start, length):
        index = 1
        while index < length:
            left  = start + index - 1
            right = start + index

            if array[left] > array[right]:
                self.grailSwap(array,  left - 2, right)
                self.grailSwap(array, right - 2,  left)
            else:
                self.grailSwap(array,  left - 2,  left)
                self.grailSwap(array, right - 2, right)
                
            index += 2
        
        left = start + index - 1
        if left < start + length:
            self.grailSwap(array, left - 2, left)


    def grailPairwiseWrites(self, array, start, length):
        index = 1
        while index < length:
            left  = start + index - 1
            right = start + index

            if array[left] > array[right]:
                array[left - 2], array[right - 2] = array[right], array[left]
            else:
                array[left - 2], array[right - 2] = array[left], array[right]

            index += 2

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
        end    = start - 1
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


    def grailBuildInPlace(self, array, start, length, currentLen, bufferLen):
        mergeLen = currentLen
        while mergeLen < bufferLen:
            fullMerge = 2 * mergeLen

            mergeEnd = start + length - fullMerge
            bufferOffset = mergeLen

            mergeIndex = start
            while mergeIndex <= mergeEnd:
                self.grailMergeForwards(array, mergeIndex, mergeLen, mergeLen, bufferOffset)

                mergeIndex += fullMerge

            leftOver = length - (mergeIndex - start)

            if leftOver > mergeLen:
                self.grailMergeForwards(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset)
            else:
                self.grailRotate(array, mergeIndex - mergeLen, mergeLen, leftOver)

            start -= mergeLen

            mergeLen *= 2

        fullMerge = 2 * bufferLen
        lastBlock = length % fullMerge
        lastOffset = start + length - lastBlock

        if lastBlock <= bufferLen:
            self.grailRotate(array, lastOffset, lastBlock, bufferLen)
        else:
            self.grailMergeBackwards(array, lastOffset, bufferLen, lastBlock - bufferLen, bufferLen)

        mergeIndex = lastOffset - fullMerge
        while mergeIndex >= start:
            self.grailMergeBackwards(array, mergeIndex, bufferLen, bufferLen, bufferLen)
            mergeIndex -= fullMerge

    
    def grailBuildOutOfPlace(self, array, start, length, bufferLen, extLen):
        arrayCopy(array, start - extLen, self.extBuffer, 0, extLen)

        self.grailPairwiseWrites(array, start, length)
        start -= 2

        mergeLen = 2
        while mergeLen < extLen:
            fullMerge = 2 * mergeLen

            mergeEnd = start + length - fullMerge
            bufferOffset = mergeLen

            mergeIndex = start
            while mergeIndex <= mergeEnd:
                self.grailMergeOutOfPlace(array, mergeIndex, mergeLen, mergeLen, bufferOffset)
                mergeIndex += fullMerge

            leftOver = length - (mergeIndex - start)

            if leftOver > mergeLen:
                self.grailMergeOutOfPlace(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset)
            else:
                arrayCopy(array, mergeIndex, array, mergeIndex - mergeLen, leftOver)

            start -= mergeLen
            mergeLen *= 2

        arrayCopy(self.extBuffer, 0, array, start + length, extLen)
        self.grailBuildInPlace(array, start, length, mergeLen, bufferLen)


    def grailBuildBlocks(self, array, start, length, bufferLen):
        if self.extBuffer is not None:
            if bufferLen < self.extBufferLen:
                extLen = bufferLen
            else:
                extLen = 1
                while (extLen*2) <= self.extBufferLen:
                    extLen *= 2
            self.grailBuildOutOfPlace(array, start, length, bufferLen, extLen)
        else:
            self.grailPairwiseSwaps(array, start, length)
            self.grailBuildInPlace(array, start - 2, length, 2, bufferLen)   

    
    def grailBlockSelectSort(self, array, firstKey, start, medianKey, blockCount, blockLen):
        for firstBlock in range(0, blockCount):
            selectBlock = firstBlock

            for currBlock in range(firstBlock + 1, blockCount):
                compare = compareVal(   array[start + (currBlock   * blockLen)],
                                        array[start + (selectBlock * blockLen)]     )

                if compare < 0 or (compare == 0 and array[firstKey + currBlock] < array[firstKey + selectBlock]):
                    selectBlock = currBlock

            if selectBlock != firstBlock:
                self.grailBlockSwap(array, start + (firstBlock * blockLen), start + (selectBlock * blockLen), blockLen)

                self.grailSwap(array, firstKey + firstBlock, firstKey + selectBlock)

                if   medianKey == firstBlock:  medianKey = selectBlock
                elif medianKey == selectBlock: medianKey = firstBlock

        return medianKey


    def grailInPlaceBufferReset(self, array, start, resetLen, bufferLen):
        index = start + resetLen - 1
        while index >= start:
            self.grailSwap(array, index, index - bufferLen)
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
        blocksToMerge = 0

        lastRightFrag = offset + (blockCount * blockLen)
        prevLeftBlock = lastRightFrag - blockLen

        while (blocksToMerge < blockCount) and (array[lastRightFrag] < array[prevLeftBlock]):
            blocksToMerge += 1
            prevLeftBlock -= blockLen

        return blocksToMerge


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
            self.currBlockLen = middle - left
            self.grailInPlaceBufferRewind(array, left, middle, end)
        else:
            self.currBlockLen = end - right
            if leftOrigin == Subarray.LEFT:
                self.currBlockOrigin = Subarray.RIGHT
            else:
                self.currBlockOrigin = Subarray.LEFT


    def grailSmartLazyMerge(self, array, start, leftLen, leftOrigin, rightLen):
        middle = start + leftLen

        if leftOrigin == Subarray.LEFT:
            if array[middle- 1] > array[middle]:
                while leftLen != 0:
                    mergeLen = self.grailBinarySearchLeft(array, middle, rightLen, array[start])

                    if mergeLen != 0:
                        self.grailRotate(array, start, leftLen, mergeLen)
                        start    += mergeLen
                        rightLen -= mergeLen

                    if rightLen == 0:
                        self.currBlockLen = leftLen
                        return
                    else:
                        condition = True
                        while condition:
                            start += 1
                            leftLen -= 1
                            condition = (leftLen != 0) and array[start] <= array[middle]
        else:
            if array[middle - 1] >= array[middle]:
                while leftLen != 0:
                    mergeLen = self.grailBinarySearchRight(array, middle, rightLen, array[start])

                    if mergeLen != 0:
                        self.grailRotate(array, start, leftLen, mergeLen)
                        start    += mergeLen
                        rightLen -= mergeLen

                    middle += mergeLen

                    if rightLen == 0:
                        self.currBlockLen = leftLen
                        return
                    else:
                        condition = True
                        while condition:
                            start += 1
                            leftLen -= 1
                            condition = (leftLen !=  0) and (array[start] < array[middle])
        
        self.currBlockLen = rightLen
        if leftOrigin == Subarray.LEFT:
            self.currBlockOrigin = Subarray.RIGHT
        else:
            self.currBlockOrigin = Subarray.LEFT


    def grailSmartMergeOutOfPlace(self, array, start, leftLen, leftOrigin, rightLen, bufferOffset):
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
            self.currBlockLen = middle - left
            self.grailOutOfPlaceBufferRewind(array, left, middle, end)
        else:
            self.currBlockLen = end - right
            if leftOrigin == Subarray.LEFT:
                self.currBlockOrigin = Subarray.RIGHT
            else:
                self.currBlockOrigin = Subarray.LEFT


    def grailMergeBlocks(self, array, firstKey, medianKey, start, blockCount, blockLen, lastMergeBlocks, lastLen):
        nextBlock = start + blockLen

        self.currBlockLen    = blockLen
        self.currBlockOrigin = self.grailGetSubarray(array, firstKey, medianKey)

        for keyIndex in range(1, blockCount):
            currBlock       = nextBlock - self.currBlockLen
            nextBlockOrigin = self.grailGetSubarray(array, firstKey + keyIndex)

            if nextBlockOrigin == self.currBlockOrigin:
                buffer = currBlock - blockLen

                self.grailBlockSwap(array, buffer, currBlock, self.currBlockLen)
                self.currBlockLen = blockLen
            else:
                self.grailSmartMerge(array, currBlock, self.currBlockLen, self.currBlockOrigin, blockLen, blockLen)

            nextBlock += blockLen
        
        currBlock = nextBlock - self.currBlockLen
        buffer    = currBlock - blockLen

        if lastLen != 0:
            if self.currBlockOrigin == Subarray.RIGHT:
                self.grailBlockSwap(array, buffer, currBlock, self.currBlockLen)

                currBlock            = nextBlock
                self.currBlockLen    = blockLen * lastMergeBlocks
                self.currBlockOrigin = Subarray.LEFT
            else:
                self.currBlockLen += blockLen * lastMergeBlocks

            self.grailMergeForwards(array, currBlock, self.currBlockLen, lastLen, blockLen)
        else:
            self.grailBlockSwap(array, buffer, currBlock, self.currBlockLen)

    
    def grailLazyMergeBlocks(self, array, firstKey, medianKey, start, blockCount, blockLen, lastMergeBlocks, lastLen):
        nextBlock = start + blockLen

        self.currBlockLen    = blockLen
        self.currBlockOrigin = self.grailGetSubarray(array, firstKey, medianKey)

        for keyIndex in range(1, blockCount):
            currBlock       = nextBlock - self.currBlockLen
            nextBlockOrigin = self.grailGetSubarray(array, firstKey + keyIndex, medianKey)

            if nextBlockOrigin == self.currBlockOrigin:
                self.currBlockLen = blockLen
            else:
                if blockLen != 0 and self.currBlockLen != 0:
                    self.grailSmartLazyMerge(array, currBlock, self.currBlockLen, self.currBlockOrigin, blockLen)

            nextBlock += blockLen
        
        currBlock = nextBlock - self.currBlockLen

        if lastLen != 0:
            if self.currBlockOrigin == Subarray.RIGHT:
                currBlock            = nextBlock
                self.currBlockLen    = blockLen * lastMergeBlocks
                self.currBlockOrigin = Subarray.LEFT
            else:
                self.currBlockLen += blockLen * lastMergeBlocks

            self.grailSmartLazyMerge(array, currBlock, self.currBlockLen, lastLen)


    def grailMergeBlocksOutOfPlace(self, array, firstKey, medianKey, start, blockCount, blockLen, lastMergeBlocks, lastLen):
        nextBlock = start + blockLen

        self.currBlockLen    = blockLen
        self.currBlockOrigin = self.grailGetSubarray(array, firstKey, medianKey)

        for keyIndex in range(1, blockCount):
            currBlock       = nextBlock - self.currBlockLen
            nextBlockOrigin = self.grailGetSubarray(array, firstKey + keyIndex, medianKey)

            if nextBlockOrigin == self.currBlockOrigin:
                buffer = currBlock - blockLen

                arrayCopy(array, currBlock, array, buffer, self.currBlockLen)
                self.currBlockLen = blockLen
            else:
                self.grailSmartMergeOutOfPlace(array, currBlock, self.currBlockLen, self.currBlockOrigin, blockLen, blockLen)

        currBlock = nextBlock - self.currBlockLen
        buffer    = currBlock - blockLen

        if lastLen != 0:
            if self.currBlockOrigin == Subarray.RIGHT:
                arrayCopy(array, currBlock, array, buffer, self.currBlockLen)

                currBlock            = nextBlock
                self.currBlockLen    = blockLen * lastMergeBlocks
                self.currBlockOrigin = Subarray.LEFT
            else:
                self.currBlockLen += blockLen * lastMergeBlocks

            self.grailMergeOutOfPlace(array, currBlock, self.currBlockLen, lastLen, blockLen)
        else:
            arrayCopy(array, currBlock, array, buffer, self.currBlockLen)

    
    def grailCombineInPlace(self, array, firstKey, start, length, subarrayLen, blockLen, mergeCount, lastSubarrays, buffer):
        fullMerge = 2 * subarrayLen
        blockCount = fullMerge // blockLen

        for mergeIndex in range(0, mergeCount):
            offset = start + (mergeIndex * fullMerge)

            self.grailInsertSort(array, firstKey, blockCount)

            medianKey = subarrayLen // blockLen
            medianKey = self.grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen)

            if buffer:
                self.grailMergeBlocks(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0)
            else:
                self.grailLazyMergeBlocks(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0)

        if lastSubarrays != 0:
            offset = start + (mergeCount * fullMerge)
            blockCount = lastSubarrays // blockLen

            self.grailInsertSort(array, firstKey, blockCount + 1)

            medianKey = subarrayLen // blockLen
            medianKey = self.grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen)

            lastFragment = lastSubarrays - (blockCount * blockLen)
            if lastFragment != 0:
                lastMergeBlocks = self.grailCountLastMergeBlocks(array, offset, blockCount, blockLen)
            else: lastMergeBlocks = 0

            smartMerges = blockCount - lastMergeBlocks

            if smartMerges == 0:
                leftLen = lastMergeBlocks * blockLen

                if buffer:
                    self.grailMergeForwards(array, offset, leftLen, lastFragment, blockLen)
                else:
                    self.grailLazyMerge(array, offset, leftLen, lastFragment)
            else:
                if buffer:
                    self.grailMergeBlocks(array, firstKey, firstKey + medianKey, offset, smartMerges, blockLen, lastMergeBlocks, lastFragment)
                else:
                    self.grailLazyMergeBlocks(array, firstKey, firstKey + medianKey, offset, smartMerges, blockLen, lastMergeBlocks, lastFragment)
            
            if buffer:
                self.grailInPlaceBufferReset(array, start, length, blockLen)

        
    def grailCombineOutOfPlace(self, array, firstKey, start, length, subarrayLen, blockLen, mergeCount, lastSubarrays):
        arrayCopy(array, start - blockLen, self.extBuffer, 0, blockLen)

        fullMerge = 2 * subarrayLen
        blockCount = fullMerge // blockLen

        for mergeIndex in range(0, mergeCount):
            offset = start + (mergeIndex * fullMerge)

            self.grailInsertSort(array, firstKey, blockCount)

            medianKey = subarrayLen // blockLen
            medianKey = self.grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen)

            self.grailMergeBlocksOutOfPlace(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0)

        if lastSubarrays != 0:
            offset = start + (mergeCount * fullMerge)
            blockCount = lastSubarrays // blockLen
            
            self.grailInsertSort(array, firstKey, blockCount + 1)

            medianKey = subarrayLen // blockLen
            medianKey = self.grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen)

            lastFragment = lastSubarrays - (blockCount * blockLen)
            if lastFragment != 0:
                lastMergeBlocks = self.grailCountLastMergeBlocks(array, offset, blockCount, blockLen)
            else: lastMergeBlocks = 0

            smartMerges = blockCount - lastMergeBlocks

            if smartMerges == 0:
                leftLen = lastMergeBlocks * blockLen

                self.grailMergeOutOfPlace(array, offset, leftLen, lastFragment, blockLen)
            else:
                self.grailMergeBlocksOutOfPlace(array, firstKey, firstKey + medianKey, offset, smartMerges, blockLen, lastMergeBlocks, lastFragment)

        self.grailOutOfPlaceBufferReset(array, start, length, blockLen)
        arrayCopy(self.extBuffer, 0, array, start - blockLen, blockLen)


    def grailCombineBlocks(self, array, firstKey, start, length, subarrayLen, blockLen, buffer):
        fullMerge    = 2 * subarrayLen
        mergeCount   = length // fullMerge
        lastSubarrays = length - (fullMerge * mergeCount)

        if lastSubarrays <= subarrayLen:
            length -= lastSubarrays
            lastSubarray = 0

        if buffer and blockLen <= self.extBufferLen:
            self.grailCombineOutOfPlace(array, firstKey, start, length, subarrayLen, blockLen, mergeCount, lastSubarrays)
        else:
            self.grailCombineInPlace(array, firstKey, start, length, subarrayLen, blockLen, mergeCount, lastSubarrays, buffer)
    

    def grailLazyMerge(self, array, start, leftLen, rightLen):
        if leftLen < rightLen:
            middle = start + leftLen

            while leftLen != 0:
                mergeLen = self.grailBinarySearchLeft(array, middle, rightLen, array[start])

                if mergeLen != 0:
                    self.grailRotate(array, start, leftLen, mergeLen)
                    start    += mergeLen
                    rightLen -= mergeLen

                middle += mergeLen

                if rightLen == 0: break
                else:
                    condition = True
                    while condition:
                        start += 1
                        leftLen -= 1
                        condition = leftLen != 0 and array[start] <= array[middle]
        else:
            end = start + leftLen + rightLen - 1
            while rightLen != 0:
                mergeLen = self.grailBinarySearchRight(array, start, leftLen, array[end])

                if mergeLen != leftLen:
                    self.grailRotate(array, start + mergeLen, leftLen - mergeLen, rightLen)
                    end     -= leftLen - mergeLen
                    leftLen  = mergeLen

                if leftLen == 0: break
                else:
                    middle = start + leftLen
                    condition = True
                    while condition:
                        rightLen -= 1
                        end -= 1
                        condition = rightLen != 0 and array[middle - 1] <= array[end]

                
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

            mergeIndex = 0
            while mergeIndex <= mergeEnd:
                self.grailLazyMerge(array, start + mergeIndex, mergeLen, mergeLen)
                mergeIndex += fullMerge

            leftOver = length - mergeIndex
            if leftOver > mergeLen:
                self.grailLazyMerge(array, start + mergeIndex, mergeLen, leftOver - mergeLen)
            mergeLen *= 2


    def grailCommonSort(self, array, start, length, extBuffer, extBufferLen):
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

            if idealBuffer and extBuffer != None:
                self.extBuffer = extBuffer
                self.extBufferLen = extBufferLen

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
                        currentBlockLen = (2 * subarrayLen) / keyLen

                self.grailCombineBlocks(array, start, start + bufferEnd, length - bufferEnd, subarrayLen, currentBlockLen, scrollingBuffer)

            self.grailInsertSort(array, start, bufferEnd)
            self.grailLazyMerge(array, start, bufferEnd, length - bufferEnd)


    def grailSortInPlace(self, array, start, length):
        self.grailCommonSort(array, start, length, None, 0)


    def grailSortStaticOOP(self, array, start, length):
        buffer = [0 for _ in range (self.GRAIL_STATIC_EXT_BUF_LEN)]
        self.grailCommonSort(array, start, length, buffer, self.GRAIL_STATIC_EXT_BUF_LEN)


    def grailSortDynamicOOP(self, array, start, length):
        bufferLen = 1
        while (bufferLen ** 2) < length: bufferLen *= 2

        buffer = [0 for _ in range(bufferLen)]

        self.grailCommonSort(array, start, length, buffer, bufferLen)
