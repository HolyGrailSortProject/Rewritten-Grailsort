package io.github.holygralsortproject.rewrittengrailsort

import kotlin.math.min
import kotlin.random.Random
import kotlin.random.nextInt
import kotlin.test.Test
import kotlin.test.fail
import kotlin.time.DurationUnit
import kotlin.time.ExperimentalTime
import kotlin.time.measureTime

@OptIn(ExperimentalTime::class)
class GrailSortTests {
    private fun <T : Comparable<T>> mismatchComparable(a: List<T>, b: List<T>): Int {
        if (a.size != b.size) {
            return min(a.size, b.size)
        }
        for (i in a.indices) {
            if (a[i].compareTo(b[i]) != 0) {
                return i
            }
        }
        return -1
    }

    private fun <T : Comparable<T>> List<T>.unorderedAt(): Int {
        for (i in 1 until size) {
            if (this[i - 1] > this[i]) {
                return i
            }
        }
        return -1
    }

    private fun <T : Comparable<T>> assertMatching(list: List<T>, verifier: List<T>) {
        val i = mismatchComparable(list, verifier)
        if (i != -1) {
            fail("list[$i] != verifier[$i]")
        }
    }

    private inline fun <T : Comparable<T>> testSort(
        banner: String,
        list: MutableList<T>,
        sorter: MutableList<T>.() -> Unit
    ) {
        println("--- $banner ---")
        val copy = list.sorted()
        if (list.size <= 32) {
            println("Before: $list")
        } else {
            println("(${list.size} numbers)")
        }
        val timeTaken = measureTime { list.sorter() }
        if (list.size <= 32) {
            println("After: $list")
        }
        println("Took ${timeTaken.toDouble(DurationUnit.MILLISECONDS)}ms")
        assertMatching(list, copy)
    }

    private fun createRandomArray(length: Int, unique: Int = length): MutableList<Int> {
        val result = mutableListOf<Int>()
        for (i in 1..length) {
            result.add(Random.nextInt(unique))
        }
        return result
    }

    @Test
    fun testSmallSort() =
        testSort("testSmallSort", mutableListOf(11, 10, 15, 0, 0, 14, 3, 9, 12, 9, 4, 0, 13, 2, 4)) {
            grailSort()
        }

    @Test
    fun testCollectKeys() {
        val list = mutableListOf<Int>()
        for (i in 1..24) {
            list.add(Random.nextInt(0 until 24))
        }
        var blockLen = 1
        while (blockLen * blockLen < list.size) {
            blockLen *= 2
        }
        val keyLen = (list.size - 1) / blockLen + 1
        val idealKeys = keyLen + blockLen
        val keyCount = collectKeys(list, idealKeys)
        val unordered = list.unorderedAt()
        if (unordered < keyCount) {
            fail("List is unordered at $unordered, which is before the end of the keys")
        }
    }

    @Test
    fun testLazyStableSort() =
        testSort("testLazyStableSort", mutableListOf(11, 10, 15, 0, 0, 14, 3, 9, 12, 9, 4, 0, 13, 2, 4)) {
            lazyStableSort()
        }

    @Test
    fun testBigLazyStableSort() =
        testSort("testBigLazyStableSort", createRandomArray(32768)) { lazyStableSort() }
}