package io.github.holygralsortproject.rewrittengrailsort

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

private fun <T : Comparable<T>> MutableList<T>.binarySearchLeft(start: Int, length: Int, target: T): Int {
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

private fun <T : Comparable<T>> MutableList<T>.binarySearchRight(start: Int, length: Int, target: T): Int {
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
    fun commonSort(list: MutableList<T>, buffer: Array<T?>?) {
        if (buffer != null && buffer.size and (buffer.size - 1) != 0) {
            throw IllegalArgumentException("Grailsort external buffer length must be a power of 2.")
        }

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
