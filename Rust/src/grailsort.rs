use crate::sortable::Sortable;
use std::cmp::Ordering;

/*
 * MIT License
 *
 * Copyright (c) 2013 Andrey Astrelin
 * Copyright (c) 2020 <name-of-holy-grail-project>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * <name-of-holy-grail-project>
 * Project Manager:      Summer Dragonfly
 * Project Contributors: 666666t
 *                       Anonymous0726
 *                       aphitorite
 *                       dani_dlg
 *                       EilrahcF
 *                       Enver
 *                       lovebuny
 *                       MP
 *                       phoenixbound
 *                       thatsOven
 *
 * Special thanks to "The Studio" Discord community!
 */

#[derive(PartialEq)]
enum Subarray {
    Right,
    Left,
}

const STATIC_SIZE: usize = 4096;

#[allow(dead_code)]
pub fn grail_sort<T: Sortable>(set: &mut [T], len: usize) {
    grail_common_sort(set, 0, len, &mut None);
}

#[allow(dead_code)]
pub fn grail_sort_with_static_buffer<T: Sortable + Default>(set: &mut [T], len: usize) {
    let mut buffer = vec![T::default(); STATIC_SIZE];
    let mut container = Some(&mut buffer[..]);

    grail_common_sort(set, 0, len, &mut container);
}

#[allow(dead_code)]
pub fn grail_sort_with_dynamic_buffer<T: Sortable + Default>(set: &mut [T], len: usize) {
    let temp_len = (len as f64).sqrt() as usize;
    let mut buffer = vec![T::default(); temp_len];
    let mut container = Some(&mut buffer[..]);

    grail_common_sort(set, 0, len, &mut container);
}

fn grail_block_swap<T: Sortable>(set: &mut [T], point_a: usize, point_b: usize, block_len: usize) {
    for i in 0..block_len {
        set.swap(point_a + i, point_b + i);
    }
}

fn grail_rotate<T: Sortable>(
    set: &mut [T],
    mut start: usize,
    mut left_len: usize,
    mut right_len: usize,
) {
    while left_len > 0 && right_len > 0 {
        if left_len <= right_len {
            grail_block_swap(set, start, start + left_len, left_len);
            start += left_len;
            right_len -= left_len;
        } else {
            grail_block_swap(
                set,
                start + left_len - right_len,
                start + left_len,
                right_len,
            );
            left_len -= right_len;
        }
    }
}

fn grail_binary_search_left<T: Sortable>(
    set: &[T],
    start: usize,
    length: usize,
    target: &T,
) -> usize {
    let mut left = 0;
    let mut right = length;
    while left < right {
        let middle = left + ((right - left) / 2);
        if set[start + middle] < *target {
            left = middle + 1;
        } else {
            right = middle;
        }
    }
    left
}

fn grail_binary_search_right<T: Sortable>(
    set: &[T],
    start: usize,
    length: usize,
    target: &T,
) -> usize {
    let mut left = 0;
    let mut right = length;
    while left < right {
        let middle = left + ((right - left) / 2);
        if set[start + middle] > *target {
            right = middle;
        } else {
            left = middle + 1;
        }
    }
    right
}

fn grail_collect_keys<T: Sortable>(
    set: &mut [T],
    start: usize,
    length: usize,
    ideal_keys: usize,
) -> usize {
    let mut keys_found = 1;
    let mut first_key = 0;
    let mut current_key = 1;

    while current_key < length && keys_found < ideal_keys {
        let insert_pos = grail_binary_search_left(
            set,
            start + first_key,
            keys_found,
            &set[start + current_key],
        );

        if insert_pos == keys_found
            || set[start + current_key] != set[start + first_key + insert_pos]
        {
            grail_rotate(
                set,
                start + first_key,
                keys_found,
                current_key - (first_key + keys_found),
            );

            first_key = current_key - keys_found;

            grail_rotate(
                set,
                start + first_key + insert_pos,
                keys_found - insert_pos,
                1,
            );

            keys_found += 1;
        }
        current_key += 1;
    }
    grail_rotate(set, start, first_key, keys_found);
    keys_found
}

fn grail_pairwise_swaps<T: Sortable>(set: &mut [T], start: usize, length: usize) {
    let mut index = 1;
    while index < length {
        let left = start + index - 1;
        let right = start + index;

        if set[left] > set[right] {
            set.swap(left - 2, right);
            set.swap(right - 2, left);
        } else {
            set.swap(left - 2, left);
            set.swap(right - 2, right);
        }

        index += 2;
    }

    let left = start + index - 1;
    if left < start + length {
        set.swap(left - 2, left);
    }
}

