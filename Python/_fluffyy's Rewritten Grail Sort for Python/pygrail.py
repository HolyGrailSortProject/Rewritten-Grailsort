"""
Rewritten Grailsort for Python -- A rewrite of an O(n log n), stable,
in-place, very fast sorting algorithm. Maintained by the Holy Grail Sort
Project.
This Python rewrite was created by _fluffyy, however it heavily relies on
the Java rewrite, whose primary author is Summer Dragonfly.

Status -- In progress, will be finished Soon™

THE TEAM:
    Summer Dragonfly
    666666t
    Anonymous0726
    aphitorite
    dani_dlg
    DeveloperSort
    EilrahcF
    Enver
    lovebuny
    Morwenn
    MP
    phoenixbound
    thatsOven
    _fluffyy
Plus everyone in "The Studio" discord server!

----------------------------------------------------------------------------

MIT License

Copyright (c) 2013 Andrey Astrelin
Copyright (c) 2021 The Holy Grail Sort Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
"""
__all__ = ["sort_in_place", "sort_static_oop", "sort_dynamic_oop"]
class _GrailSorter:
    LEFT = object()
    RIGHT = object()
    STATIC_EXT_BUFFER_LEN = 512
    def __repr__(self):
        return "<grail sorting helper>"
    def swap(self, arr, a, b):
        arr[a], arr[b] = arr[b], arr[a]
    def block_swap(self, arr, a, b, block_len):
        for i in range(block_len):
            self.swap(arr, a + i, b + i)
    def rotate(self, arr, start, left, right):
        while left > 0 and right > 0:
            if left <= right:
                self.block_swap(arr, start, start + left, left)
                start += left
                right -= left
            else:
                self.block_swap(arr, start + left - right, start + left, right)
                left -= right
    def insert_sort(self, arr, start, length):
        for i in range(start, start + length - 1):
            while i >= start and self.compare(arr[i], arr[i + 1]) > 0:
                self.swap(arr, i, i + 1)
                i -= 1
    def bin_search_left(self, arr, start, length, target):
        left, right = 0, length
        while left < right:
            middle = left + ((right - left) // 2)
            if self.compare(arr[start + middle], target) < 0:
                left = middle + 1
            else:
                right = middle
        return left
    def bin_search_right(self, arr, start, length, target):
        left, right = 0, length
        while left < right:
            middle = left + ((right - left) // 2)
            if self.compare(arr[start + middle], target) > 0:
                right = middle
            else:
                left = middle + 1
        return right
    def collect_keys(self, arr, start, length, ideal_keys):
        keys_found = 1
        first_key = 0
        current_key = 1
        while current_key < length and keys_found < ideal_keys:
            insert_pos = self.bin_search_left(
                arr, start + first_key, keys_found, arr[start + current_key])
            if (insert_pos == keys_found or
                self.compare(arr[start + current_key],
                             arr[start + first_key + insert_pos]) != 0):
                self.rotate(arr, start + first_key, keys_found,
                            current_key - (first_key + keys_found))
                first_key = current_key - keys_found
                self.rotate(arr, start + first_key + insert_pos,
                            keys_found - insert_pos, 1)
                keys_found += 1
            current_key += 1
        self.rotate(arr, start, first_key, keys_found)
        return keys_found
    def pairwise_swaps(self, arr, start, length):
        for index in range(1, length, 2):
            left, right = start + index - 1, start + index
            if self.compare(arr[left], arr[right]) > 0:
                self.swap(arr, left - 2, right)
                self.swap(arr, right - 2, left)
            else:
                self.swap(arr, left - 2, left)
                self.swap(arr, right - 2, right)
        left = start + index - 1
        if left < start + length:
            self.swap(arr, left - 2, left)
    def pairwise_writes(self, arr, start, length):
        for index in range(1, length, 2):
            left = start + index - 1
            right = start + index
            if self.compare(arr[left], arr[right]) > 0:
                arr[left - 2] = arr[right]
                arr[right - 2] = arr[left]
            else:
                arr[left - 2] = arr[left]
                arr[right - 2] = arr[right]
        left = start + index - 1
        if left < start + length:
            arr[left - 2] = arr[left]
    def merge_forwards(self, arr, start, left_len, right_len, buffer_offset):
        buffer = start - buffet_offset
        left = start
        middle = start + left_len
        right - middle
        end = middle + right_len
        while right < end:
            if left == middle or self.compare(arr[left], arr[right]) > 0:
                self.swap(arr, buffer, right)
                right += 1
            else:
                self.swap(arr, buffer, left)
                left += 1
            buffer += 1
        if buffer != left:
            self.block_swap(arr, buffer, left, middle - left)
    def merge_backwards(self, arr, start, left_len, right_len, buffer_offset):
        end = start - 1
        left = start + left_len - 1
        middle = left
        right = middle + right_len
        buffer = right + buffer_offset
        while left > end:
            if right == middle or self.compare(arr[left], arr[right]) > 0:
                self.swap(arr, buffer, left)
                left -= 1
            else:
                self.swap(arr, buffer, right)
                right -= 1
            buffer -= 1
        if right != buffer:
            while right > middle:
                self.swap(arr, buffer, right)
                buffer -= 1
                right -= 1
    def merge_out_of_place(self, arr, start, left_len, right_len,
                           buffer_offset):
        buffer = start - buffer_offset
        left = start
        middle = start + left_len
        right = middle
        end = middle + right_len
        while right < end:
            if left == middle or self.compare(arr[left], arr[right]) > 0:
                arr[buffer] = arr[right]
                right += 1
            else:
                arr[buffer] = arr[left]
                left += 1
            buffer += 1
        if buffer != left:
            while left < middle:
                arr[buffer] = arr[left]
                buffer += 1
                left += 1
    def build_in_place(self, arr, start, length, current_len, buffer_len):
        merge_len = current_len
        while merge_len < buffer_len:
            full_merge = 2 * merge_len
            merge_end = start + length - full_merge
            buffer_offset = merge_len
            for merge_index in range(start, merge_end + 1, full_merge):
                self.merge_forwards(arr, merge_index, merge_len, merge_len,
                                    buffer_offset)
            leftover = length - (merge_index - start)
            if leftover > merge_len:
                self.merge_forwards(arr, merge_index, merge_len,
                                    leftover - merge_len, buffer_offset)
            else:
                self.rotate(arr, merge_index - merge_len, merge_len, leftover)
            start -= merge_len
            merge_len *= 2
        full_merge = 2 * buffer_len
        final_block = length % full_merge
        final_offset = start + length - final_block
        if final_block <= buffer_len:
            self.rotate(arr, final_offset, final_block, buffer_len)
        else:
            self.merge_backwargs(arr, final_offset, buffer_len,
                                 final_block - buffer_len, buffer_len)
        for merge_index in range(final_offset - full_merge, start - 1,
                                 -full_merge):
            self.merge_backwards(arr, merge_index, buffer_len, buffer_len,
                                 buffer_len)
    #TO-DO: CONTINUE ON LINE 395
_instance = _GrailSorter()
sort_in_place = _instance.sort_in_place
sort_static_oop = _instance.sort_static_oop
sort_dynamic_oop = _instance.sort_dynamic_oop
del _instance, _GrailSorter
