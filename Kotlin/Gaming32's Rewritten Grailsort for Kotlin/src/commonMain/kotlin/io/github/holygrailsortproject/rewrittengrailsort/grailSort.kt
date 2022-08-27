package io.github.holygrailsortproject.rewrittengrailsort

import kotlin.jvm.JvmOverloads

const val GRAIL_STATIC_EXT_BUFFER_LEN = 512

private fun <T> MutableList<T>.swap(a: Int, b: Int) {
    this[b] = set(a, this[b])
}

private fun <T> MutableList<T>.blockSwap(a: Int, b: Int, blockLen: Int) {
    for (i in 0 until blockLen) {
        swap(a + i, b + i)
    }
}

private fun <T> MutableList<T>.rotate(start: Int, leftLen: Int, rightLen: Int) {
    var currentStart = start
    var currentLeft = leftLen
    var currentRight = rightLen
    while (currentLeft > 0 && currentRight > 0) {
        if (currentLeft <= currentRight) {
            blockSwap(currentStart, currentStart + currentLeft, currentLeft)
            currentStart += currentLeft
            currentRight -= currentLeft
        } else {
            blockSwap(currentStart + currentLeft - currentRight, currentStart + currentLeft, currentRight)
            currentLeft -= currentRight
        }
    }
}

private fun <T : Comparable<T>> MutableList<T>.insertSort(start: Int, length: Int) {
    for (item in 1 until length) {
        var right = start + item
        var left = right - 1

        while (left >= start && this[left] > this[right]) {
            swap(left, right)
            left--
            right--
        }
    }
}

private fun <T : Comparable<T>> List<T>.binarySearchLeft(start: Int, length: Int, target: T): Int {
    var left = 0
    var right = length

    while (left < right) {
        val middle = left + (right - left) / 2

        if (this[start + middle] < target) {
            left = middle + 1
        } else {
            right = middle
        }
    }

    return left
}

private fun <T : Comparable<T>> List<T>.binarySearchRight(start: Int, length: Int, target: T): Int {
    var left = 0
    var right = length

    while (left < right) {
        val middle = left + (right - left) / 2

        if (this[start + middle] > target) {
            right = middle
        } else {
            left = middle + 1
        }
    }

    return right
}

internal fun <T : Comparable<T>> collectKeys(list: MutableList<T>, idealKeys: Int): Int {
    var keysFound = 1
    var firstKey = 0
    var currKey = 0

    while (currKey < list.size && keysFound < idealKeys) {
        val insertPos = list.binarySearchLeft(firstKey, keysFound, list[currKey])

        // Use compareTo() manually because != uses equals()
        if (insertPos == keysFound || list[currKey].compareTo(list[firstKey + insertPos]) != 0) {
            list.rotate(firstKey, keysFound, currKey - (firstKey + keysFound))
            firstKey = currKey - keysFound
            list.rotate(firstKey + insertPos, keysFound - insertPos, 1)
            keysFound++
        }
        currKey++
    }

    list.rotate(0, firstKey, keysFound)
    return keysFound
}

private fun <T : Comparable<T>> pairwiseSwaps(list: MutableList<T>, start: Int, length: Int) {
    var index = 1
    while (index < length) {
        val right = start + index
        val left = right - 1

        if (list[left] > list[right]) {
            list.swap(left - 2, right)
            list.swap(right - 2, left)
        } else {
            list.swap(left - 2, left)
            list.swap(right - 2, right)
        }

        index += 2
    }

    val left = start + index - 1
    if (left < start + length) {
        list.swap(left - 2, left)
    }
}

private fun <T : Comparable<T>> mergeForwards(
    list: MutableList<T>,
    start: Int,
    leftLen: Int,
    rightLen: Int,
    bufferOffset: Int
) {
    var buffer = start - bufferOffset
    var left = start
    val middle = start + leftLen
    var right = middle
    val end = middle + rightLen

    while (right < end) {
        if (left == middle || list[left] > list[right]) {
            list.swap(buffer++, right++)
        } else {
            list.swap(buffer++, left++)
        }
    }

    if (buffer != left) {
        list.blockSwap(buffer, left, middle - left)
    }
}