fn grail_pairwise_writes<T: Sortable>(set: &mut [T], start: usize, length: usize) {
    let mut index = 1;
    while index < length {
        let left = start + index - 1;
        let right = start + index;

        if set[left] > set[right] {
            set[left - 2] = set[right];
            set[right - 2] = set[left];
        } else {
            set[left - 2] = set[left];
            set[right - 2] = set[right];
        }

        index += 2;
    }

    let left = start + index - 1;
    if left < start + length {
        set[left - 2] = set[left];
    }
}

fn grail_block_select_sort<T: Sortable>(
    set: &mut [T],
    keys: usize,
    start: usize,
    mut median_key: usize,
    block_count: usize,
    block_len: usize,
) -> usize {
    for block in 1..block_count {
        let left = block - 1;
        let mut right = left;

        for index in block..block_count {
            let compare =
                match set[start + (right * block_len)].cmp(&set[start + (index * block_len)]) {
                    Ordering::Greater => 1,
                    Ordering::Equal => 0,
                    Ordering::Less => -1,
                };

            if compare > 0 || compare == 0 && set[keys + right] > set[keys + index] {
                right = index;
            }
        }

        if right != left {
            grail_block_swap(
                set,
                start + (left * block_len),
                start + (right * block_len),
                block_len,
            );

            set.swap(keys + left, keys + right);

            if median_key == left {
                median_key = right;
            } else if median_key == right {
                median_key = left;
            }
        }
    }
    median_key
}

fn grail_merge_forwards<T: Sortable>(
    set: &mut [T],
    start: usize,
    left_len: usize,
    right_len: usize,
    buffer_offset: isize,
) {
    let mut left = start;
    let middle = start + left_len;
    let mut right = middle;
    let end = middle + right_len;
    let mut buffer = (start as isize - buffer_offset) as usize;

    while right < end {
        if left == middle || set[left] > set[right] {
            set.swap(buffer, right);
            right += 1;
        } else {
            set.swap(buffer, left);
            left += 1;
        }
        buffer += 1;
    }

    if buffer != left {
        grail_block_swap(set, buffer, left, middle - left);
    }
}

fn grail_merge_backwards<T: Sortable>(
    set: &mut [T],
    start: usize,
    left_len: usize,
    right_len: usize,
    buffer_offset: isize,
) {
    let mut left: isize = (start + left_len - 1) as isize;
    let middle = left as usize;
    let mut right = middle + right_len;
    let end = start;
    let mut buffer = (right as isize + buffer_offset) as usize;

    while left >= end as isize {
        if right == middle || set[left as usize] > set[right] {
            set.swap(buffer, left as usize);
            left -= 1;
        } else {
            set.swap(buffer, right);
            right -= 1;
        }
        buffer -= 1;
    }
    if right != buffer {
        while right > middle {
            set.swap(buffer, right);
            buffer -= 1;
            right -= 1;
        }
    }
}

fn grail_out_of_place_merge<T: Sortable>(
    set: &mut [T],
    start: usize,
    left_len: usize,
    right_len: usize,
    buffer_offset: isize,
) {
    let mut left = start;
    let middle = start + left_len;
    let mut right = middle;
    let end = middle + right_len;
    let mut buffer = (start as isize - buffer_offset) as usize;

    while right < end {
        if left == middle || set[left] > set[right] {
            set[buffer] = set[right];
            right += 1;
        } else {
            set[buffer] = set[left];
            left += 1;
        }
        buffer += 1;
    }

    if buffer != left {
        while left < middle {
            set[buffer] = set[left];
            buffer += 1;
            left += 1;
        }
    }
}

#[allow(dead_code)]
fn grail_in_place_buffer_reset<T: Sortable>(
    set: &mut [T],
    start: usize,
    reset_len: usize,
    buffer_len: usize,
) {
    let mut index = start + reset_len - 1;
    while index >= start {
        set.swap(index, index - buffer_len);
        index -= 1;
    }
}

#[allow(dead_code)]
fn grail_out_of_place_buffer_reset<T: Sortable>(
    set: &mut [T],
    start: usize,
    reset_len: usize,
    buffer_len: usize,
) {
    let mut index = start + reset_len - 1;
    while index >= start {
        set[index] = set[index - buffer_len];
        index -= 1;
    }
}

#[allow(dead_code)]
fn grail_in_place_buffer_rewind<T: Sortable>(
    set: &mut [T],
    start: usize,
    mut left_overs: usize,
    mut buffer: usize,
) {
    while left_overs > start {
        buffer -= 1;
        left_overs -= 1;
        set.swap(buffer, left_overs);
    }
}

#[allow(dead_code)]
fn grail_out_of_place_buffer_rewind<T: Sortable>(
    set: &mut [T],
    start: usize,
    mut left_overs: usize,
    mut buffer: usize,
) {
    while left_overs > start{
        buffer -= 1;
        left_overs -= 1;
        set[buffer] = set[left_overs];
    }
}

