package io.github.holygrailsortproject.rewrittengrailsort

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

    private fun <T : Comparable<T>> assertMatching(list: List<T>, verifier: List<T>) {
        val i = mismatchComparable(list, verifier)
        if (i != -1) {
            fail("list[$i] != verifier[$i]")
        }
    }

    private fun <T : Comparable<T>> List<T>.unorderedAt(): Int {
        for (i in 1 until size) {
            if (this[i - 1] > this[i]) {
                return i
            }
        }
        return -1
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
        val unordered = list.unorderedAt()
        if (unordered != -1) {
            fail("list[${unordered - 1}] > list[$unordered]")
        }
        println("Took ${timeTaken.toDouble(DurationUnit.MILLISECONDS)}ms")
        assertMatching(list, copy)
    }

    private fun createRandomList(length: Int, unique: Int = length): MutableList<Int> {
        val result = mutableListOf<Int>()
        for (i in 1..length) {
            result.add(Random.nextInt(unique))
        }
        return result
    }

    @Test
    fun testSmallGrailSort() =
        testSort("testSmallGrailSort", mutableListOf(11, 10, 15, 0, 0, 14, 3, 9, 12, 9, 4, 0, 13, 2, 4)) {
            grailSort()
        }

    @Test
    fun testMediumGrailSort() =
        testSort("testMediumGrailSort", createRandomList(1 shl 14)) { grailSort() }

    @Test
    fun testGrailSort() =
        testSort("testGrailSort", createRandomList(1 shl 20)) { grailSort() }

    @Test
    fun testGrailSortNonPow2() =
        testSort("testGrailSortNonPow2", createRandomList((1 shl 20) - 13)) { grailSort() }

    @Test
    fun testStrategy3() =
        testSort("testStrategy3", createRandomList(1 shl 20, 3)) { grailSort() }

    @Test
    fun testStrategy3NonPow2() =
        testSort("testStrategy3NonPow2", createRandomList((1 shl 20) - 13, 3)) { grailSort() }

    @Test
    fun testGrailSortStaticOOP() =
        testSort("testGrailSortStaticOOP", createRandomList(1 shl 20)) { grailSort(GrailSortType.STATIC_OOP) }

    @Test
    fun testGrailSortStaticOOPNonPow2() =
        testSort("testGrailSortStaticOOPNonPow2", createRandomList((1 shl 20) - 13)) {
            grailSort(GrailSortType.STATIC_OOP)
        }

    @Test
    fun testGrailSortDynamicOOP() =
        testSort("testGrailSortDynamicOOP", createRandomList(1 shl 20)) { grailSort(GrailSortType.DYNAMIC_OOP) }

    @Test
    fun testGrailSortDynamicOOPNonPow2() =
        testSort("testGrailSortDynamicOOPNonPow2", createRandomList((1 shl 20) - 13)) {
            grailSort(GrailSortType.DYNAMIC_OOP)
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
        testSort("testBigLazyStableSort", createRandomList(16384)) { lazyStableSort() }

    @Test
    fun testBigLazyStableSortNonPow2() =
        testSort("testBigLazyStableSortNonPow2", createRandomList(16371)) { lazyStableSort() }
}