private fun <T : Comparable<T>> mergeBackwards(
    list: MutableList<T>,
    start: Int,
    leftLen: Int,
    rightLen: Int,
    bufferOffset: Int
) {
    val end = start - 1
    var left = end + leftLen
    val middle = left
    var right = middle + rightLen
    var buffer = right + bufferOffset

    while (left > end) {
        if (right == middle || list[left] > list[right]) {
            list.swap(buffer--, left--)
        } else {
            list.swap(buffer--, right--)
        }
    }

    if (right != buffer) {
        while (right > middle) {
            list.swap(buffer--, right--)
        }
    }
}

private fun <T : Comparable<T>> buildInPlace(
    list: MutableList<T>,
    start: Int,
    length: Int,
    currentLen: Int,
    bufferLen: Int
) {
    var currentStart = start

    var mergeLen = currentLen
    while (mergeLen < bufferLen) {
        val fullMerge = 2 * mergeLen

        val mergeEnd = currentStart + length - fullMerge
        val bufferOffset = mergeLen

        var mergeIndex = currentStart
        while (mergeIndex <= mergeEnd) {
            mergeForwards(list, mergeIndex, mergeLen, mergeLen, bufferOffset)
            mergeIndex += fullMerge
        }

        val leftOver = length - (mergeIndex - currentStart)

        if (leftOver > mergeLen) {
            mergeForwards(list, mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset)
        } else {
            list.rotate(mergeIndex - mergeLen, mergeLen, leftOver)
        }

        currentStart -= mergeLen
        mergeLen *= 2
    }

    val fullMerge = 2 * bufferLen
    val lastBlock = length % fullMerge
    val lastOffset = currentStart + length - lastBlock

    if (lastBlock <= bufferLen) {
        list.rotate(lastOffset, lastBlock, bufferLen)
    } else {
        mergeBackwards(list, lastOffset, bufferLen, lastBlock - bufferLen, bufferLen)
    }

    for (mergeIndex in (lastOffset - fullMerge) downTo start step fullMerge) {
        mergeBackwards(list, mergeIndex, bufferLen, bufferLen, bufferLen)
    }
}

private fun <T : Comparable<T>> blockSelectSort(
    list: MutableList<T>,
    firstKey: Int,
    start: Int,
    medianKey: Int,
    blockCount: Int,
    blockLen: Int
): Int {
    var currentMedian = medianKey

    for (firstBlock in 0 until blockCount) {
        var selectBlock = firstBlock

        for (currBlock in (firstBlock + 1) until blockCount) {
            val compare = list[start + currBlock * blockLen].compareTo(list[start + selectBlock * blockLen])

            if (compare < 0 || (compare == 0 && list[firstKey + currBlock] < list[firstBlock + selectBlock])) {
                selectBlock = currBlock
            }
        }

        if (selectBlock != firstBlock) {
            list.blockSwap(start + firstBlock * blockLen, start + selectBlock * blockLen, blockLen)
            list.swap(firstKey + firstBlock, firstKey + selectBlock)

            if (currentMedian == firstBlock) {
                currentMedian = selectBlock
            } else if (currentMedian == selectBlock) {
                currentMedian = firstBlock
            }
        }
    }

    return currentMedian
}

private fun <T : Comparable<T>> inPlaceBufferReset(list: MutableList<T>, start: Int, length: Int, bufferOffset: Int) {
    var buffer = start + length - 1
    var index = buffer - bufferOffset
    while (buffer >= start) {
        list.swap(index--, buffer--)
    }
}

