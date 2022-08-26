package io.github.holygralsortproject.rewrittengrailsort

import kotlin.jvm.JvmOverloads

const val GRAIL_STATIC_EXT_BUFFER_LEN = 512

private inline fun <T> MutableList<T>.swap(a: Int, b: Int) {
    this[b] = set(a, this[b])
}

private fun <T : Comparable<T>> insertSort(list: MutableList<T>, start: Int, length: Int) {
    for (item in 1 until length) {
        var right = start + item
        var left = right - 1

        while (left >= start && list[left] > list[right]) {
            list.swap(left, right)
            left--
            right--
        }
    }
}

class GrailSort<T : Comparable<T>> {
    fun commonSort(list: MutableList<T>, buffer: Array<T?>?) {
        if (buffer != null && buffer.size and (buffer.size - 1) != 0) {
            throw IllegalArgumentException("Grailsort external buffer length must be a power of 2.")
        }

        if (list.size < 16) {
            insertSort(list, 0, list.size)
            return
        }
    }
}

enum class GrailSortType {
    IN_PLACE, STATIC_OOP, DYNAMIC_OOP
}

@JvmOverloads
inline fun <reified T : Comparable<T>> grailSort(
    list: MutableList<T>,
    type: GrailSortType = GrailSortType.IN_PLACE
) = GrailSort<T>().commonSort(list, when (type) {
    GrailSortType.IN_PLACE -> null
    GrailSortType.STATIC_OOP -> arrayOfNulls(GRAIL_STATIC_EXT_BUFFER_LEN)
    GrailSortType.DYNAMIC_OOP -> {
        var bufferLen = 1
        while (bufferLen * bufferLen < list.size) {
            bufferLen *= 2
        }
        arrayOfNulls(bufferLen)
    }
})