fn grail_build_blocks<T: Sortable>(
    set: &mut [T],
    buffer: &mut Option<&mut [T]>,
    start: usize,
    length: usize,
    buffer_len: usize,
) {
    match buffer {
        Some(buf) => {
            let extern_len = if buffer_len < buf.len() {
                buffer_len
            } else {
                let mut temp = 1;
                while (temp * 2) <= buf.len() {
                    temp *= 2;
                }
                temp
            };

            grail_build_out_of_place(set, buf, start, length, buffer_len, extern_len);
        }
        None => {
            grail_pairwise_swaps(set, start, length);
            grail_build_in_place(set, start - 2, length, 2, buffer_len);
        }
    }
}

fn grail_build_out_of_place<T: Sortable>(
    set: &mut [T],
    buffer: &mut [T],
    mut start: usize,
    length: usize,
    buffer_len: usize,
    extern_len: usize,
) {
    &mut buffer[0..extern_len].copy_from_slice(&set[start - extern_len..start]);

    grail_pairwise_writes(set, start, length);
    start -= 2;

    let mut merge_len = 2;
    while merge_len < extern_len {
        let mut merge_index = start;
        let merge_end = start + length - (2 * merge_len);
        let buffer_offset: isize = merge_len as isize;

        while merge_index <= merge_end {
            grail_out_of_place_merge(set, merge_index, merge_len, merge_len, buffer_offset);
            merge_index += 2 * merge_len;
        }
        let left_over = length - (merge_index - start);

        if left_over > merge_len {
            grail_out_of_place_merge(
                set,
                merge_index,
                merge_len,
                left_over - merge_len,
                buffer_offset,
            );
        } else {
            //TODO: Might not be correct?
            for offset in 0..left_over {
                set[merge_index + offset - merge_len] = set[merge_index + offset];
            }
        }

        start -= merge_len;
        merge_len *= 2;
    }

    &mut set[start + length..start + length + extern_len].copy_from_slice(&buffer[0..extern_len]);
    grail_build_in_place(set, start, length, merge_len, buffer_len);
}

fn grail_build_in_place<T: Sortable>(
    set: &mut [T],
    mut start: usize,
    length: usize,
    current_merge: usize,
    buffer_len: usize,
) {
    let mut merge_len = current_merge;
    while merge_len < buffer_len {
        let mut merge_index = start;
        let merge_end = start + length - (2 * merge_len);
        let buffer_offset: isize = merge_len as isize;

        while merge_index <= merge_end {
            grail_merge_forwards(set, merge_index, merge_len, merge_len, buffer_offset);
            merge_index += 2 * merge_len;
        }

        let left_over = length - (merge_index - start);

        if left_over > merge_len {
            grail_merge_forwards(
                set,
                merge_index,
                merge_len,
                left_over - merge_len,
                buffer_offset,
            );
        } else {
            grail_rotate(set, merge_index - merge_len, merge_len, left_over);
        }

        start -= merge_len;
        merge_len *= 2;
    }

    let final_block = length % (2 * buffer_len);
    let final_offset = start + length - final_block;
    if final_block <= buffer_len {
        grail_rotate(set, final_offset, final_block, buffer_len);
    } else {
        grail_merge_backwards(
            set,
            final_offset,
            buffer_len,
            final_block - buffer_len,
            buffer_len as isize,
        );
    }
    
    let mut merge_index: isize = (final_offset as isize - (2 * buffer_len) as isize);
    while merge_index >= start as isize {
        grail_merge_backwards(
            set,
            merge_index as usize,
            buffer_len,
            buffer_len,
            buffer_len as isize,
        );
        merge_index -= 2 * buffer_len as isize;
    }
}

#[allow(dead_code)]
fn grail_count_left_block<T: Sortable>(
    set: &[T],
    offset: usize,
    block_count: usize,
    block_len: usize,
) -> usize {
    let mut left_blocks = 0;
    let first_right_block = offset + (block_count * block_len);
    let mut prev_left_block = first_right_block - block_len;

    while left_blocks < block_count && set[first_right_block] < set[prev_left_block] {
        left_blocks += 1;
        prev_left_block -= block_len;
    }

    left_blocks
}

fn grail_count_left_blocks<T: Sortable>(
    set: &[T],
    offset: usize,
    block_count: usize,
    block_len: usize,
) -> usize {
    let mut left_blocks = 0;
    let first_right_block = offset + (block_count * block_len);
    let mut prev_left_block = first_right_block - block_len;

    while left_blocks < block_count && set[first_right_block] < set[prev_left_block] {
        left_blocks += 1;
        prev_left_block -= block_len;
    }

    left_blocks
}

fn grail_get_subarray<T: Sortable>(set: &[T], current_key: usize, median_key: usize) -> Subarray {
    if set[current_key] < set[median_key] {
        Subarray::Left
    } else {
        Subarray::Right
    }
}

