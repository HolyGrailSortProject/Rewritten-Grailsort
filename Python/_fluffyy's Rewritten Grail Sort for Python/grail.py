"""REWRITTEN GRAIL SORT FOR PYTHON - grail sort translation from Java to Python
Author: _fluffyy
Status: About halfway finished

MIT License

Copyright (c) 2013 Andrey Astrelin
Copyright (c) 2020 The Holy Grail Sort Project

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

The Holy Grail Sort Project
Project Manager:      Summer Dragonfly
Project Contributors: 666666t
                      Anonymous0726
                      aphitorite
                      dani_dlg
                      EilrahcF
                      Enver
                      lovebuny
                      MP
                      phoenixbound
                      thatsOven
                      Bee sort
                      _fluffyy

Special thanks to "The Studio" Discord community!"""

import enum
class _Subarray(enum.Enum):
    LEFT = "LEFT"
    RIGHT = "RIGHT"
class GrailSorter:
    @staticmethod
    def sorted_comparer(a, b):
        return 1 if a > b else -1 if a < b else 0
    @staticmethod
    def reversed_comparer(a, b):
        return -1 if a > b else 1 if a < b else 0
    def __init__(self, compare_func=None):
        if compare_func is None:
            compare_func = self.sorted_comparer
        self.comparer = compare_func
    def _arraycopy(self, source, source_pos, dest, dest_pos, length):
        times = 0
        while times < length:
            dest[dest_pos] = source[source_pos]
            source_pos += 1
            dest_pos += 1
            times += 1
    def _swap(self, arr, a, b):
        arr[a], arr[b] = arr[b], arr[a]
    def _block_swap(self, arr, a, b, block_len):
        for i in range(block_len):
            self._swap(arr, a + i, b + i)
    def _rotate(self, arr, start, left_len, right_len):
        while left_len > 0 and right_len > 0:
            if left_len <= right_len:
                self._block_swap(arr, start, start + left_len, left_len)
                start += left_len
                right_len -= left_len
            else:
                self._block_swap(arr, start + left_len - right_len,
                    start + left_len, right_len)
                left_len -= right_len
    def _binary_search_left(self, arr, start, length, target):
        left = 0
        right = length
        while left < right:
            middle = left + int((right - left) / 2)
            if self.comparer(arr[start + middle], target) < 0:
                left = middle + 1
            else:
                right = middle
        return left
    def _binary_search_right(self, arr, start, length, target):
        left = 0
        right = length
        while left < right:
            middle = left + int((right - left) / 2)
            if self.comparer(arr[start + middle], target) > 0:
                right = middle
            else:
                left = middle + 1
        return right
    def _collect_keys(self, arr, start, length, ideal_keys):
        keys_found = 1
        first_key = 0
        current_key = 1
        while current_key < length and keys_found < ideal_keys:
            insert_pos = self._binary_search_left(arr, start + first_key,
                keys_found, arr[start + current_key])
            if insert_pos == keys_found or self.comparer(arr[start
                + current_key], arr[start + first_key + insert_pos]) != 0:
                self._rotate(arr, start + first_key, keys_found, current_key
                    - (first_key + keys_found))
                first_key = current_key - keys_found
                self._rotate(arr, start + first_key + insert_pos, keys_found
                    - insert_pos, 1)
                keys_found += 1
            current_key += 1
        self._rotate(arr, start, first_key, keys_found)
        return keys_found
    def _pairwise_swaps(self, arr, start, length):
        for index in range(1, length, 2):
            left = start + index - 1
            right = start + index
            if self.comparer(arr[left], arr[right]) > 0:
                self._swap(arr, left - 2, right)
                self._swap(arr, right - 2, left)
            else:
                self._swap(arr, left - 2, left)
                self._swap(arr, right - 2, right)
        left = start + index - 1
        if left < start + length:
            self._swap(arr, left - 2, left)
    def _pairwise_writes(self, arr, start, length):
        for index in range(1, length, 2):
            left = start + index - 1
            right = start + index
            if self.comparer(arr[left], arr[right]) > 0:
                arr[left - 2] = arr[right]
                arr[right - 2] = arr[left]
            else:
                arr[left - 2] = arr[left]
                arr[right - 2] = arr[right]
        left = start + index - 1
        if left < start + length:
            arr[left - 2] = arr[left]
    def _block_select_sort(self, arr, keys, start, median_key, block_count,
                           block_len):
        for block in range(1, block_count):
            left = block - 1
            right = left
            for index in range(block, block_count):
                compare = self.comparer(arr[start + right * block_len],
                                        arr[start + index * block_len])
                if compare > 0 or (compare == 0 and self.comparer(arr[keys
                                                        + right], arr[keys
                                                        + index]) > 0):
                    right = index
            if right != left:
                self._block_swap(arr, start + left * block_len,
                                 start + right * block_len, block_len)
                self._swap(arr, keys + left, keys + right)
                if median_key == left:
                    median_key = right
                elif median_key == right:
                    median_key = left
        return median_key
    def _merge_forwards(self, arr, start, left_len, right_len, buffer_offset):
        left = start
        middle = start + left_len
        right = middle
        end = middle + right_len
        buffer = start - buffer_offset
        while right < end:
            if left == middle or self.comparer(arr[left], arr[right]) > 0:
                self._swap(arr, buffer, right)
                right += 1
            else:
                self._swap(arr, buffer, left)
                left += 1
            buffer += 1
        if buffer != left:
            self._block_swap(arr, buffer, left, middle - left)
    def _merge_backwards(self, arr, start, left_len, right_len, buffer_offset):
        left = start + left_len - 1
        middle = left
        right = middle + right_len
        end = start
        buffer = start + buffer_offset
        while left >= end:
            if right == middle or self.comparer(arr[left], arr[right]) > 0:
                self._swap(arr, buffer, left)
                left -= 1
            else:
                self._swap(arr, buffer, right)
                right -= 1
            buffer -= 1
        if right != buffer:
            while right > middle:
                self._swap(arr, buffer, right)
                buffer -= 1
                right -= 1
    def _out_of_place_merge(self, arr, start, left_len, right_len, buffer_offset):
        left = start
        middle = start + left_len
        right = middle
        end = middle + right_len
        buffer = start - buffer_offset
        while right < end:
            if left == middle or self.comparer(arr[left], arr[right]) > 0:
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
    def _in_place_buffer_reset(self, arr, start, reset_len, buffer_len):
        index = start + reset_len - 1
        while index >= start:
            self._swap(arr, index, index - buffer_len)
            index -= 1
    def _out_of_place_buffer_reset(self, arr, start, reset_len, buffer_len):
        index = start + reset_len - 1
        while index >= start:
            arr[index] = arr[index - buffer_len]
            index -= 1
    def _in_place_buffer_rewind(self, arr, start, buffer, left_overs):
        while start < buffer:
            buffer -= 1
            left_overs -= 1
            self._swap(arr, buffer, left_overs)
    def _out_of_place_buffer_rewind(self, arr, start, buffer, left_overs):
        while start < buffer:
            buffer -= 1
            left_overs -= 1
            arr[buffer] = arr[left_overs]
    def _build_blocks(self, arr, start, length, buffer_len):
        if self.external_buffer != None:
            if buffer_len < self.external_buffer_length:
                extern_len = buffer_len
            else:
                extern_len = 1
                while extern_len * 2 < self.external_buffer_length:
                    extern_len *= 2
            self._build_out_of_place(arr, start, length, buffer_len, extern_len)
        else:
            self._pairwise_swaps(arr, start, length)
            self._build_in_place(arr, start - 2, length, 2, buffer_len)
    def _build_out_of_place(self, arr, start, length, buffer_len, extern_len):
        self._arraycopy(arr, start - extern_len, self.external_buffer, 0,
                        extern_len)
        self._pairwise_writes(arr, start, length)
        start -= 2
        merge_len = 2
        while merge_len < extern_len:
            merge_end = start + length - (2 * merge_len)
            buffer_offset = merge_len
            for merge_index in range(start, merge_end + 1, 2 * merge_len):
                self._out_of_place_merge(arr, merge_index, merge_len, merge_len,
                                         buffer_offset)
            left_over = length - (merge_index - start)
            if left_over > merge_len:
                self._out_of_place_merge(arr, merge_index, merge_len, left_over
                                         - merge_len, buffer_offset)
            else:
                for offset in range(left_over):
                    arr[merge_index + offset - merge_len] = arr[merge_index
                                                                + offset]
            start -= merge_len
            merge_len *= 2
        self._arraycopy(self.external_buffer, 0, arr, start + length, extern_len)
        self._build_in_place(arr, start, length, merge_len, buffer_len)
    def _build_in_place(self, arr, start, length, current_merge, buffer_len):
        merge_len = current_merge
        while merge_len < buffer_len:
            merge_end = start + length - (2 * merge_len)
            buffer_offset = merge_len
            for merge_index in range(start, merge_end + 1, 2 * merge_len):
                self._merge_forwards(arr, merge_index, merge_len, merge_len,
                                     buffer_offset)
            left_over = length - (merge_index - start)
            if left_over > merge_len:
                self._merge_forwards(arr, merge_index, merge_len, left_over
                                     - merge_len, buffer_offset)
            else:
                self._rotate(arr, merge_index - merge_len, merge_len, left_over)
            start -= merge_len
            merge_len *= 2
        final_block = length % (2 * buffer_len)
        final_offset = start + length - final_block
        if final_block <= buffer_len:
            self._rotate(arr, final_offset, final_block, buffer_len)
        else:
            self._merge_backwards(arr, final_offset, buffer_len, final_block
                                  - buffer_len, buffer_len)
        for merge_index in range(final_offset - (2 * buffer_len), start - 1,
                                 -(2 * buffer_len)):
            self._merge_backwards(arr, merge_index, buffer_len, buffer_len,
                                  buffer_len)
    def _count_left_blocks(self, arr, offset, block_count, block_len):
        left_blocks = 0
        first_right_block = offset + (block_count * block_len)
        prev_left_block = first_right_block - block_len
        while left_block < block_count and self.comparer(arr[first_right_block],
            arr[prev_left_block]) < 0:
            left_blocks += 1
            prev_left_block -= block_len
        return left_blocks
    def _get_subarray(self, arr, current_key, median_key):
        if self.comparer(arr[current_key], arr[median_key]) < 0:
            return _Subarray.LEFT
        else:
            return _Subarray.RIGHT
    def _smart_merge_out_of_place(self, arr, start, left_len, left_origin,
                                  right_len, buffer_offset):
        left = start
        middle = start + left_len
        right = middle
        end = middle + right_len
        buffer = start - buffer_offset
        if left_origin == _Subarray.LEFT:
            while left < middle and right < end:
                if self.comparer(arr[left], arr[right]) <= 0:
                    arr[buffer] = arr[left]
                    left += 1
                else:
                    arr[buffer] = arr[right]
                    right += 1
                buffer += 1
        else:
            while left < middle and right < end:
                if self.comparer(arr[left], arr[right]) < 0:
                    arr[buffer] = arr[left]
                    left += 1
                else:
                    arr[buffer] = arr[right]
                    right += 1
                buffer += 1
        if left < middle:
            self.current_block_len = middle - left
            self._out_of_place_buffer_rewind(arr, left, middle, end)
        else:
            self.current_block_len = end - right
            if left_origin == _Subarray.LEFT:
                self.current_block_origin = _Subarray.RIGHT
            else:
                self.current_block_origin = _Subarray.RIGHT
    def _smart_merge(self, arr, start, left_len, left_origin, right_len,
                     buffer_offset):
        left = start
        middle = start + left_len
        right = middle
        end = middle + right_len
        buffer = start - buffer_offset
        if left_origin == _Subarray.LEFT:
            while left < middle and right < end:
                if self.comparer(arr[left], arr[right]) != 1:
                    self._swap(arr, buffer, left)
                    left += 1
                else:
                    self._swap(arr, buffer, right)
                    right += 1
                buffer += 1
        else:
            while left < middle and right < end:
                if self.comparer(arr[left], arr[right]) == -1:
                    self._swap(arr, buffer, left)
                    left += 1
                else:
                    self._swap(arr, buffer, right)
                    right += 1
                buffer += 1
        if left < middle:
            self.current_block_len = middle - left
            self._in_place_buffer_rewind(arr, left, middle, end)
        else:
            self.current_block_len = end - right
            if left_origin == _Subarray.LEFT:
                self.current_block_origin = _Subarray.RIGHT
            else:
                self.current_block_origin = _Subarray.LEFT
    def _smart_lazy_merge(self, arr, start, left_len, left_origin, right_len):
        if left_origin == _Subarray.LEFT:
            if (self.comparer(arr[start + left_len - 1], arr[start + left_len])
                == 1):
                while left_len != 0:
                    insert_pos = self._binary_search_left(arr, start + left_len,
                        right_len, arr[start])
                    if insert_pos != 0:
                        self._rotate(arr, start, left_len, insert_pos)
                        start += insert_pos
                        right_len -= insert_pos
                    if right_len == 0:
                        self.current_block_len = left_len
                        return
                    else:
                        while True:
                            start += 1
                            left_len -= 1
                            if left_len != 0 and self.comparer(arr[start],
                                arr[start + left_len]) != 1:
                                break
        else:
            if (self.comparer(arr[start + left_len - 1], arr[start + left_len])
                != 1):
                while left_len != 0:
                    insert_pos = self._binary_search_right(arr, start + left_len,
                        right_len, arr[start])
                    if insert_pos != 0:
                        self._rotate(arr, start, left_len, insert_pos)
                        start += insert_pos
                        right_len -= insert_pos
                    if right_len == 0:
                        self.current_block_len = left_len
                        return
                    else:
                        while True:
                            start += 1
                            left_len -= 1
                            if left_len != 0 and self.comparer(arr[start],
                                arr[start + left_len]) == -1:
                                break
        self.current_block_len = right_len
        if left_origin == _Subarray.LEFT:
            self.current_block_origin = _Subarray.RIGHT
        else:
            self.current_block_origin = _Subarray.LEFT
    def _merge_blocks_out_of_place(self, arr, keys, median_key, start,
                                   block_count, block_len, final_left_blocks,
                                   final_len):
        pass   # TO-DO: CONTINUE AT LINE 682
