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
 #                       Control
 #                       dani_dlg
 #                       DeveloperSort
 #                       EilrahcF
 #                       Enver
 #                       Gaming32
 #                       lovebuny
 #                       Morwenn
 #                       MP
 #                       phoenixbound
 #                       Spex_guy
 #                       thatsOven
 #                       _fluffyy
 #                       
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
# Current status: Working (Passing all tests) + Stable

class Subarray:
    LEFT, RIGHT = 0, 1

class GrailSort:

    GRAIL_STATIC_EXT_BUF_LEN = 512

    extBuffer = None
    extBufferLen = 0

    @staticmethod
    def grailSwap(array, a, b):
        array[a], array[b] = array[b], array[a]
    
    @staticmethod
    def grailBlockSwap(array, a, b, blockLen):
        for i in range(0, blockLen):
            GrailSort.grailSwap(array, a + i, b + i)

    @staticmethod
    def grailRotate(array, start, leftLen, rightLen):
        while leftLen > 0 and rightLen > 0:
            if leftLen <= rightLen:
                GrailSort.grailBlockSwap(array, start, start + leftLen, leftLen)
                start    += leftLen
                rightLen -= leftLen
            else:
                GrailSort.grailBlockSwap(array, start + leftLen - rightLen, start + leftLen, rightLen)
                leftLen -= rightLen
    
    @staticmethod
    def grailInsertSort(array, start, length):
        for item in range(1, length):
            left  = start + item - 1
            right = start + item

            while left >= start and array[left] > array[right]:
                GrailSort.grailSwap(array, left, right)
                left  -= 1
                right -= 1

    @staticmethod
    def grailBinarySearchLeft(array, start, length, target):
        left  = 0
        right = length

        while left < right:
            middle = left + ((right - left) // 2)

            if array[start + middle] < target:
                left = middle + 1
            else: 
                right = middle

        return left

    @staticmethod
    def grailBinarySearchRight(array, start, length, target):
        left  = 0
        right = length

        while left < right:
            middle = left + ((right - left) // 2)

            if array[start + middle] > target:
                right = middle
            else:
                left = middle + 1

        return right

    @staticmethod    
    def grailCollectKeys(array, start, length, idealKeys):
        keysFound  = 1
        firstKey   = 0
        currKey    = 1

        while currKey < length and keysFound < idealKeys:

            insertPos = GrailSort.grailBinarySearchLeft(array, start + firstKey, keysFound, array[start + currKey])

            if insertPos == keysFound or array[start + currKey] != array[start + firstKey + insertPos]:

                GrailSort.grailRotate(array, start + firstKey, keysFound, currKey - (firstKey + keysFound))

                firstKey = currKey - keysFound

                GrailSort.grailRotate(array, start + firstKey + insertPos, keysFound - insertPos, 1)

                keysFound += 1

            currKey += 1

        GrailSort.grailRotate(array, start, firstKey, keysFound)
        return keysFound

    @staticmethod
    def grailPairwiseSwaps(array, start, length):
        index = 1
        while index < length:
            left  = start + index - 1
            right = start + index

            if array[left] > array[right]:
                GrailSort.grailSwap(array,  left - 2, right)
                GrailSort.grailSwap(array, right - 2,  left)
            else:
                GrailSort.grailSwap(array,  left - 2,  left)
                GrailSort.grailSwap(array, right - 2, right)
                
            index += 2
        
        left = start + index - 1
        if left < start + length:
            GrailSort.grailSwap(array, left - 2, left)

    @staticmethod
    def grailPairwiseWrites(array, start, length):
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

    @staticmethod
    def grailMergeForwards(array, start, leftLen, rightLen, bufferOffset):
        left   = start
        middle = start + leftLen
        right  = middle
        end    = middle + rightLen
        buffer = start - bufferOffset

        while right < end:
            if left == middle or array[left] > array[right]:
                GrailSort.grailSwap(array, buffer, right)
                right += 1
            else:
                GrailSort.grailSwap(array, buffer, left)
                left += 1
            buffer += 1

        if buffer != left:
            GrailSort.grailBlockSwap(array, buffer, left, middle-left)
        
    @staticmethod
    def grailMergeBackwards(array, start, leftLen, rightLen, bufferOffset):
        end    = start - 1
        left   = end + leftLen
        middle = left
        right  = middle + rightLen
        buffer = right + bufferOffset

        while left > end:
            if right == middle or array[left] > array[right]:
                GrailSort.grailSwap(array, buffer, left)
                left -= 1
            else:
                GrailSort.grailSwap(array, buffer, right)
                right -= 1
            buffer -= 1

        if right != buffer:
            while right > middle:
                GrailSort.grailSwap(array, buffer, right)
                buffer -= 1
                right -= 1

    @staticmethod 
    def grailMergeOutOfPlace(array, start, leftLen, rightLen, bufferOffset):
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

    @staticmethod
    def grailBuildInPlace(array, start, length, currentLen, bufferLen):
        mergeLen = currentLen
        while mergeLen < bufferLen:
            fullMerge = 2 * mergeLen

            mergeEnd = start + length - fullMerge
            bufferOffset = mergeLen

            mergeIndex = start
            while mergeIndex <= mergeEnd:
                GrailSort.grailMergeForwards(array, mergeIndex, mergeLen, mergeLen, bufferOffset)

                mergeIndex += fullMerge

            leftOver = length - (mergeIndex - start)

            if leftOver > mergeLen:
                GrailSort.grailMergeForwards(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset)
            else:
                GrailSort.grailRotate(array, mergeIndex - mergeLen, mergeLen, leftOver)

            start -= mergeLen

            mergeLen *= 2

        fullMerge = 2 * bufferLen
        lastBlock = int(length % fullMerge)
        lastOffset = start + length - lastBlock

        if lastBlock <= bufferLen:
            GrailSort.grailRotate(array, lastOffset, lastBlock, bufferLen)
        else:
            GrailSort.grailMergeBackwards(array, lastOffset, bufferLen, lastBlock - bufferLen, bufferLen)

        mergeIndex = lastOffset - fullMerge
        while mergeIndex >= start:
            GrailSort.grailMergeBackwards(array, mergeIndex, bufferLen, bufferLen, bufferLen)
            mergeIndex -= fullMerge

    @staticmethod   
    def grailBuildOutOfPlace(array, start, length, bufferLen, extLen):
        arrayCopy(array, start - extLen, GrailSort.extBuffer, 0, extLen)

        GrailSort.grailPairwiseWrites(array, start, length)
        start -= 2

        mergeLen = 2
        while mergeLen < extLen:
            fullMerge = 2 * mergeLen

            mergeEnd = start + length - fullMerge
            bufferOffset = mergeLen

            mergeIndex = start
            while mergeIndex <= mergeEnd:
                GrailSort.grailMergeOutOfPlace(array, mergeIndex, mergeLen, mergeLen, bufferOffset)
                mergeIndex += fullMerge

            leftOver = length - (mergeIndex - start)

            if leftOver > mergeLen:
                GrailSort.grailMergeOutOfPlace(array, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset)
            else:
                arrayCopy(array, mergeIndex, array, mergeIndex - mergeLen, leftOver)

            start -= mergeLen
            mergeLen *= 2

        arrayCopy(GrailSort.extBuffer, 0, array, start + length, extLen)
        GrailSort.grailBuildInPlace(array, start, length, mergeLen, bufferLen)

    @staticmethod
    def grailBuildBlocks(array, start, length, bufferLen):
        if GrailSort.extBuffer is not None:
            if bufferLen < GrailSort.extBufferLen:
                extLen = bufferLen
            else:
                extLen = 1
                while (extLen*2) <= GrailSort.extBufferLen:
                    extLen *= 2
            GrailSort.grailBuildOutOfPlace(array, start, length, bufferLen, extLen)
        else:
            GrailSort.grailPairwiseSwaps(array, start, length)
            GrailSort.grailBuildInPlace(array, start - 2, length, 2, bufferLen)   

    @staticmethod   
    def grailBlockSelectSort(array, firstKey, start, medianKey, blockCount, blockLen):
        for firstBlock in range(0, blockCount):
            selectBlock = firstBlock

            for currBlock in range(firstBlock + 1, blockCount):
                compare = compareVal(   array[start + (currBlock   * blockLen)],
                                        array[start + (selectBlock * blockLen)]     )

                if compare < 0 or (compare == 0 and array[firstKey + currBlock] < array[firstKey + selectBlock]):
                    selectBlock = currBlock

            if selectBlock != firstBlock:
                GrailSort.grailBlockSwap(array, start + (firstBlock * blockLen), start + (selectBlock * blockLen), blockLen)

                GrailSort.grailSwap(array, firstKey + firstBlock, firstKey + selectBlock)

                if   medianKey == firstBlock:  medianKey = selectBlock
                elif medianKey == selectBlock: medianKey = firstBlock

        return medianKey

    @staticmethod
    def grailInPlaceBufferReset(array, start, length, bufferOffset):
        buffer = start + length - 1
        index  = buffer - bufferOffset 
        while buffer >= start:
            GrailSort.grailSwap(array, index, buffer)
            buffer -= 1
            index -= 1

    @staticmethod
    def grailOutOfPlaceBufferReset(array, start, length, bufferOffset):
        buffer = start + length - 1
        index  = buffer - bufferOffset 
        while buffer >= start:
            array[buffer] = array[index]
            buffer -= 1
            index -= 1

    @staticmethod
    def grailInPlaceBufferRewind(array, start, leftBlock, buffer):
        while leftBlock >= start:
            GrailSort.grailSwap(array, buffer, leftBlock)
            buffer -= 1
            leftBlock -= 1
            
    @staticmethod
    def grailOutOfPlaceBufferRewind(array, start, leftBlock, buffer):
        while leftBlock >= start:
            array[buffer] = array[leftBlock]
            buffer -= 1
            leftBlock -= 1

    @staticmethod
    def grailGetSubarray(array, currentKey, medianKey):
        if array[currentKey] < array[medianKey] : return Subarray.LEFT
        else                                    : return Subarray.RIGHT

    @staticmethod
    def grailCountLastMergeBlocks(array, offset, blockCount, blockLen):
        blocksToMerge = 0

        lastRightFrag = offset + (blockCount * blockLen)
        prevLeftBlock = lastRightFrag - blockLen

        while (blocksToMerge < blockCount) and (array[lastRightFrag] < array[prevLeftBlock]):
            blocksToMerge += 1
            prevLeftBlock -= blockLen

        return blocksToMerge

    @staticmethod
    def grailSmartMerge(array, start, leftLen, leftOrigin, rightLen, bufferOffset):
        left   = start
        middle = start + leftLen
        right  = middle
        end    = middle + rightLen
        buffer = start - bufferOffset

        if leftOrigin == Subarray.LEFT:
            while (left < middle) and (right < end):
                if array[left] <= array[right]:
                    GrailSort.grailSwap(array, buffer, left)
                    left += 1
                else:
                    GrailSort.grailSwap(array, buffer, right)
                    right += 1
                buffer += 1
        
        else:
            while (left < middle) and (right < end):
                if array[left] < array[right]:
                    GrailSort.grailSwap(array, buffer, left)
                    left += 1
                else:
                    GrailSort.grailSwap(array, buffer, right)
                    right += 1
                buffer += 1

        if left < middle:
            GrailSort.currBlockLen = middle - left
            GrailSort.grailInPlaceBufferRewind(array, left, middle - 1, end - 1)
        else:
            GrailSort.currBlockLen = end - right
            if leftOrigin == Subarray.LEFT:
                GrailSort.currBlockOrigin = Subarray.RIGHT
            else:
                GrailSort.currBlockOrigin = Subarray.LEFT

    @staticmethod
    def grailSmartLazyMerge(array, start, leftLen, leftOrigin, rightLen):
        middle = start + leftLen

        if leftOrigin == Subarray.LEFT:
            if array[middle- 1] > array[middle]:
                while leftLen != 0:
                    mergeLen = GrailSort.grailBinarySearchLeft(array, middle, rightLen, array[start])

                    if mergeLen != 0:
                        GrailSort.grailRotate(array, start, leftLen, mergeLen)
                        start    += mergeLen
                        rightLen -= mergeLen
                        middle   += mergeLen

                    if rightLen == 0:
                        GrailSort.currBlockLen = leftLen
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
                    mergeLen = GrailSort.grailBinarySearchRight(array, middle, rightLen, array[start])

                    if mergeLen != 0:
                        GrailSort.grailRotate(array, start, leftLen, mergeLen)
                        start    += mergeLen
                        rightLen -= mergeLen
                        middle   += mergeLen

                    if rightLen == 0:
                        GrailSort.currBlockLen = leftLen
                        return
                    else:
                        condition = True
                        while condition:
                            start += 1
                            leftLen -= 1
                            condition = (leftLen !=  0) and (array[start] < array[middle])
        
        GrailSort.currBlockLen = rightLen
        if leftOrigin == Subarray.LEFT:
            GrailSort.currBlockOrigin = Subarray.RIGHT
        else:
            GrailSort.currBlockOrigin = Subarray.LEFT

    @staticmethod
    def grailSmartMergeOutOfPlace(array, start, leftLen, leftOrigin, rightLen, bufferOffset):
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
            GrailSort.currBlockLen = middle - left
            GrailSort.grailOutOfPlaceBufferRewind(array, left, middle - 1, end - 1)
        else:
            GrailSort.currBlockLen = end - right
            if leftOrigin == Subarray.LEFT:
                GrailSort.currBlockOrigin = Subarray.RIGHT
            else:
                GrailSort.currBlockOrigin = Subarray.LEFT

    @staticmethod
    def grailMergeBlocks(array, firstKey, medianKey, start, blockCount, blockLen, lastMergeBlocks, lastLen):
        nextBlock = start + blockLen

        GrailSort.currBlockLen    = blockLen
        GrailSort.currBlockOrigin = GrailSort.grailGetSubarray(array, firstKey, medianKey)

        for keyIndex in range(1, blockCount):
            currBlock       = nextBlock - GrailSort.currBlockLen
            nextBlockOrigin = GrailSort.grailGetSubarray(array, firstKey + keyIndex, medianKey)

            if nextBlockOrigin == GrailSort.currBlockOrigin:
                buffer = currBlock - blockLen

                GrailSort.grailBlockSwap(array, buffer, currBlock, GrailSort.currBlockLen)
                GrailSort.currBlockLen = blockLen
            else:
                GrailSort.grailSmartMerge(array, currBlock, GrailSort.currBlockLen, GrailSort.currBlockOrigin, blockLen, blockLen)

            nextBlock += blockLen
        
        currBlock = nextBlock - GrailSort.currBlockLen
        buffer    = currBlock - blockLen

        if lastLen != 0:
            if GrailSort.currBlockOrigin == Subarray.RIGHT:
                GrailSort.grailBlockSwap(array, buffer, currBlock, GrailSort.currBlockLen)

                currBlock                 = nextBlock
                GrailSort.currBlockLen    = blockLen * lastMergeBlocks
                GrailSort.currBlockOrigin = Subarray.LEFT
            else:
                GrailSort.currBlockLen += blockLen * lastMergeBlocks

            GrailSort.grailMergeForwards(array, currBlock, GrailSort.currBlockLen, lastLen, blockLen)
        else:
            GrailSort.grailBlockSwap(array, buffer, currBlock, GrailSort.currBlockLen)

    @staticmethod
    def grailLazyMergeBlocks(array, firstKey, medianKey, start, blockCount, blockLen, lastMergeBlocks, lastLen):
        nextBlock = start + blockLen

        GrailSort.currBlockLen    = blockLen
        GrailSort.currBlockOrigin = GrailSort.grailGetSubarray(array, firstKey, medianKey)

        for keyIndex in range(1, blockCount):
            currBlock       = nextBlock - GrailSort.currBlockLen
            nextBlockOrigin = GrailSort.grailGetSubarray(array, firstKey + keyIndex, medianKey)

            if nextBlockOrigin == GrailSort.currBlockOrigin:
                GrailSort.currBlockLen = blockLen
            else:
                if blockLen != 0 and GrailSort.currBlockLen != 0:
                    GrailSort.grailSmartLazyMerge(array, currBlock, GrailSort.currBlockLen, GrailSort.currBlockOrigin, blockLen)

            nextBlock += blockLen
        
        currBlock = nextBlock - GrailSort.currBlockLen

        if lastLen != 0:
            if GrailSort.currBlockOrigin == Subarray.RIGHT:
                currBlock            = nextBlock
                GrailSort.currBlockLen    = blockLen * lastMergeBlocks
                GrailSort.currBlockOrigin = Subarray.LEFT
            else:
                GrailSort.currBlockLen += blockLen * lastMergeBlocks

            GrailSort.grailLazyMerge(array, currBlock, GrailSort.currBlockLen, lastLen)

    @staticmethod
    def grailMergeBlocksOutOfPlace(array, firstKey, medianKey, start, blockCount, blockLen, lastMergeBlocks, lastLen):
        nextBlock = start + blockLen

        GrailSort.currBlockLen    = blockLen
        GrailSort.currBlockOrigin = GrailSort.grailGetSubarray(array, firstKey, medianKey)

        for keyIndex in range(1, blockCount):
            currBlock       = nextBlock - GrailSort.currBlockLen
            nextBlockOrigin = GrailSort.grailGetSubarray(array, firstKey + keyIndex, medianKey)

            if nextBlockOrigin == GrailSort.currBlockOrigin:
                buffer = currBlock - blockLen

                arrayCopy(array, currBlock, array, buffer, GrailSort.currBlockLen)
                GrailSort.currBlockLen = blockLen
            else:
                GrailSort.grailSmartMergeOutOfPlace(array, currBlock, GrailSort.currBlockLen, GrailSort.currBlockOrigin, blockLen, blockLen)
            nextBlock += blockLen
        
        currBlock = nextBlock - GrailSort.currBlockLen
        buffer    = currBlock - blockLen

        if lastLen != 0:
            if GrailSort.currBlockOrigin == Subarray.RIGHT:
                arrayCopy(array, currBlock, array, buffer, GrailSort.currBlockLen)

                currBlock                 = nextBlock
                GrailSort.currBlockLen    = blockLen * lastMergeBlocks
                GrailSort.currBlockOrigin = Subarray.LEFT
            else:
                GrailSort.currBlockLen += blockLen * lastMergeBlocks

            GrailSort.grailMergeOutOfPlace(array, currBlock, GrailSort.currBlockLen, lastLen, blockLen)
        else:
            arrayCopy(array, currBlock, array, buffer, GrailSort.currBlockLen)

    @staticmethod
    def grailCombineInPlace(array, firstKey, start, length, subarrayLen, blockLen, mergeCount, lastSubarrays, buffer):
        fullMerge = 2 * subarrayLen
        blockCount = fullMerge // blockLen

        for mergeIndex in range(0, mergeCount):
            offset = start + (mergeIndex * fullMerge)

            GrailSort.grailInsertSort(array, firstKey, blockCount)

            medianKey = subarrayLen // blockLen
            medianKey = GrailSort.grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen)

            if buffer:
                GrailSort.grailMergeBlocks(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0)
            else:
                GrailSort.grailLazyMergeBlocks(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0)

        if lastSubarrays != 0:
            offset = start + (mergeCount * fullMerge)
            blockCount = lastSubarrays // blockLen

            GrailSort.grailInsertSort(array, firstKey, blockCount + 1)

            medianKey = subarrayLen // blockLen
            medianKey = GrailSort.grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen)

            lastFragment = lastSubarrays - (blockCount * blockLen)
            if lastFragment != 0:
                lastMergeBlocks = GrailSort.grailCountLastMergeBlocks(array, offset, blockCount, blockLen)
            else: lastMergeBlocks = 0

            smartMerges = blockCount - lastMergeBlocks

            if smartMerges == 0:
                leftLen = lastMergeBlocks * blockLen

                if buffer:
                    GrailSort.grailMergeForwards(array, offset, leftLen, lastFragment, blockLen)
                else:
                    GrailSort.grailLazyMerge(array, offset, leftLen, lastFragment)
            else:
                if buffer:
                    GrailSort.grailMergeBlocks(array, firstKey, firstKey + medianKey, offset, smartMerges, blockLen, lastMergeBlocks, lastFragment)
                else:
                    GrailSort.grailLazyMergeBlocks(array, firstKey, firstKey + medianKey, offset, smartMerges, blockLen, lastMergeBlocks, lastFragment)
            
        if buffer:
            GrailSort.grailInPlaceBufferReset(array, start, length, blockLen)

    @staticmethod   
    def grailCombineOutOfPlace(array, firstKey, start, length, subarrayLen, blockLen, mergeCount, lastSubarrays):
        arrayCopy(array, start - blockLen, GrailSort.extBuffer, 0, blockLen)

        fullMerge = 2 * subarrayLen
        blockCount = fullMerge // blockLen

        for mergeIndex in range(0, mergeCount):
            offset = start + (mergeIndex * fullMerge)

            GrailSort.grailInsertSort(array, firstKey, blockCount)

            medianKey = subarrayLen // blockLen
            medianKey = GrailSort.grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen)

            GrailSort.grailMergeBlocksOutOfPlace(array, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0)

        if lastSubarrays != 0:
            offset = start + (mergeCount * fullMerge)
            blockCount = lastSubarrays // blockLen
            
            GrailSort.grailInsertSort(array, firstKey, blockCount + 1)

            medianKey = subarrayLen // blockLen
            medianKey = GrailSort.grailBlockSelectSort(array, firstKey, offset, medianKey, blockCount, blockLen)

            lastFragment = lastSubarrays - (blockCount * blockLen)
            if lastFragment != 0:
                lastMergeBlocks = GrailSort.grailCountLastMergeBlocks(array, offset, blockCount, blockLen)
            else: lastMergeBlocks = 0

            smartMerges = blockCount - lastMergeBlocks

            if smartMerges == 0:
                leftLen = lastMergeBlocks * blockLen

                GrailSort.grailMergeOutOfPlace(array, offset, leftLen, lastFragment, blockLen)
            else:
                GrailSort.grailMergeBlocksOutOfPlace(array, firstKey, firstKey + medianKey, offset, smartMerges, blockLen, lastMergeBlocks, lastFragment)

        GrailSort.grailOutOfPlaceBufferReset(array, start, length, blockLen)
        arrayCopy(GrailSort.extBuffer, 0, array, start - blockLen, blockLen)

    @staticmethod
    def grailCombineBlocks(array, firstKey, start, length, subarrayLen, blockLen, buffer):
        fullMerge    = 2 * subarrayLen
        mergeCount   = length // fullMerge
        lastSubarrays = length - (fullMerge * mergeCount)

        if lastSubarrays <= subarrayLen:
            length -= lastSubarrays
            lastSubarrays = 0

        if buffer and blockLen <= GrailSort.extBufferLen:
            GrailSort.grailCombineOutOfPlace(array, firstKey, start, length, subarrayLen, blockLen, mergeCount, lastSubarrays)
        else:
            GrailSort.grailCombineInPlace(array, firstKey, start, length, subarrayLen, blockLen, mergeCount, lastSubarrays, buffer)
    
    @staticmethod
    def grailLazyMerge(array, start, leftLen, rightLen):
        if leftLen < rightLen:
            middle = start + leftLen

            while leftLen != 0:
                mergeLen = GrailSort.grailBinarySearchLeft(array, middle, rightLen, array[start])

                if mergeLen != 0:
                    GrailSort.grailRotate(array, start, leftLen, mergeLen)
                    start    += mergeLen
                    rightLen -= mergeLen
                    middle   += mergeLen

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
                mergeLen = GrailSort.grailBinarySearchRight(array, start, leftLen, array[end])

                if mergeLen != leftLen:
                    GrailSort.grailRotate(array, start + mergeLen, leftLen - mergeLen, rightLen)
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

    @staticmethod            
    def grailLazyStableSort(array, start, length):
        for index in range(1, length, 2):
            left  = start + index - 1
            right = start + index

            if array[left] > array[right]:
                GrailSort.grailSwap(array, left, right)

        mergeLen = 2
        while mergeLen < length:
            fullMerge = 2 * mergeLen

            mergeEnd = length - fullMerge

            mergeIndex = 0
            while mergeIndex <= mergeEnd:
                GrailSort.grailLazyMerge(array, start + mergeIndex, mergeLen, mergeLen)
                mergeIndex += fullMerge

            leftOver = length - mergeIndex
            if leftOver > mergeLen:
                GrailSort.grailLazyMerge(array, start + mergeIndex, mergeLen, leftOver - mergeLen)
            mergeLen *= 2

    @staticmethod
    def grailCommonSort(array, start, length, extBuffer, extBufferLen):
        if length < 16:
            GrailSort.grailInsertSort(array, start, length)
            return
        else:
            blockLen = 1

            while (blockLen ** 2) < length: blockLen *= 2

            keyLen = ((length - 1) // blockLen) + 1

            idealKeys = keyLen + blockLen

            keysFound = GrailSort.grailCollectKeys(array, start, length, idealKeys)

            if keysFound < idealKeys:
                if keysFound < 4:
                    GrailSort.grailLazyStableSort(array, start, length)
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
                GrailSort.extBuffer = extBuffer
                GrailSort.extBufferLen = extBufferLen

            GrailSort.grailBuildBlocks(array, start + bufferEnd, length - bufferEnd, subarrayLen)

            while (length - bufferEnd) > (2 * subarrayLen):
                subarrayLen *= 2

                currentBlockLen = blockLen
                scrollingBuffer = idealBuffer

                if not idealBuffer:
                    keyBuffer = keyLen // 2
                    if keyBuffer >= ((2 * subarrayLen) // keyBuffer):
                        currentBlockLen = keyBuffer
                        scrollingBuffer = True

                    else:
                        currentBlockLen = (2 * subarrayLen) // keyLen

                GrailSort.grailCombineBlocks(array, start, start + bufferEnd, length - bufferEnd, subarrayLen, currentBlockLen, scrollingBuffer)

            GrailSort.grailInsertSort(array, start, bufferEnd)
            GrailSort.grailLazyMerge(array, start, bufferEnd, length - bufferEnd)

    @staticmethod
    def grailSortInPlace(array, start, length):
        GrailSort.extBuffer = None
        GrailSort.extBufferLen = 0
        GrailSort.grailCommonSort(array, start, length, None, 0)

    @staticmethod
    def grailSortStaticOOP(array, start, length):
        GrailSort.extBuffer = [0 for _ in range (GrailSort.GRAIL_STATIC_EXT_BUF_LEN)]
        GrailSort.extBufferLen = GrailSort.GRAIL_STATIC_EXT_BUF_LEN
        GrailSort.grailCommonSort(array, start, length, GrailSort.extBuffer, GrailSort.GRAIL_STATIC_EXT_BUF_LEN)

    @staticmethod
    def grailSortDynamicOOP(array, start, length):
        GrailSort.extBufferLen = 1
        while (GrailSort.extBufferLen ** 2) < length: GrailSort.extBufferLen *= 2

        GrailSort.extBuffer = [0 for _ in range(GrailSort.extBufferLen)]

        GrailSort.grailCommonSort(array, start, length, GrailSort.extBuffer, GrailSort.extBufferLen)