fn grail_smart_merge_out_of_place<T: Sortable>(
    set: &mut [T],
    start: usize,
    left_len: &mut usize,
    left_origin: &mut Subarray,
    right_len: usize,
    buffer_offset: usize,
) {
    let mut left = start;
    let middle = start + *left_len;
    let mut right = middle;
    let end = middle + right_len;
    let mut buffer = start - buffer_offset;

    if *left_origin == Subarray::Left {
        while left < middle && right < end {
            if set[left] <= set[right] {
                set[buffer] = set[left];
                left += 1;
            } else {
                set[buffer] = set[right];
                right += 1;
            }
            buffer += 1;
        }
    } else {
        while left < middle && right < end {
            if set[left] < set[right] {
                set[buffer] = set[left];
                left += 1;
            } else {
                set[buffer] = set[right];
                right += 1;
            }
            buffer += 1;
        }
    }

    if left < middle {
        *left_len = middle - left;
        grail_out_of_place_buffer_rewind(set, left, middle, end);
    } else {
        *left_len = end - right;
        if *left_origin == Subarray::Left {
            *left_origin = Subarray::Right;
        } else {
            *left_origin = Subarray::Left;
        }
    }
}

fn grail_smart_merge<T: Sortable>(
    set: &mut [T],
    start: usize,
    left_len: &mut usize,
    left_origin: &mut Subarray,
    right_len: usize,
    buffer_offset: usize,
) {
    let mut left = start;
    let middle = start + *left_len;
    let mut right = middle;
    let end = middle + right_len;
    let mut buffer = start - buffer_offset;

    if *left_origin == Subarray::Left {
        while left < middle && right < end {
            if set[left] <= set[right] {
                set.swap(buffer, left);
                left += 1;
            } else {
                set.swap(buffer, right);
                right += 1;
            }
            buffer += 1;
        }
    } else {
        while left < middle && right < end {
            if set[left] < set[right] {
                set.swap(buffer, left);
                left += 1;
            } else {
                set.swap(buffer, right);
                right += 1;
            }
            buffer += 1;
        }
    }

    if left < middle {
        *left_len = middle - left;
        grail_in_place_buffer_rewind(set, left, middle, end);
    } else {
        *left_len = end - right;
        if *left_origin == Subarray::Left {
            *left_origin = Subarray::Right;
        } else {
            *left_origin = Subarray::Left;
        }
    }
}

fn grail_smart_lazy_merge<T: Sortable>(
    set: &mut [T],
    mut start: usize,
    left_len: &mut usize,
    left_origin: &mut Subarray,
    mut right_len: usize,
) {
    if *left_origin == Subarray::Left {
        if set[start + *left_len - 1] > set[start + *left_len] {
            while *left_len != 0 {
                let insert_pos =
                    grail_binary_search_left(set, start + *left_len, right_len, &set[start]);

                if insert_pos != 0 {
                    grail_rotate(set, start, *left_len, insert_pos);
                    start += insert_pos;
                    right_len -= insert_pos;
                }

                if right_len == 0 {
                    return;
                } else {
                    start += 1;
                    *left_len -= 1;
                    while *left_len != 0 && set[start] <= set[start + *left_len] {
                        start += 1;
                        *left_len -= 1;
                    }
                }
            }
        }
    } else {
        if set[start + *left_len - 1] >= set[start + *left_len] {
            while *left_len != 0 {
                let insert_pos =
                    grail_binary_search_right(set, start + *left_len, right_len, &set[start]);

                if insert_pos != 0 {
                    grail_rotate(set, start, *left_len, insert_pos);
                    start += insert_pos;
                    right_len -= insert_pos;
                }

                if right_len == 0 {
                    return;
                } else {
                    start += 1;
                    *left_len -= 1;
                    while *left_len != 0 && set[start] < set[start + *left_len] {
                        start += 1;
                        *left_len -= 1;
                    }
                }
            }
        }
    }

    *left_len = right_len;
    if *left_origin == Subarray::Left {
        *left_origin = Subarray::Right;
    } else {
        *left_origin = Subarray::Left;
    }
}