private fun <T : Comparable<T>> inPlaceBufferRewind(list: MutableList<T>, start: Int, leftBlock: Int, buffer: Int) {
    var currentLeft = leftBlock
    var currentBuffer = buffer
    while (currentLeft >= start) {
        list.swap(currentBuffer--, currentLeft--)
    }
}

private fun <T : Comparable<T>> countLastMergeBlocks(list: List<T>, offset: Int, blockCount: Int, blockLen: Int): Int {
    var blocksToMerge = 0

    val lastRightFrag = offset + blockCount * blockLen
    var prevLeftBlock = lastRightFrag - blockLen

    while (blocksToMerge < blockCount && list[lastRightFrag] < list[prevLeftBlock]) {
        blocksToMerge++
        prevLeftBlock -= blockLen
    }

    return blocksToMerge
}

private fun <T : Comparable<T>> lazyMerge(list: MutableList<T>, start: Int, leftLen: Int, rightLen: Int) {
    var currentLeft = leftLen
    var currentRight = rightLen
    if (currentLeft < currentRight) {
        var middle = start + currentLeft
        var currentStart = start

        while (currentLeft != 0) {
            val mergeLen = list.binarySearchLeft(middle, currentRight, list[currentStart])

            if (mergeLen != 0) {
                list.rotate(currentStart, currentLeft, mergeLen)

                currentStart += mergeLen
                middle += mergeLen
                currentRight -= mergeLen
            }

            if (currentRight == 0) {
                break
            } else {
                do {
                    currentStart++
                    currentLeft--
                } while (currentLeft != 0 && list[start] <= list[middle])
            }
        }
    } else {
        var end = start + currentLeft + currentRight - 1

        while (currentRight != 0) {
            val mergeLen = list.binarySearchRight(start, currentLeft, list[end])

            if (mergeLen != leftLen) {
                list.rotate(start + mergeLen, currentLeft - mergeLen, currentRight)

                end -= currentLeft - mergeLen
                currentLeft = mergeLen
            }

            if (currentLeft == 0) {
                break
            } else {
                val middle = start + currentLeft
                do {
                    currentRight--
                    end--
                } while (currentRight != 0 && list[middle - 1] <= list[end])
            }
        }
    }
}

class GrailSort<T : Comparable<T>> {
    companion object {
        internal const val SUBARRAY_LEFT = false
        internal const val SUBARRAY_RIGHT = true

        private fun <T : Comparable<T>> getSubarray(list: List<T>, currentKey: Int, medianKey: Int) =
            if (list[currentKey] < list[medianKey]) {
                SUBARRAY_LEFT
            } else {
                SUBARRAY_RIGHT
            }
    }

    private lateinit var extBuffer: Array<T?>
    private var currBlockLen: Int = 0
    private var currBlockOrigin: Boolean = false

    private fun smartMerge(
        list: MutableList<T>,
        start: Int,
        leftLen: Int,
        leftOrigin: Boolean,
        rightLen: Int,
        bufferOffset: Int
    ) {
        var buffer = start - bufferOffset
        var left = start
        val middle = start + leftLen
        var right = middle
        val end = middle + rightLen

        if (leftOrigin == SUBARRAY_LEFT) {
            while (left < middle && right < end) {
                if (list[left] <= list[right]) {
                    list.swap(buffer++, left++)
                } else {
                    list.swap(buffer++, right++)
                }
            }
        } else {
            while (left < middle && right < end) {
                if (list[left] < list[right]) {
                    list.swap(buffer++, left++)
                } else {
                    list.swap(buffer++, right++)
                }
            }
        }

        if (left < middle) {
            currBlockLen = middle - left
            inPlaceBufferRewind(list, left, middle - 1, end - 1)
        } else {
            currBlockLen = end - right
            currBlockOrigin = !leftOrigin
        }
    }

