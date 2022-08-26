package io.github.holygralsortproject.rewrittengrailsort

import kotlin.test.Test
import kotlin.test.fail

class GrailSortTests {
    private fun <T : Comparable<T>> assertOrdered(list: List<T>) {
        for (i in 1 until list.size) {
            if (list[i - 1] > list[i]) {
                fail("list[${i - 1}] > list[$i]")
            }
        }
    }

    @Test
    fun testSmallSort() {
        val testList = mutableListOf(11, 10, 15, 0, 0, 14, 3, 9, 12, 9, 4, 0, 13, 2, 4)
        grailSort(testList)
        assertOrdered(testList)
    }
}