fn grail_merge_blocks_out_of_place<T: Sortable>(
    set: &mut [T],
    keys: usize,
    median_key: usize,
    start: usize,
    block_count: usize,
    block_len: usize,
    final_left_blocks: usize,
    final_len: usize,
) {

    let mut current_block;
    let mut block_index = block_len;

    let mut current_block_len = block_len;
    let mut current_block_origin = grail_get_subarray(set, keys, median_key);

    for key_index in 1..block_count {
        current_block = block_index - current_block_len;

        let next_block_origin = grail_get_subarray(set, keys + key_index, median_key);

        if next_block_origin == current_block_origin {
            internal_array_copy(
                set,
                start + current_block,
                start + current_block - block_len,
                current_block_len,
            );
            current_block = block_index;
            current_block_len = block_len;
        } else {
            grail_smart_merge_out_of_place(
                set,
                start + current_block,
                &mut current_block_len,
                &mut current_block_origin,
                block_len,
                block_len,
            );
        }
        block_index += block_len;
    }

    current_block = block_index - current_block_len;

    if final_len != 0 {
        if current_block_origin == Subarray::Right {
            internal_array_copy(
                set,
                start + current_block,
                start + current_block - block_len,
                current_block_len,
            );
            current_block = block_index;

            current_block_len = block_len * final_left_blocks;
            current_block_origin = Subarray::Left;
        } else {
            current_block_len += block_len * final_left_blocks;
        }

        grail_out_of_place_merge(
            set,
            start + current_block,
            current_block_len,
            final_len,
            block_len as isize,
        );
    } else {
        internal_array_copy(set, start + current_block, start + current_block - block_len, current_block_len);
    }
}

fn internal_array_copy<T: Sortable>(
    set: &mut [T],
    src_position: usize,
    dest_position: usize,
    length: usize,
) {
    for i in 0..length {
        set[dest_position + i] = set[src_position + i];
    }
}

fn grail_merge_blocks<T: Sortable>(
    set: &mut [T],
    keys: usize,
    median_key: usize,
    start: usize,
    block_count: usize,
    block_len: usize,
    final_left_blocks: usize,
    final_len: usize,
) {
    let mut first_block: usize;
    let mut block_index: usize = block_len;
    let mut first_block_len: usize = block_len;
    let mut first_block_origin: Subarray = if set[keys] < set[median_key] {
        Subarray::Left
    } else {
        Subarray::Right
    };

    for key_index in 1..block_count {
        first_block = block_index - first_block_len;

        let next_block_origin = if set[keys + key_index] < set[median_key] {
            Subarray::Left
        } else {
            Subarray::Right
        };

        if next_block_origin == first_block_origin {
            grail_block_swap(
                set,
                start + first_block - block_len,
                start + first_block,
                first_block_len,
            );
            first_block = block_index;
            first_block_len = block_len;
        } else {
            grail_smart_merge(
                set,
                start + first_block,
                &mut first_block_len,
                &mut first_block_origin,
                block_len,
                block_len,
            );
        }

        block_index += block_len;
    }

    first_block = block_index - first_block_len;

    if final_len != 0 {
        if first_block_origin == Subarray::Right {
            grail_block_swap(
                set,
                start + first_block - block_len,
                start + first_block,
                first_block_len,
            );

            first_block = block_index;
            first_block_len = block_len * final_left_blocks;
            first_block_origin = Subarray::Left;
        } else {
            first_block_len += block_len * final_left_blocks;
        }

        grail_merge_forwards(
            set,
            start + first_block,
            first_block_len,
            final_len,
            block_len as isize,
        );
    } else {
        grail_block_swap(
            set,
            start + first_block,
            start + first_block - block_len,
            first_block_len,
        );
    }
}

#[allow(dead_code)]
fn grail_lazy_merge_blocks<T: Sortable>(
    set: &mut [T],
    keys: usize,
    median_key: usize,
    start: usize,
    block_count: usize,
    block_len: usize,
    final_left_blocks: usize,
    final_len: usize,
) {
    let mut first_block;
    let mut block_index = block_len;
    let mut first_block_len = block_len;

    let mut first_block_origin = if set[keys] < set[median_key] {
        Subarray::Left
    } else {
        Subarray::Right
    };

    for key_index in 1..block_count {
        first_block = block_index - first_block_len;

        let next_block_origin = if set[keys + key_index] < set[median_key] {
            Subarray::Left
        } else {
            Subarray::Right
        };

        if next_block_origin == first_block_origin {
            first_block = block_index;
            first_block_len = block_len;
        } else {
            grail_smart_lazy_merge(
                set,
                start + first_block,
                &mut first_block_len,
                &mut first_block_origin,
                block_len,
            );
        }

        block_index += block_len;
    }

    first_block = block_index - first_block_len;

    if final_len != 0 {
        if first_block_origin == Subarray::Right {
            first_block = block_index;
            first_block_len = block_len * final_left_blocks;
            first_block_origin = Subarray::Left;
        } else {
            first_block_len += block_len * final_left_blocks;
        }

        grail_lazy_merge(set, start + first_block, first_block_len, final_len);
    }
}