    private fun smartLazyMerge(list: MutableList<T>, start: Int, leftLen: Int, leftOrigin: Boolean, rightLen: Int) {
        var currentStart = start
        var currentLeft = leftLen
        var currentRight = rightLen
        var middle = currentStart + currentLeft

        if (leftOrigin == SUBARRAY_LEFT) {
            if (list[middle - 1] > list[middle]) {
                while (currentLeft != 0) {
                    val mergeLen = list.binarySearchLeft(middle, currentRight, list[currentStart])

                    if (mergeLen != 0) {
                        list.rotate(currentStart, currentLeft, mergeLen)

                        currentStart += mergeLen
                        middle += mergeLen
                        currentRight -= mergeLen
                    }

                    if (currentRight == 0) {
                        currBlockLen = currentLeft
                        return
                    }
                    do {
                        currentStart++
                        currentLeft--
                    } while (currentLeft != 0 && list[start] <= list[middle])
                }
            }
        } else {
            if (list[middle - 1] >= list[middle]) {
                while (currentLeft != 0) {
                    val mergeLen = list.binarySearchRight(middle, currentRight, list[currentStart])

                    if (mergeLen != 0) {
                        list.rotate(currentStart, currentLeft, mergeLen)

                        currentStart += mergeLen
                        middle += mergeLen
                        currentRight -= mergeLen
                    }

                    if (rightLen == 0) {
                        currBlockLen = currentLeft
                        return
                    }
                    do {
                        currentStart++
                        currentLeft--
                    } while (leftLen != 0 && list[start] < list[middle])
                }
            }
        }

        currBlockLen = currentRight
        currBlockOrigin = !leftOrigin
    }

    private fun mergeBlocks(
        list: MutableList<T>,
        firstKey: Int,
        medianKey: Int,
        start: Int,
        blockCount: Int,
        blockLen: Int,
        lastMergeBlocks: Int,
        lastLen: Int
    ) {
        var buffer: Int

        var currBlock: Int
        var nextBlock = start + blockLen

        currBlockLen = blockLen
        currBlockOrigin = getSubarray(list, firstKey, medianKey)

        for (keyIndex in 1 until blockCount) {
            currBlock = nextBlock - currBlockLen
            val nextBlockOrigin = getSubarray(list, firstKey + keyIndex, medianKey)

            if (nextBlockOrigin == currBlockOrigin) {
                buffer = currBlock - blockLen

                list.blockSwap(buffer, currBlock, currBlockLen)
                currBlockLen = blockLen
            } else {
                smartMerge(list, currBlock, currBlockLen, currBlockOrigin, blockLen, blockLen)
            }

            nextBlock += blockLen
        }

        currBlock = nextBlock - currBlockLen
        buffer = currBlock - blockLen

        if (lastLen != 0) {
            if (currBlockOrigin == SUBARRAY_RIGHT) {
                list.blockSwap(buffer, currBlock, currBlockLen)

                currBlock = nextBlock
                currBlockLen = blockLen * lastMergeBlocks
                currBlockOrigin = SUBARRAY_LEFT
            } else {
                currBlockLen += blockLen * lastMergeBlocks
            }

            mergeForwards(list, currBlock, currBlockLen, lastLen, blockLen)
        } else {
            list.blockSwap(buffer, currBlock, currBlockLen)
        }
    }

    private fun lazyMergeBlocks(
        list: MutableList<T>,
        firstKey: Int,
        medianKey: Int,
        start: Int,
        blockCount: Int,
        blockLen: Int,
        lastMergeBlocks: Int,
        lastLen: Int
    ) {
        var currBlock: Int
        var nextBlock = start + blockLen

        currBlockLen = blockLen
        currBlockOrigin = getSubarray(list, firstKey, medianKey)

        for (keyIndex in 1 until blockCount) {
            currBlock = nextBlock - currBlockLen
            val nextBlockOrigin = getSubarray(list, firstKey + keyIndex, medianKey)

            if (nextBlockOrigin == currBlockOrigin) {
                currBlockLen = blockLen
            } else if (blockLen != 0 && currBlockLen != 0) {
                smartLazyMerge(list, currBlock, currBlockLen, currBlockOrigin, blockLen)
            }

            nextBlock += blockLen
        }

        currBlock = nextBlock - currBlockLen

        if (lastLen != 0) {
            if (currBlockOrigin == SUBARRAY_RIGHT) {
                currBlock = nextBlock
                currBlockLen = blockLen * lastMergeBlocks
                currBlockOrigin = SUBARRAY_LEFT
            } else {
                currBlockLen += blockLen * lastMergeBlocks
            }

            lazyMerge(list, currBlock, currBlockLen, lastLen)
        }
    }