fn grail_combine_blocks<T: Sortable>(
    set: &mut [T],
    buffer: &mut Option<&mut [T]>,
    keys: usize,
    start: usize,
    mut length: usize,
    subarray_len: usize,
    block_len: usize,
    scrolling_buffer: bool,
) {
    let merge_count = length / (2 * subarray_len);
    let mut last_subarray = length % (2 * subarray_len);
    if last_subarray <= subarray_len {
        length -= last_subarray;
        last_subarray = 0;
    }

    match buffer {
        Some(buf) => {
            if block_len <= buf.len() {
                grail_combine_out_of_place(
                    set,
                    buf,
                    keys,
                    start,
                    length,
                    subarray_len,
                    block_len,
                    merge_count,
                    last_subarray,
                );
            } else {
                grail_combine_in_place(
                    set,
                    keys,
                    start,
                    length,
                    subarray_len,
                    block_len,
                    merge_count,
                    last_subarray,
                    scrolling_buffer,
                );
            }
        }
        None => grail_combine_in_place(
            set,
            keys,
            start,
            length,
            subarray_len,
            block_len,
            merge_count,
            last_subarray,
            scrolling_buffer,
        ),
    }
}

fn grail_combine_out_of_place<T: Sortable>(
    set: &mut [T],
    buffer: &mut [T],
    keys: usize,
    start: usize,
    length: usize,
    subarray_len: usize,
    block_len: usize,
    merge_count: usize,
    last_subarray: usize,
) {
    buffer[0..block_len].copy_from_slice(&set[start - block_len..start]);
    for merge_index in 0..merge_count {
        let offset = start + (merge_index * (2 * subarray_len));
        let block_count = (2 * subarray_len) / block_len;

        grail_insertion_sort(set, keys, block_count);

        let mut median_key = subarray_len / block_len;
        median_key = grail_block_select_sort(set, keys, offset, median_key, block_count, block_len);

        grail_merge_blocks_out_of_place(
            set,
            keys,
            keys + median_key,
            offset,
            block_count,
            block_len,
            0,
            0,
        );
    }

    if last_subarray != 0 {
        let offset = start + (merge_count * (2 * subarray_len));
        let right_blocks = last_subarray / block_len;

        grail_insertion_sort(set, keys, right_blocks + 1);

        let mut median_key = subarray_len / block_len;
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, right_blocks, block_len);

        let last_fragment = last_subarray % block_len;
        let left_blocks = if last_fragment != 0 {
            grail_count_left_blocks(set, offset, right_blocks, block_len)
        } else {
            0
        };

        let block_count = right_blocks - left_blocks;
        if block_count == 0 {
            let left_length = left_blocks * block_len;
            grail_out_of_place_merge(set, offset, left_length, last_fragment, block_len as isize);
        } else {
            grail_merge_blocks_out_of_place(
                set,
                keys,
                keys + median_key,
                offset,
                block_count,
                block_len,
                left_blocks,
                last_fragment,
            );
        }
    }
    grail_out_of_place_buffer_reset(set, start, length, block_len);
    set[start - block_len..start].copy_from_slice(&buffer[0..block_len]);
}

fn grail_combine_in_place<T: Sortable>(
    set: &mut [T],
    keys: usize,
    start: usize,
    length: usize,
    subarray_len: usize,
    block_len: usize,
    merge_count: usize,
    last_subarray: usize,
    scrolling_buffer: bool,
) {
    for merge_index in 0..merge_count {
        let offset = start + (merge_index * (2 * subarray_len));
        let block_count = (2 * subarray_len) / block_len;

        grail_insertion_sort(set, keys, block_count);

        let mut median_key = subarray_len / block_len;
        median_key = grail_block_select_sort(set, keys, offset, median_key, block_count, block_len);

        if scrolling_buffer {
            grail_merge_blocks(
                set,
                keys,
                keys + median_key,
                offset,
                block_count,
                block_len,
                0,
                0,
            );
        } else {
            grail_lazy_merge_blocks(
                set,
                keys,
                keys + median_key,
                offset,
                block_count,
                block_len,
                0,
                0,
            );
        }
    }

    if last_subarray != 0 {
        let offset = start + (merge_count * (2 * subarray_len));
        let right_blocks = last_subarray / block_len;

        grail_insertion_sort(set, keys, right_blocks + 1);

        let mut median_key = subarray_len / block_len;
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, right_blocks, block_len);

        let last_fragment = last_subarray % block_len;
        let left_blocks = if last_fragment != 0 {
            grail_count_left_blocks(set, offset, right_blocks, block_len)
        } else {
            0
        };

        let block_count = right_blocks - left_blocks;

        if block_count == 0 {
            let left_length = left_blocks * block_len;

            if scrolling_buffer {
                grail_merge_forwards(set, offset, left_length, last_fragment, block_len as isize);
            } else {
                grail_lazy_merge(set, offset, left_length, last_fragment);
            }
        } else {
            if scrolling_buffer {
                grail_merge_blocks(
                    set,
                    keys,
                    keys + median_key,
                    offset,
                    block_count,
                    block_len,
                    left_blocks,
                    last_fragment,
                );
            } else {
                grail_lazy_merge_blocks(
                    set,
                    keys,
                    keys + median_key,
                    offset,
                    block_count,
                    block_len,
                    left_blocks,
                    last_fragment,
                );
            }
        }
    }

    if scrolling_buffer {
        grail_in_place_buffer_reset(set, start, length, block_len);
    }
}