    private fun combineInPlace(
        list: MutableList<T>,
        firstKey: Int,
        start: Int,
        length: Int,
        subarrayLen: Int,
        blockLen: Int,
        mergeCount: Int,
        lastSubarrays: Int,
        buffer: Boolean
    ) {
        val fullMerge = 2 * subarrayLen
        var blockCount = fullMerge / blockLen

        for (mergeIndex in 0 until mergeCount) {
            val offset = start + mergeIndex * fullMerge

            list.insertSort(firstKey, blockCount)

            var medianKey = subarrayLen / blockLen
            medianKey = blockSelectSort(list, firstKey, offset, medianKey, blockCount, blockLen)

            if (buffer) {
                mergeBlocks(list, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0)
            } else {
                lazyMergeBlocks(list, firstKey, firstKey + medianKey, offset, blockCount, blockLen, 0, 0)
            }
        }

        if (lastSubarrays != 0) {
            val offset = start + mergeCount * fullMerge
            blockCount = lastSubarrays / blockLen

            list.insertSort(firstKey, blockCount + 1)

            var medianKey = subarrayLen / blockLen
            medianKey = blockSelectSort(list, firstKey, offset, medianKey, blockCount, blockLen)

            val lastFragment = lastSubarrays - blockCount * blockLen
            val lastMergeBlocks = if (lastFragment != 0) {
                countLastMergeBlocks(list, offset, blockCount, blockLen)
            } else {
                0
            }

            val smartMerges = blockCount - lastMergeBlocks

            if (smartMerges == 0) {
                val leftLen = lastMergeBlocks * blockLen

                if (buffer) {
                    mergeForwards(list, offset, leftLen, lastFragment, blockLen)
                } else {
                    lazyMerge(list, offset, leftLen, lastFragment)
                }
            } else {
                if (buffer) {
                    mergeBlocks(
                        list, firstKey, firstKey + medianKey, offset,
                        smartMerges, blockLen, lastMergeBlocks, lastFragment
                    )
                } else {
                    lazyMergeBlocks(
                        list, firstKey, firstKey + medianKey, offset,
                        smartMerges, blockLen, lastMergeBlocks, lastFragment
                    )
                }
            }
        }

        if (buffer) {
            inPlaceBufferReset(list, start, length, blockLen)
        }
    }

    private fun combineBlocks(
        list: MutableList<T>,
        firstKey: Int,
        start: Int,
        length: Int,
        subarrayLen: Int,
        blockLen: Int,
        buffer: Boolean
    ) {

        val fullMerge = 2 * subarrayLen
        val mergeCount = length / fullMerge
        var lastSubarrays = length - (fullMerge * mergeCount)

        var realLength = length
        if (lastSubarrays <= subarrayLen) {
            realLength -= lastSubarrays
            lastSubarrays = 0
        }

        if (buffer && this::extBuffer.isInitialized && blockLen <= extBuffer.size) {
            TODO("grailCombineOutOfPlace")
        } else {
            combineInPlace(list, firstKey, start, realLength, subarrayLen, blockLen, mergeCount, lastSubarrays, buffer)
        }
    }