fn grail_lazy_merge<T: Sortable>(
    set: &mut [T],
    mut start: usize,
    mut left_len: usize,
    mut right_len: usize,
) {
    if left_len < right_len {
        while left_len != 0 {
            let insert_pos =
                grail_binary_search_left(set, start + left_len, right_len, &set[start]);

            if insert_pos != 0 {
                grail_rotate(set, start, left_len, insert_pos);
                start += insert_pos;
                right_len -= insert_pos;
            }

            if right_len == 0 {
                break;
            } else {
                start += 1;
                left_len -= 1;
                while left_len != 0 && set[start] <= set[start + left_len] {
                    start += 1;
                    left_len -= 1;
                }
            }
        }
    } else {
        let mut end = start + left_len + right_len - 1;
        while right_len != 0 {
            let insert_pos = grail_binary_search_right(set, start, left_len, &set[end]);

            if insert_pos != left_len {
                grail_rotate(set, start + insert_pos, left_len - insert_pos, right_len);
                end -= left_len - insert_pos;
                left_len = insert_pos;
            }

            if left_len == 0 {
                break;
            } else {
                let left_end = start + left_len - 1;
                end -= 1;
                right_len -= 1;
                while right_len != 0 && set[left_end] <= set[end] {
                    end -= 1;
                    right_len -= 1;
                }
            }
        }
    }
}

fn grail_lazy_stable_sort<T: Sortable>(set: &mut [T], start: usize, length: usize) {
    let mut index = 1;
    while index < length {
        let left = start + index - 1;
        let right = start + index;

        if set[left] > set[right] {
            set.swap(left, right);
        }
        index += 2;
    }
    let mut merge_len = 2;
    while merge_len < length {
        let mut merge_index = 0;
        let merge_end = length - (2 * merge_len);

        while merge_index <= merge_end {
            grail_lazy_merge(set, start + merge_index, merge_len, merge_len);
            merge_index += 2 * merge_len;
        }

        let left_over = length - merge_index;
        if left_over > merge_len {
            grail_lazy_merge(set, start + merge_index, merge_len, left_over - merge_len);
        }

        merge_len *= 2;
    }
}

fn grail_insertion_sort<T: Sortable>(set: &mut [T], start: usize, length: usize) {
    for item in 1..length {
        let mut left: isize = (start + item - 1) as isize;
        let mut right: isize = (start + item) as isize;

        while left >= start as isize && set[left as usize] > set[right as usize] {
            set.swap(left as usize, right as usize);
            left -= 1;
            right -= 1;
        }
    }
}

fn calc_min_keys(num_keys: usize, mut block_keys_sum: usize) -> usize {
    let mut min_keys = 1;
    while min_keys < num_keys && block_keys_sum != 0 {
        min_keys *= 2;
        block_keys_sum /= 8;
    }
    min_keys
}