    private fun buildBlocks(list: MutableList<T>, start: Int, length: Int, bufferLen: Int) {
        if (this::extBuffer.isInitialized) {
            val extLen = if (bufferLen < extBuffer.size) {
                bufferLen
            } else {
                var extLen = 1
                while (extLen * 2 < extBuffer.size) {
                    extLen *= 2
                }
                extLen
            }

            TODO("grailBuildOutOfPlace")
        } else {
            pairwiseSwaps(list, start, length)
            buildInPlace(list, start - 2, length, 2, bufferLen)
        }
    }

    fun commonSort(list: MutableList<T>, extBuffer: Array<T?>?) {
        if (list.size < 16) {
            list.insertSort(0, list.size)
            return
        }

        var blockLen = 1
        while (blockLen * blockLen < list.size) {
            blockLen *= 2
        }

        var keyLen = (list.size - 1) / blockLen + 1
        val idealKeys = keyLen + blockLen

        val keysFound = collectKeys(list, idealKeys)

        val idealBuffer: Boolean
        if (keysFound < idealKeys) {
            if (keysFound < 4) {
                list.lazyStableSort()
                return
            } else {
                keyLen = blockLen
                blockLen = 0
                idealBuffer = false
                while (keyLen > keysFound) {
                    keyLen /= 2
                }
            }
        } else {
            idealBuffer = true
        }

        val bufferEnd = blockLen + keyLen
        var subarrayLen = if (idealBuffer) {
            blockLen
        } else {
            keyLen
        }

        if (idealBuffer && extBuffer != null) {
            this.extBuffer = extBuffer
        }

        buildBlocks(list, bufferEnd, list.size - bufferEnd, subarrayLen)

        while (list.size - bufferEnd > 2 * subarrayLen) {
            subarrayLen *= 2

            var currentBlockLen = blockLen
            var scrollingBuffer = idealBuffer

            if (!idealBuffer) {
                val keyBuffer = keyLen / 2

                if (keyBuffer >= 2 * subarrayLen / keyBuffer) {
                    currentBlockLen = keyBuffer
                    scrollingBuffer = true
                } else {
                    currentBlockLen = 2 * subarrayLen / keyLen
                }
            }

            combineBlocks(list, 0, bufferEnd, list.size - bufferEnd, subarrayLen, currentBlockLen, scrollingBuffer)
        }

        list.insertSort(0, bufferEnd)
        lazyMerge(list, 0, bufferEnd, list.size - bufferEnd)
    }
}

enum class GrailSortType {
    IN_PLACE, STATIC_OOP, DYNAMIC_OOP
}

fun <T : Comparable<T>> MutableList<T>.lazyStableSort() {
    for (index in 1 until size step 2) {
        val left = index - 1

        if (this[left] > this[index]) {
            swap(left, index)
        }
    }
    var mergeLen = 2
    while (mergeLen < size) {
        val fullMerge = 2 * mergeLen
        val mergeEnd = size - fullMerge

        var mergeIndex = 0
        while (mergeIndex <= mergeEnd) {
            lazyMerge(this, mergeIndex, mergeLen, mergeLen)
            mergeIndex += fullMerge
        }

        val leftOver = size - mergeIndex
        if (leftOver > mergeLen) {
            lazyMerge(this, mergeIndex, mergeLen, leftOver - mergeLen)
        }

        mergeLen *= 2
    }
}

@JvmOverloads
inline fun <reified T : Comparable<T>> MutableList<T>.grailSort(
    type: GrailSortType = GrailSortType.IN_PLACE
) = GrailSort<T>().commonSort(this, when (type) {
    GrailSortType.IN_PLACE -> null
    GrailSortType.STATIC_OOP -> arrayOfNulls(GRAIL_STATIC_EXT_BUFFER_LEN)
    GrailSortType.DYNAMIC_OOP -> {
        var bufferLen = 1
        while (bufferLen * bufferLen < size) {
            bufferLen *= 2
        }
        arrayOfNulls(bufferLen)
    }
})