pub fn grail_common_sort<T: Sortable>(
    set: &mut [T],
    start: usize,
    length: usize,
    ext_buf: &mut Option<&mut [T]>,
) {
    if length < 16 {
        grail_insertion_sort(set, start, length);
        return;
    } else {
        let mut block_len = 1;
        while block_len * block_len < length {
            block_len *= 2;
        }

        let mut key_len = ((length - 1) / block_len) + 1;

        let ideal_keys = key_len + block_len;

        let keys_found = grail_collect_keys(set, start, length, ideal_keys);
        let ideal_buffer;
        if keys_found < ideal_keys {
            if keys_found < 4 {
                grail_lazy_stable_sort(set, start, length);
                return;
            } else {
                key_len = block_len;
                block_len = 0;
                ideal_buffer = false;

                while key_len > keys_found {
                    key_len /= 2;
                }
            }
        } else {
            ideal_buffer = true;
        }

        let buffer_end = block_len + key_len;
        let mut buffer_len = if ideal_buffer { block_len } else { key_len };

        grail_build_blocks(
            set,
            ext_buf,
            start + buffer_end,
            length - buffer_end,
            buffer_len,
        );

        while length - buffer_end > 2 * buffer_len {
            buffer_len *= 2;

            let mut current_block_len = block_len;
            let mut scrolling_buffer = ideal_buffer;

            if !scrolling_buffer {
                if key_len > 4 && (key_len / 8) * key_len >= buffer_len {
                    current_block_len = key_len / 2;
                    scrolling_buffer = true;
                } else {
                    let block_keys_sum = (buffer_len * keys_found) / 2;
                    let min_keys = calc_min_keys(key_len, block_keys_sum);

                    current_block_len = (2 * buffer_len) / min_keys;
                }
            }
            grail_combine_blocks(
                set,
                ext_buf,
                start,
                start + buffer_end,
                length - buffer_end,
                buffer_len,
                current_block_len,
                scrolling_buffer,
            );
        }
        grail_insertion_sort(set, start, buffer_end);
        grail_lazy_merge(set, start, buffer_end, length - buffer_end);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::grailpair::GrailPair;
    use rand::{thread_rng, Rng};

    #[test]
    fn bufferless_grail_power_of_2_sizes() {
        for i in 8..20 {
            let mut rng = thread_rng();
            let len = 2usize.pow(i);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort(&mut set, len);
            verify_sort(&set);
        }
    }
    #[test]
    fn bufferless_grail_power_of_2_plus_one_sizes() {
        for i in 8..20 {
            let mut rng = thread_rng();
            let len = 2usize.pow(i) + 1;
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort(&mut set, len);
            verify_sort(&set);
        }
    }
    #[test]
    fn bufferless_grail_power_of_2_sizes_already_sorted_all_unique() {
        for i in 8..20 {
            let len = 2usize.pow(i) + 1;
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: x as isize,
                    value: x as isize,
                })
                .collect();
            grail_sort(&mut set, len);
            verify_sort(&set);
        }
    }
    #[test]
    fn bufferless_grail_random_sizes_random_values() {
        for _ in 0..12 {
            let mut rng = thread_rng();
            let len = rng.gen_range(17, 524288);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort(&mut set, len);
            verify_sort(&set);
        }
    }

    #[test]
    fn static_buffer_grail_power_of_2_sizes() {
        for i in 8..20 {
            let mut rng = thread_rng();
            let len = 2usize.pow(i);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort_with_static_buffer(&mut set, len);
            verify_sort(&set);
        }
    }
    #[test]
    fn static_buffer_grail_power_of_2_plus_one_sizes() {
        for i in 8..20 {
            let mut rng = thread_rng();
            let len = 2usize.pow(i) + 1;
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort_with_static_buffer(&mut set, len);
            verify_sort(&set);
        }
    }
    #[test]
    fn static_buffer_grail_power_of_2_sizes_already_sorted_all_unique() {
        for i in 8..20 {
            let len = 2usize.pow(i) + 1;
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: x as isize,
                    value: x as isize,
                })
                .collect();
            grail_sort_with_static_buffer(&mut set, len);
            verify_sort(&set);
        }
    }
    #[test]
    fn static_buffer_grail_random_sizes_random_values() {
        for _ in 0..12 {
            let mut rng = thread_rng();
            let len = rng.gen_range(17, 524288);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort_with_static_buffer(&mut set, len);
            verify_sort(&set);
        }
    }
    #[test]
    fn dynamic_buffer_grail_power_of_2_sizes() {
        for i in 8..20 {
            let mut rng = thread_rng();
            let len = 2usize.pow(i);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort_with_dynamic_buffer(&mut set, len);
            verify_sort(&set);
        }
    }
    #[test]
    fn dynamic_buffer_grail_power_of_2_plus_one_sizes() {
        for i in 8..20 {
            let mut rng = thread_rng();
            let len = 2usize.pow(i) + 1;
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort_with_dynamic_buffer(&mut set, len);
            verify_sort(&set);
        }
    }

    #[test]
    fn dynamic_buffer_grail_power_of_2_sizes_already_sorted_all_unique() {
        for i in 8..20 {
            let len = 2usize.pow(i) + 1;
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: x as isize,
                    value: x as isize,
                })
                .collect();
            grail_sort_with_dynamic_buffer(&mut set, len);
            verify_sort(&set);
        }
    }

    #[test]
    fn dynamic_buffer_grail_random_sizes_random_values() {
        for _ in 0..12 {
            let mut rng = thread_rng();
            let len = rng.gen_range(17, 524288);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort_with_dynamic_buffer(&mut set, len);
            verify_sort(&set);
        }
    }

    fn verify_sort(set: &[GrailPair]) {
        for i in 1..set.len() {
            assert!(
                set[i].key >= set[i - 1].key,
                "indices {} and {} out of order; ({}, {})",
                i - 1,
                i,
                set[i - 1].key,
                set[i].key
            );
            if set[i].key == set[i - 1].key {
                assert!(
                    set[i].value > set[i - 1].value,
                    "indices {} and {} are unstable; ({}, {})",
                    i - 1,
                    i,
                    set[i - 1].value,
                    set[i].value
                );
            }
        }
    }
}
