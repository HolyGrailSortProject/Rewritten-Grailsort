//! grailsort.zig
//!
//! This implementation is based on the version maintained by The Holy Grail Sort Project.
//! https://github.com/MusicTheorist/Rewritten-Grailsort
//! It would not have been possible without their patient and detailed explanations of how
//! this ridiculous sort is supposed to work.
//!
//! PLEASE NOTE, THIS IS A WORK IN PROGRESS!
//! This code should not be used in production yet, or really for anything except reference.
//! It is not done yet or fully tested, and some cases are not even implemented.
//!
//! MIT License
//! 
//! Copyright (c) 2013 Andrey Astrelin
//! Copyright (c) 2020 The Holy Grail Sort Project
//! Copyright (c) 2021 Martin Wickham
//! 
//! Permission is hereby granted, free of charge, to any person obtaining a copy
//! of this software and associated documentation files (the "Software"), to deal
//! in the Software without restriction, including without limitation the rights
//! to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//! copies of the Software, and to permit persons to whom the Software is
//! furnished to do so, subject to the following conditions:
//! 
//! The above copyright notice and this permission notice shall be included in all
//! copies or substantial portions of the Software.
//! 
//! THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//! IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//! FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//! AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//! LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//! OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//! SOFTWARE.
//!

const std = @import("std");
const assert = std.debug.assert;

// ----------------------- Public API -------------------------

/// Sorts the array in-place
pub fn sort(
    comptime T: type,
    array: []T,
    context: anytype,
    comptime lessThan: fn(context: @TypeOf(context), lhs: T, rhs: T) bool,
) void {
    sortCommon(T, array, context, lessThan, emptySlice(T));
}

/// Sorts with an allocated buffer.  If allocation of the optimal buffer
/// size fails, performs an in-place sort instead.
pub fn sortWithAllocatedBuffer(
    comptime T: type,
    array: []T,
    context: anytype,
    comptime lessThan: fn(context: @TypeOf(context), lhs: T, rhs: T) bool,
    allocator: *std.mem.Allocator,
) void {
    const len = findOptimalBufferLength(array.len);
    var allocated = true;
    const buffer = allocator.alloc(T, len) catch blk: {
        allocated = false;
        break :blk emptySlice(T);
    };
    defer if (allocated) allocator.free(items);

    sortCommon(T, array, context, lessThan, buffer);
}

/// Returns the optimal buffer length for a given array size.
/// Meant for use with sortExternal.
pub fn findOptimalBufferLength(array_len: usize) usize {
    // find the smallest power of two that is at least
    // the sqrt of the length of the array.  This method
    // handles overflow when the length is close to MAX_USIZE.
    var block_len: usize = 4;
    var block_len_sq: usize = 16;
    while (block_len_sq < array_len and block_len_sq != 0) {
        block_len_sq <<= 2;
        block_len <<= 1;
    }
    return block_len;
}

/// Sorts using an external buffer to help make things faster.
/// Use findOptimalBufferLength to find the best buffer length for a given size.
/// Buffers longer than findOptimalBufferLength are still optimal.
/// Buffers smaller than findOptimalBufferLength may still be helpful.
pub fn sortExternal(
    comptime T: type,
    array: []T,
    context: anytype,
    comptime lessThan: fn(context:@TypeOf(context), lhs: T, rhs: T) bool,
    buffer: []T,
) void {
    sortCommon(T, array, context, lessThan, buffer);
}


// ---------------------------- Implementation -----------------------------

// TODO-OPT: There are many places where this implementation could specify
// noalias but does not.  There may be a perf benefit to doing so, especially
// when keys are passed separately from data, or if the comparator is opaque.
//
// TODO-OPT: There are many places where this implementation divides by a
// power of two.  We could consider passing around the log2 value and using
// shifts instead, but these divisions are not usually on critical paths so
// it may not be worth very much.
//
// TODO-ZEN: This implementation is not very consistent between using slices
// and using ptr + len parameters.  It may be worth using pointers in more
// places to make the indexing nicer, especially in places where there is
// a junk buffer before the valid data.

/// This sort can handle three different methods for buffer management.
const BufferMode = enum {
    /// There are not enough unique values in the array to make an
    /// inline buffer.  Fall back to in place merge sorts with no
    /// buffer.
    no_buffer,

    /// There is an inline buffer which may be used to accelerate
    /// merge sorts, but must be preserved.
    inline_buffer,

    /// An external buffer has been provided, don't worry about
    /// preserving values in the internal buffer.
    external_buffer,
};

/// Arrays smaller than this will do insertion sort instead
/// TODO-OPT: Tune this value.
const TUNE_TOO_SMALL = 16;

/// If the array has fewer than this many unique elements, use a sort that
/// works better on arrays with few actual items.
/// TODO-OPT: Tune this value.
const TUNE_TOO_FEW_KEYS = 4;

/// If the external buffer is smaller than this many items,
/// it's not worth the extra overhead of the out of place merge.
/// This must always be at least 2, otherwise the out of place
/// merge will crash.  If the buffer is less than 4 items,
/// the out of place merge degrades to the in place merge plus
/// some checks, so it's not worth it.
/// TODO-OPT: Tune this value.
const TUNE_MIN_BUILD_BLOCKS_BUFFER = 4;

/// If this is true, when running with an external buffer,
/// the junk buffer will be filled with undefined.
const DEBUG_SET_UNDEFINED = false;

/// Root sorting function, used by all public api points.
fn sortCommon(
    comptime T: type,
    array: []T,
    context: anytype,
    comptime lessThanFn: fn(context:@TypeOf(context), lhs: T, rhs: T) bool,
    buffer: []T,
) void {
    const Comparator = struct {
        //! This struct just cleans up the parameter lists of inner functions.
        context: @TypeOf(context),

        pub inline fn lessThan(self: @This(), lhs: T, rhs: T) bool {
            // TODO-API: do some tests to see if a compare function
            // can actually be performant here
            return lessThanFn(self.context, lhs, rhs);
        }

        pub inline fn compare(self: @This(), lhs: T, rhs: T) std.math.Order {
            // TODO-OPT: use an actual compare function here
            if (lessThanFn(self.context, lhs, rhs)) return .lt;
            if (lessThanFn(self.context, rhs, lhs)) return .gt;
            return .eq;
        }
    };
    const cmp = Comparator{ .context = context };

    // If the array is too small, just do insertion sort.
    if (array.len < TUNE_TOO_SMALL) {
        insertSort(T, array, cmp);
        return;
    }

    // This sort works by building a "junk buffer" at the beginning
    // of the array.  The junk buffer will be used as scratch space
    // to accelerate other parts of the sort.  We will need to rearrange
    // the items in the junk buffer freely.  In order to do that
    // and maintain stability, we require that all items in the junk
    // buffer are unique.

    // The rest of the list will be split up into fixed-size blocks.
    // These blocks must be a power of two in size, so that we can
    // use a fast scrolling merge sort to create them.  As shown in
    // the paper, the best size for this list is the square root of
    // the length of the array.

    // This calculates the smallest power of two that is greater
    // than or equal to sqrt(array.len).
    var block_len = findOptimalBufferLength(array.len);

    // We will also need a key item at the beginning of the array
    // for each block, which we will use to maintain stability in
    // the sort.

    // key_len = ceil(array.len / block_len)
    // this is safe because array.len >= 16 (and therefore > 0).
    // This could be a floor division instead if the use is updated.
    // TODO-OPT: Test a bunch of cases with and without this.
    // Does it make a meaningful difference?
    var key_len = ((array.len - 1) / block_len) + 1;

    const ideal_external_buffer = buffer.len >= block_len;

    // So the total number of unique items needed at the start of
    // the list is the sum of the number of keys and the block length.
    // We only need to include the junk buffer in the keys if we
    // don't have a large enough external buffer.  Otherwise the
    // junk buffer is stable so it doesn't need to be unique.
    var ideal_keys = if (ideal_external_buffer) key_len else (key_len + block_len);

    // Now we can go find those keys, and move them to the front of
    // the array.
    // TODO-OPT: We can probably use the external buffer to speed this
    // up if present.
    const keys_found = collectKeys(T, array, ideal_keys, cmp);

    // In the event that the array contains very many duplicate elements,
    // we may not be able to find enough unique keys. In that case, use
    // one of two fallback strategies.
    const ideal_buffer = keys_found >= ideal_keys;
    if (!ideal_buffer) {
        // If we didn't find enough keys, use one of two fallback strategies.
        if (keys_found < TUNE_TOO_FEW_KEYS) {
            // There are very few unique items, use a different sort.
            // TODO-OPT: Should this value be a percentage of the array length instead?
            // Or some more complicated calculation?
            // TODO-OPT: We can probably use the external buffer to speed this up if present.
            lazyStableSort(T, array, cmp);
            return;
        } else {
            // Strategy 2: Block swaps with small scrolling buffer and/or lazy merges
            // In this case, we will use the buffer we have to try to optimize
            // things for a bit, and then fall back to the keyed selection +
            // in place merge sort.  Start by reducing our initial
            // block length to be the size of our actual buffer.
            // TODO-OPT: key_len is a power of two, consider using @clz instead.
            // TODO-OPT: Without an external buffer, the optimal assignment is
            // to use half of the keys as keys and half as junk, but with an
            // external buffer it is better to use the external buffer as
            // junk and all of the keys as keys.  Later code assumes that
            // these two values are related by the in place optimal relation,
            // but we could pass separate parameters for these two values in
            // the external case to speed up this calculation.
            key_len = std.math.floorPowerOfTwo(usize, keys_found);
            block_len = 0;
        }
    }

    // In the normal case, this is the end of the keys buffer and
    // is equal to keys_found.  If there aren't enough keys, this
    // is just block_len instead.  If we have an external buffer,
    // this includes the junk buffer but we may have only found
    // key_len keys.
    var first_data_idx = if (ideal_external_buffer and ideal_buffer) block_len else (block_len + key_len);

    // Our initial blocks are normally the block length.
    // If we are in strategy 2, we will use our shortened
    // key length instead, to account for our limited buffer.
    // TODO-OPT: When we use all available space with an external
    // buffer in strategy 2, we will also need to update this.
    var subarray_len = if (ideal_buffer) block_len else key_len;

    // First, we need to sort each block.  This algorithm uses either
    // the junk buffer or an external buffer to do an in place merge
    // sort, displacing the junk buffer and moving it through the array.
    // When all is said and done, the junk buffer will be back where
    // it started.
    // TODO-OPT: With an ideal buffer, we don't even need to write the
    // junk buffer back to the array, we can keep it external forever.
    // TODO-ZEN: This `- subarray_len` is awkward, maybe use an array
    // pointer and data length instead?
    if (buffer.len >= TUNE_MIN_BUILD_BLOCKS_BUFFER) {
        buildBlocksExternal(T, array[first_data_idx - subarray_len..], subarray_len, buffer, cmp);
    } else {
        buildBlocksInPlace(T, array[first_data_idx - subarray_len..], subarray_len, cmp);
    }

    // At this point, pairs of blocks are sorted, so double the length.
    subarray_len *= 2;

    // save off our data length for future use
    const data_len = array.len - first_data_idx;

    // At the start of this loop, the array always looks as follows:
    // the keys and junk buffer are at the start of the array, unsorted.
    // They are followed by subarrays of length subarray_len, which are
    // each sorted.  In each iteration, we will combine and sort each
    // pair of subarrays, to yield larger subarrays.
    while (subarray_len < data_len) : (subarray_len *= 2) {
        var curr_block_len = block_len;
        var mode: BufferMode = .inline_buffer;

        if (!ideal_buffer) {
            // Even if we don't have the ideal buffer, we might still
            // be able to use a junk buffer for this pass.  We just
            // need to make sure that we have enough keys for both the
            // selection sort and the junk buffer.  We need to divvy up
            // our keys for use as block keys vs junk buffer.
            // since the junk buffer is the size of a block, and a
            // subarray is the remaining number of keys times the
            // block size, the maximum subarray size we can support
            // is (junk_keys * block_keys) / 2.  The maximum of this
            // function happens when junk_keys == block_keys, so our
            // check is (subarray_len * 2) <= (key_len / 2)^2.
            // TODO-OPT: We can get away with a slightly smaller key
            // buffer for the last iteration, because we don't use
            // the full subarray_len.
            const key_buffer = key_len / 2;
            if (key_buffer * key_buffer >= subarray_len * 2) {
                curr_block_len = key_buffer;
            } else {
                // If we can't use the scrolling buffer, we are going
                // to be doing in-place merging.  Since that's expensive,
                // we want to use the smallest block size possible,
                // and put more work on the selection sort.
                curr_block_len = (subarray_len * 2) / key_len;
                mode = .no_buffer;
            }
        }

        // If we have enough external buffer to put the junk buffer
        // in it, (and to hold all needed keys), use that to optimize
        // combineBlocks.
        // TODO-OPT: The second check here can only be different from
        // the first in strategy 2, in all other cases they are equal.
        if (buffer.len >= curr_block_len and buffer.len >= (subarray_len * 2 / curr_block_len)) {
            mode = .external_buffer;
        }

        // TODO-OPT: We don't need to do this repeatedly if we have an ideal buffer.
        if (mode == .external_buffer) {
            copyNoAlias(T, buffer.ptr, array.ptr, curr_block_len);
            setUndefined(T, array[0..curr_block_len]);
            moveBackToClobberFront(T, array[0..first_data_idx], first_data_idx - curr_block_len);
        }

        combineBlocks(T, array, first_data_idx, subarray_len, curr_block_len, mode, buffer, cmp);

        // TODO-OPT: We don't need to do this repeatedly if we have an ideal buffer.
        if (mode == .external_buffer) {
            moveFrontToClobberBack(T, array[0..first_data_idx], first_data_idx - curr_block_len);
            copyNoAlias(T, array.ptr, buffer.ptr, curr_block_len);
            setUndefined(T, buffer[0..curr_block_len]);
        }
    }

    // When all is said and done, we just have the keys at the beginning
    // of the array, and one sorted subarray of everything else that follows
    // it.  We'll finish by sorting the keys, and then performing an in-place
    // merge sort of the keys and everything else.
    // TODO-OPT: We could maybe do a better merge sort taking advantage of the
    // external buffer.  Even though it's not big enough to hold the entire
    // keys array, it can still help reduce swaps (or let us do them as blocks).
    insertSort(T, array[0..first_data_idx], cmp);
    lazyMerge(T, array, first_data_idx, cmp);
}

/// This function searches the list for the first ideal_keys unique elements.
/// It puts those items at the beginning of the array in sorted order, and
/// returns the number of unique values that it found to put in that buffer.
/// TODO-OPT: The keys at the beginning do not actually need to be in sorted order.
/// There might be a way to optimize this that clobbers order.
/// TODO-OPT: With an external buffer, we don't need to rewind or preserve keys,
/// we just need to move any not-chosen keys up past the key area.
fn collectKeys(comptime T: type, array: []T, ideal_keys: usize, cmp: anytype) usize {
    // The number of keys we have found so far.  Since the first
    // item in the array is always unique, we always count it.
    var keys_found: usize = 1;

    // The index of the array of the start of the key buffer.
    // The sorted buffer of keys will move around in the array,
    // but it starts at the very beginning.
    // This rotation is only necessary to preserve stability.
    // Without that, we could keep the list at the beginning
    // and swap displaced elements with keys.  But since we
    // need stability, we will move the keys list instead.
    // Moving the small keys list is a lot faster in the worst
    // case than moving the non-keys to preserve order.
    var first_key_idx: usize = 0;

    // The index in the array of the item we are currently considering
    // adding as a key.  The key buffer is always somewhere on the left
    // of this, but there may be non-key elements between the buffer and
    // this index.
    var curr_key_idx: usize = 1;

    // We will check every item in the list in order to see if it can be a key.
    while (curr_key_idx < array.len) : (curr_key_idx += 1) {
        // this is the current set of unique keys.  It moves over the course of
        // this search, which is why we have first_key_idx.  But it is always
        // sorted in ascending order.
        const keys = array[first_key_idx..][0..keys_found];

        // determine the index in the key buffer where we would insert this key.
        // TODO-OPT: If we use a compare function that can recognize equals,
        // this search can early out on equals, because we reject duplicate keys.
        const insert_key_idx = binarySearchLeft(T, keys, array[curr_key_idx], cmp);

        // at this point we know that array[curr_key_idx] <= keys[insert_key_idx].
        // So we can check if the key we are considering is unique by checking
        // if array[curr_key_idx] < keys[insert_key_idx].
        if (insert_key_idx == keys_found or
            cmp.lessThan(array[curr_key_idx], keys[insert_key_idx])) {
            
            // Move the keys list to butt up against the current key.
            // Moving the keys list like this instead of inserting at
            // the beginning of the array saves a ton of copies.
            // Note that this invalidates `keys`.
            rotate(T, array[first_key_idx..curr_key_idx], keys_found);
            first_key_idx = curr_key_idx - keys_found;

            // Now use rotate to insert the new key at the right position.
            const array_insert_idx = first_key_idx + insert_key_idx;
            const keys_after_insert = keys_found - insert_key_idx;
            rotate(T, array[array_insert_idx..][0..keys_after_insert + 1], keys_after_insert);

            // If we've found enough keys, we don't need to keep looking.  Break immediately.
            keys_found += 1;
            if (keys_found >= ideal_keys) break;
        }
    }

    // Ok, now we need to move the keys buffer back to the beginning of the array.
    rotate(T, array[0..first_key_idx + keys_found], first_key_idx);
    
    return keys_found;
}

/// This function sorts every block of block_len elements, starting at index block_len.
/// It uses a junk buffer of block_len elements at the beginning to accelerate the sort.
/// This buffer may be reordered, but will be back at the beginning of the array when
/// this function returns.
/// TODO-OPT: We should probably use a small stack buffer of 8 or 16 elements
/// and always call buildBlocksExternal, to optimize the first few merges.
/// As a bonus, this would let us delete the pairwiseSwaps function.
fn buildBlocksInPlace(comptime T: type, array: []T, block_len: usize, cmp: anytype) void {
    // We'll use iterative merge sorts to perform this sort.
    // Start with an optimized version of merge sort with a size of 1.
    // This function will also move two items of the junk buffer to the
    // end of the array, not just one.
    pairwiseSwaps(T, array[block_len-2..], cmp);
    // Then continue doing larger merge sorts and moving items to the end
    // of the array.  The last merge sort is done in reverse to move the
    // junk buffer back to the beginning.
    buildInPlace(T, array, 2, block_len, cmp);
}

/// Builds merge chunks in-place.  This function accepts an array that consists of
/// a set of keys followed by data items.  It must start with exactly
/// `block_len - already_merged_size` keys, followed by all the data items, followed by
/// `already_merged_size` more keys.  In other words, there are exactly block_len keys,
/// but already_merged_size of them have been moved to the end of the array already.
/// Additionally, before calling this function, every `already_merged_size`
/// items after the starting keys must be sorted.  The last partial block must also be sorted.
/// After calling this function, all of the keys will be at the beginning of the array,
/// and every chunk of 2*block_len items after the keys will be sorted.
/// The keys may be reordered during this process.  block_len and already_merged_size
/// must both be powers of two.
fn buildInPlace(comptime T: type, array: []T, already_merged_size: usize, block_len: usize, cmp: anytype) void {
    assert(std.math.isPowerOfTwo(block_len));
    assert(std.math.isPowerOfTwo(already_merged_size));
    assert(already_merged_size <= block_len);

    // start_position marks the beginning of the data elements.
    // It starts at block_len, moved back by the number of keys
    // that have already been merged to the back of the array.
    // As we move keys to the back, this will move left.
    var start_position = block_len - already_merged_size;
    const data_len = array.len - block_len;

    // We'll start with a merge size of smallest_merged_size items, and increase that until
    // it contains the whole list.  For each pass, we will merge pairs of chunks,
    // and also move some keys to the end.
    var merge_len = already_merged_size;
    while (merge_len < block_len) : (merge_len *= 2) {
        const full_merge_len = 2 * merge_len;
        
        // Our buffer will be the same size as our merge chunk.  That's how many
        // keys we will move in one pass over the array.
        const buffer_len = merge_len;
        
        // We'll consider each pair of merge chunks, and merge them together into one chunk.
        // While we do that, we'll propagate some keys from the front to the back of the list.  
        var merge_index = start_position;
        var remaining_unmerged = data_len;
        while (remaining_unmerged >= full_merge_len) : ({
            merge_index += full_merge_len;
            remaining_unmerged -= full_merge_len;
        }) {
            mergeForwards(T, array.ptr + merge_index, buffer_len, merge_len, merge_len, cmp);
        }

        // We need special handling for partial blocks at the end
        if (remaining_unmerged > merge_len) {
            // If we have more than one block, do a merge with the partial last block.
            mergeForwards(T, array.ptr + merge_index, buffer_len, merge_len, remaining_unmerged - merge_len, cmp);
        } else {
            // Otherwise, rotate the buffer past the sorted chunk of remaining array.
            // TODO-OPT: Rotate preserves the order of both halves, but we only care about
            // the order of the right half.  The left half can be completely unordered.  So
            // there's room here for a faster implementation.
            rotate(T, array[merge_index-buffer_len..][0..merge_len + remaining_unmerged], merge_len);
        }

        // Finally, move the start position back to get new keys next iteration
        start_position -= merge_len;
    }

    assert(start_position == 0);

    // Now that we've created sorted chunks of size block_len, we need
    // to do the last chunk.  For this one, we'll go backwards through the
    // array, moving the keys back to the beginning.

    const full_merge_len = 2 * block_len;
    // TODO-OPT: Pretty sure this is a power of two, we can use a mask here instead.
    const last_block_len = data_len % full_merge_len;
    var remaining_full_blocks = data_len / full_merge_len;
    const final_offset = data_len - last_block_len;

    // First we have to consider the special case of the partially sorted block
    // at the end of the array.  If it's smaller than a block, we can just rotate it.
    // Otherwise, we need to do a merge.
    if (last_block_len <= block_len) {
        rotate(T, array[final_offset..], last_block_len);
    } else {
        mergeBackwards(T, array.ptr + final_offset, block_len, last_block_len - block_len, block_len, cmp);
    }

    // Now continue to merge backwards through the rest of the array, back to the beginning.
    var merge_index = final_offset;
    while (remaining_full_blocks > 0) : (remaining_full_blocks -= 1) {
        merge_index -= full_merge_len;
        mergeBackwards(T, array.ptr + merge_index, block_len, block_len, block_len, cmp);
    }
}

/// This is similar to buildBlocksInPlace, but uses an external storage buffer
/// to reduce swaps.  It will copy junk items into the external array, and then
/// use a variant of the merge operation which clobbers the junk buffer.  Once
/// the merge size exceeds the size of the external buffer, it falls back to the
/// in-place version.
/// TODO-ZEN: Combine this with buildBlocksInPlace
fn buildBlocksExternal(comptime T: type, array: []T, block_len: usize, buffer: []T, cmp: anytype) void {
    // round the buffer length down to a power of two
    var pow2_buffer_len = if (buffer.len >= block_len) block_len
        else std.math.floorPowerOfTwo(usize, buffer.len);

    // copy as many keys as we can into the external block
    copyNoAlias(T, buffer.ptr, array.ptr + (block_len - pow2_buffer_len), pow2_buffer_len);
    setUndefined(T, (array.ptr + block_len - pow2_buffer_len)[0..pow2_buffer_len]);

    // Use a separate code path for pairs because it's much faster
    assert(pow2_buffer_len >= 2);
    var start_position = block_len - 2;
    pairwiseWrites(T, array[start_position..], cmp);

    // Then do forward merges just like in the in place version,
    // but clobber the junk buffer instead of preserving it.
    // TODO-ZEN: There is probably a better expression of this indexing,
    // see lazyStableSort for inspiration.
    var merge_len: usize = 2;
    while (merge_len < pow2_buffer_len) : (merge_len *= 2) {
        const full_merge_len = merge_len * 2;

        var remaining = array.len - block_len;
        var merge_position = start_position;

        while (remaining >= full_merge_len) : ({
            remaining -= full_merge_len;
            merge_position += full_merge_len;
        }) {
            mergeForwardExternal(T, array.ptr + merge_position, merge_len, merge_len, merge_len, cmp);
        }

        if (remaining > merge_len) {
            mergeForwardExternal(T, array.ptr + merge_position, merge_len, merge_len, remaining - merge_len, cmp);
        } else {
            copyNoAlias(T, array.ptr + merge_position - merge_len, array.ptr + merge_position, remaining);
            setUndefined(T, (array.ptr + merge_position)[0..remaining]);
        }

        start_position -= merge_len;
    }

    assert(start_position + pow2_buffer_len == block_len);

    // If our buffer can hold the whole block size, we can
    // do an out of place reverse merge as well.
    if (pow2_buffer_len == block_len) {
        const full_merge_len = 2 * block_len;
        const data_len = array.len - block_len;
        // TODO-OPT: Pretty sure this is a power of two, we can use a mask here instead.
        const last_block_len = data_len % full_merge_len;
        var remaining_full_blocks = data_len / full_merge_len;
        const final_offset = data_len - last_block_len;

        // First we have to consider the special case of the partially sorted block
        // at the end of the array.  If it's smaller than a block, we can just rotate it.
        // Otherwise, we need to do a merge.
        if (last_block_len <= block_len) {
            rotate(T, array[final_offset..], last_block_len);
        } else {
            mergeBackwardExternal(T, array.ptr + final_offset, block_len, last_block_len - block_len, block_len, cmp);
        }

        // Now continue to merge backwards through the rest of the array, back to the beginning.
        var merge_index = final_offset;
        while (remaining_full_blocks > 0) : (remaining_full_blocks -= 1) {
            merge_index -= full_merge_len;
            mergeBackwardExternal(T, array.ptr + merge_index, block_len, block_len, block_len, cmp);
        }

        // Then restore the buffer.
        // TODO-OPT: This isn't necessary, we can keep using the buffer.
        copyNoAlias(T, array.ptr + (block_len - pow2_buffer_len), buffer.ptr, pow2_buffer_len);
        setUndefined(T, buffer[0..pow2_buffer_len]);
    } else {
        copyNoAlias(T, array.ptr + (array.len - pow2_buffer_len), buffer.ptr, pow2_buffer_len);
        setUndefined(T, buffer[0..pow2_buffer_len]);

        // TODO-OPT: If the external buffer is large enough, we could do an
        // out-of-place reverse merge for even more speed.
        buildInPlace(T, array, merge_len, block_len, cmp);
    }
}

/// This function inspects every pair of elements in the given array,
/// starting with the third and fourth element, and moving forward by
/// two each time.  It puts each pair in the correct order, and moves
/// it back two elements.  The first two displaced elements are moved
/// to the end, but may not necessarily be in the correct order.
/// The caller should ensure that the first two elements are not equal,
/// otherwise the sort may not be stable.
/// The passed array must contain at least two elements.
/// So with this array:
///   [1 2  6 5  3 4  8 7  9]
/// It will sort it to
///   [5 6  3 4  7 8  9  2 1].
fn pairwiseSwaps(comptime T: type, array: []T, cmp: anytype) void {
    // save the keys to the stack
    const first_key = array[0];
    const second_key = array[1];

    // move all the items down two, while sorting them
    pairwiseWrites(T, array, cmp);

    // then stamp the saved keys on the end
    array[array.len-2] = first_key;
    array[array.len-1] = second_key;
}

/// This function inspects every pair of elements in the given array,
/// starting with the third and fourth element, and moving forward by
/// two each time.  It puts each pair in the correct order, and moves
/// it back two elements.  The first two displaced elements are clobbered.
/// So with this array:
///   [1 2  6 5  3 4  8 7  9]
/// It will sort it to
///   [5 6  3 4  7 8  9  X X]
fn pairwiseWrites(comptime T: type, array: []T, cmp: anytype) void {
    var index: usize = 3;
    while (index < array.len) : (index += 2) {
        // check if the items are out of order, ensuring that equal items
        // are considered to be in order.
        // TODO-OPT: This wouldn't be difficult to write in a branchless way,
        // see if that makes a difference.
        if (cmp.lessThan(array[index], array[index-1])) {
            // here they are out of order, swap them as we move them back.
            array[index - 3] = array[index];
            array[index - 2] = array[index - 1];
        } else {
            // here they are in order, copy them back preserving order.
            array[index - 3] = array[index - 1];
            array[index - 2] = array[index];
        }
    }

    // check if there's one extra item on the end
    if (index == array.len) {
        array[index - 3] = array[index-1];
    }
}

/// This function iterates pairs of subarrays of length subarray_len,
/// starting at first_block_idx, and including the partial subarray
/// at the end of the list.  Each subarray must be sorted, and after
/// this call the pairs will be combined into larger sorted subarrays.
/// There must be at least one item in the array before first_block_idx
/// for each block in the array, excluding the final partial block.
/// If use_junk_buffer is true, there must also be at least block_len
/// more elements for the junk buffer, which will be used to accelerate
/// the merge operation.
fn combineBlocks(
    comptime T: type,
    array: []T,
    first_block_idx: usize,
    subarray_len: usize,
    block_len: usize,
    mode: BufferMode,
    external_buffer: []T,
    cmp: anytype,
) void {
    // The total number of data items, excluding keys and the junk buffer
    const data_len = array.len - first_block_idx;
    // The length of a merged subarray
    const full_merge_len = 2 * subarray_len;
    // The number of full merges we will do
    var merge_count = data_len / full_merge_len;
    // The number of items that do not fit into a full merge
    const leftover_count = data_len % full_merge_len;
    // The number of blocks in a full merge
    const block_count = full_merge_len / block_len;
    // The number of blocks in a subarray
    const half_block_count = @divExact(block_count, 2);
    // The block index of the first block of the second subarray
    const initial_median = half_block_count;

    // The length of our inline junk buffer.
    const junk_len = if (mode == .no_buffer) 0 else block_len;
    // The array from which we will pull keys.
    const keys_base = if (mode == .external_buffer) external_buffer
        else array[0..first_block_idx - junk_len];

    // The index of the first subarray to be merged
    // TODO-ZEN: Consider making merge_start a pointer
    var merge_start: usize = first_block_idx;

    // Iterate through pairs of subarrays, merging them.
    // If we are using a junk buffer, this operation also
    // transfers it from the left to the right.
    while (merge_count > 0) : (merge_count -= 1) {
        // The keys are used to preserve stability in blockSelectSort.
        const keys = keys_base[0..block_count];

        // We need to make sure they are in order.
        insertSort(T, keys, cmp);

        // blockSelectSort will do a selection sort on the blocks in the array.
        // It also permutes the keys to match.  This puts blocks in closer to the
        // right order, allowing us to combine them with mergeBlocks.
        const median_key = blockSelectSort(T, keys.ptr, array.ptr + merge_start, initial_median, block_count, block_len, cmp);

        // TODO-ZIG: Replace this with inline switch when that's implemented
        // TODO-ZEN: Make the parameters the same for all of these in preparation
        switch (mode) {
        .no_buffer       => mergeBlocks(T, keys.ptr, median_key, array.ptr + merge_start, block_count, block_len, 0, 0,       .no_buffer, cmp),
        .inline_buffer   => mergeBlocks(T, keys.ptr, median_key, array.ptr + merge_start, block_count, block_len, 0, 0,   .inline_buffer, cmp),
        .external_buffer => mergeBlocks(T, keys.ptr, median_key, array.ptr + merge_start, block_count, block_len, 0, 0, .external_buffer, cmp),
        }

        merge_start += full_merge_len;
    }

    // If the number of left over items is greater than the size of a subarray,
    // we need to merge them.  This is a more difficult merge because the last
    // subarray cannot participate in the selection sort.  Because of that,
    // we cannot necessarily merge all full blocks, because some of them are
    // not ordered correctly with regard to the trailer.
    if (leftover_count > subarray_len) {
        const trailer_blocks = leftover_count / block_len;
        const trailer_items = leftover_count % block_len;

        // The +1 here adds an extra key which tracks the trailer items.
        // TODO-OPT: I don't think we actually need a key for the trailer.
        // hmm, we do always need one for the median though.
        const keys = keys_base[0..trailer_blocks+1];
        insertSort(T, keys, cmp);

        // perform our selection sort as usual, including even blocks that
        // may not end up being part of the standard sort.  Only do this if
        // we have full blocks on the right side.  If it's just a partial block,
        // everything except the partial block is already sorted (because it's
        // all the left side).
        const median_key = if (trailer_blocks <= half_block_count) initial_median
            else blockSelectSort(T, keys.ptr, array.ptr + merge_start, initial_median, trailer_blocks, block_len, cmp);

        // This counts the number of full blocks at the end of the trailer
        // that cannot participate in the standard merge because they come
        // after the start of the trailer in sorted order.
        // TODO-OPT: We know that any unfit blocks must come from the left
        // array.  This means we could find the unfit blocks before doing the
        // selection sort, and copy them directly to the end of the array.
        // This allows for a smaller selection sort, and means that the two
        // largest items (which will likely be swapped multiple times during
        // the sort) no longer participate.  It also means we need to insertion
        // sort three fewer keys :P
        const unfit_trailer_blocks: usize = if (trailer_items > 0) countLastMergeBlocks(T, array[merge_start..], trailer_blocks, block_len, cmp) else 0;

        // The number of blocks that do participate in the normal merge follows immediately.
        const normal_blocks = trailer_blocks - unfit_trailer_blocks;

        // If there are no normal blocks, the trailer comes first.
        if (normal_blocks == 0) {
            // Note that this can only happen if there are no trailer blocks
            // after the last full subarray.  If there were, those blocks
            // would be normal blocks.
            assert(trailer_blocks == half_block_count);

            // In this case, the selection sort did nothing, and the blocks
            // are all in sorted order.  So we just need to merge the trailer
            // items with the sorted left half.
            const left_len = trailer_blocks * block_len;
            const right_len = trailer_items;

            // TODO-ZIG: Change mode to an inline parameter once those are
            // implemented, to avoid this switch.
            switch (mode) {
            .no_buffer       => mergeIntoPrecedingJunk(T, array.ptr + merge_start, junk_len, left_len, trailer_items,       .no_buffer, cmp),
            .inline_buffer   => mergeIntoPrecedingJunk(T, array.ptr + merge_start, junk_len, left_len, trailer_items,   .inline_buffer, cmp),
            .external_buffer => mergeIntoPrecedingJunk(T, array.ptr + merge_start, junk_len, left_len, trailer_items, .external_buffer, cmp),
            }
        } else {
            const unfit_items = block_len * unfit_trailer_blocks + trailer_items;
            // Common case, some blocks participate in the merge.
            // TODO-ZIG: Replace this with inline switch when that's implemented
            switch (mode) {
            .no_buffer       => mergeBlocks(T, keys.ptr, median_key, array.ptr + merge_start, normal_blocks, block_len, unfit_trailer_blocks, unfit_items,       .no_buffer, cmp),
            .inline_buffer   => mergeBlocks(T, keys.ptr, median_key, array.ptr + merge_start, normal_blocks, block_len, unfit_trailer_blocks, unfit_items,   .inline_buffer, cmp),
            .external_buffer => mergeBlocks(T, keys.ptr, median_key, array.ptr + merge_start, normal_blocks, block_len, unfit_trailer_blocks, unfit_items, .external_buffer, cmp),
            }
        }

        merge_start += leftover_count;
        assert(merge_start == array.len);
    }

    // If we have a junk buffer, we need to move it back to the beginning of the list.
    // TODO-ZIG: Replace this with an inline switch or parameter when those are in.
    switch (mode) {
    .no_buffer       => moveFrontPastJunk(T, array[first_block_idx - junk_len..merge_start], merge_start - first_block_idx,       .no_buffer),
    .inline_buffer   => moveFrontPastJunk(T, array[first_block_idx - junk_len..merge_start], merge_start - first_block_idx,   .inline_buffer),
    .external_buffer => moveFrontPastJunk(T, array[first_block_idx - junk_len..merge_start], merge_start - first_block_idx, .external_buffer),
    }
}

/// Performs a selection sort on the blocks in the array.  Only the first item
/// in each sorted block is used for comparison.  If the first items in two blocks
/// tie, the keys are used to break the tie.  This keeps the sort stable.  But
/// it also means we need a full comparison function, not just a less than function,
/// so that we can detect ties.  Swaps made to the block data are also made to the keys.
/// The initial_median parameter is the index of a particular block.  That index is tracked
/// through swaps made by this function, and the sorted index of that block is returned.
/// This function does not handle the partial block on the end of the array.  That must be
/// done externally.
/// Note that the blocks_ptr parameter points to the first valid block.  It does not include
/// the junk buffer.
fn blockSelectSort(comptime T: type, noalias keys_ptr: [*]T, noalias blocks_ptr: [*]T, initial_median: usize, block_count: usize, block_len: usize, cmp: anytype) usize {
    const keys = keys_ptr[0..block_count];
    const blocks = blocks_ptr[0..block_count * block_len];
    assert(initial_median < block_count);

    // track the index of this block through the sort
    var median_key = initial_median;

    // blocks to the left of left_block are sorted.
    var left_block: usize = 0;
    while (left_block < block_count) : (left_block += 1) {
        // Search for the smallest block after or including this block
        var smallest_block = left_block;
        var right_block = left_block + 1;
        while (right_block < block_count) : (right_block += 1) {
            // Compare blocks by comparing the first item in each block.
            // Individual blocks are sorted, so this is comparing the smallest
            // item in each block.
            const order = cmp.compare(blocks[block_len *    right_block],
                                      blocks[block_len * smallest_block]);

            // If the blocks tie, use the keys to break the tie.
            // This keeps the sort stable, ensuring that the original
            // order of the input array is preserved.  It works because
            // keys are guaranteed to be unique, so they cannot be equal.
            if (order == .lt or
                (order == .eq and
                 cmp.lessThan(keys[right_block], keys[smallest_block]))
            ) {
                smallest_block = right_block;
            }
        }

        // If the left block is the smallest, nothing needs to be swapped.
        // It's already in the correct position.
        if (smallest_block != left_block) {
            // Swap the block contents
            blockSwap(
                T,
                blocks.ptr + block_len * left_block,
                blocks.ptr + block_len * smallest_block,
                block_len,
            );

            // Also swap the keys, to preserve stability.
            // TODO-OPT: If we have an external buffer and there is room,
            // we could store block indexes in it instead.  Those are faster
            // to compare than keys, and faster to swap.  They also don't
            // need to be sorted back afterwards.
            const tmp = keys[left_block];
            keys[left_block] = keys[smallest_block];
            keys[smallest_block] = tmp;

            // If one of the blocks we swapped was the one referenced by,
            // the median key, update the median key to track it.
            if (median_key == left_block) {
                median_key = smallest_block;
            } else if (median_key == smallest_block) {
                median_key = left_block;
            }
        }
    }

    return median_key;
}

/// When handling the trailing elements at the end of the array,
/// we cannot necessarily sort all complete blocks as normal, and
/// then merge in the trailer.  The reason is that the trailer does
/// not undergo the selection sort before merging, so it is not
/// necessarily true that the first element of the trailer would be
/// greater than the last sorted element.  Because of this, we
/// can't actually merge all trailer blocks as normal.  This function
/// counts how many trailer blocks we need to merge manually in order
/// to make sure the sort works.
fn countLastMergeBlocks(
    comptime T: type,
    trailer: []T,
    trailer_blocks: usize,
    block_len: usize,
    cmp: anytype,
) usize {
    var blocks_to_merge_manually: usize = 0;
    var first_item_after_blocks = trailer_blocks * block_len;
    var curr_full_block = first_item_after_blocks;

    // We can include a block in the normal sort as long as that
    // block's first item is less than or equal to the trailer.
    // If it's greater than the the first item in the trailer,
    // we can't sort it normally because we may end up with items
    // greater than the start of the trailer in the "sorted" part
    // of the list.  In the case that the start of a block is
    // equal to the start of the trailer, the block's starting
    // value is considered to be less than the trailer, because
    // the trailer consists of the items that were at the end of the
    // array when the sort began.
    while (blocks_to_merge_manually < trailer_blocks and
        cmp.lessThan(trailer[first_item_after_blocks],
                     trailer[curr_full_block - block_len])) {
        blocks_to_merge_manually += 1;
        curr_full_block -= block_len;
    }

    return blocks_to_merge_manually;
}

/// This function accepts a list of keys and a list of blocks.
/// After calling it, the scratch buffer at the beginning of the
/// array will be at the end (reordered), and all other items
/// will be sorted on the left.  If the mode needs a junk buffer,
/// the list of blocks must be preceded by block_len items of junk,
/// and be followed by block_count * block_len items of data.
/// For that data, within each block, the items must be sorted.
/// The blocks themselves must be sorted based on the first item
/// in each block.  The data may optionally be followed by a set
/// of "trailer blocks", which must also be sorted in the same way.
/// There may be yet more items in a partial block after the 
/// trailer blocks.  trailer_len is the total of the items in the
/// trailer blocks and the items afterwards.
/// Trailer blocks must match the criteria in countLastMergeBlocks.
fn mergeBlocks(
    comptime T         : type,
    noalias keys_ptr   : [*]const T,
    median_key         : usize,
    noalias blocks_ptr : [*]T,
    block_count        : usize,
    block_len          : usize,
    trailer_blocks     : usize,
    trailer_len        : usize,
    comptime mode      : BufferMode,
    cmp                : anytype,
) void {
    const junk_len = if (mode == .no_buffer) 0 else block_len;

    // if this is the last segment, we may need one extra item for the median key.
    const keys = keys_ptr[0..block_count + trailer_blocks + 1];
    const blocks = (blocks_ptr - junk_len)[0..junk_len + block_count * block_len + trailer_len];

    // When we start, our first block is after the junk buffer
    // (at index block_len), and the next block is one block
    // after that.
    var next_block = junk_len + block_len;
    var curr_block_len = block_len;

    // This origin tells us which subarray the current block
    // came from, before we did the selection sort on blocks.
    // true means left, false means right.  The subarrays were
    // originally sorted, so if we find two adjacent blocks
    // from the same subarray, we know they are already sorted,
    // and we can skip forward a block without any work.
    // TODO-OPT: I think we can just check median_key to see if it's
    // equal to zero here, keys[0] must be either zero or block_count/2.
    var curr_block_from_left_subarray = cmp.lessThan(keys[0], keys[median_key]);

    var key_idx: usize = 1; // TODO-ZEN: rename to next_block
    while (key_idx < block_count) : (key_idx += 1) {
        // This is the beginning of one of the two arrays to be merged.
        // The other array starts at index next_block.  At this point
        // in the loop, the junk buffer is in one single block immediately
        // before this index.
        const curr_block = next_block - curr_block_len;
        const next_block_from_left_subarray = cmp.lessThan(keys[key_idx], keys[median_key]);

        // If both blocks came from the same sub-array, they are already sorted.
        // We just need to move the junk buffer past the current block, so that
        // we can grab a new block and check again.
        if (next_block_from_left_subarray == curr_block_from_left_subarray) {
            // We know that everything to the left of the buffer is sorted,
            // and that everything in the current block is less than anything
            // in the next block.  The current block is also sorted, so we
            // can just move it to the sorted part of the list, and swap it
            // with the displaced junk buffer.
            swapWithPrecedingJunk(T, blocks.ptr + curr_block, junk_len, curr_block_len, mode);

            // After doing that, we know that the next block we grab will be a
            // full block, so set the length accordingly.
            curr_block_len = block_len;
        } else {
            // If the next two blocks don't come from same sub-array, they need
            // to be merged. We know that the last item in the left array is smaller
            // than the first item in the following block from the left array.
            // Similarly, the last item in the right array is smaller than the first
            // item in the following block of the right array.  Therefore, the smaller
            // of the last items from the two blocks we are merging is smaller than both
            // of the next blocks we might encounter.  So we don't need to look at any
            // blocks after these two until we've reached the end of one of the blocks.
            // At that point, we will stop merging, change our current block to be
            // the remaining list, and then grab the next unchecked block as the new second list.

            if (mode != .no_buffer) {
                // Iterators for our two arrays and output buffer
                var buffer_idx = curr_block - junk_len;

                // For stability, when items are equal, we need to prefer items
                // from the left subarray.  For this merge, we are always merging
                // between separate sub-arrays.  `left` will always be items from
                // the `left` subarray, and `right` will always be from the right.
                // TODO-ZEN: I think we can keep these iterators consistent
                // and avoid all this ugliness by making them persistent outside
                // of this scope.  It would also let us get rid of the
                // curr_block_from_left_subarray variable.
                var left = if (curr_block_from_left_subarray) curr_block
                    else next_block;
                const left_end = left + if (curr_block_from_left_subarray) curr_block_len
                    else block_len;
                var right = if (curr_block_from_left_subarray) next_block
                    else curr_block;
                const right_end = right + if (curr_block_from_left_subarray) block_len
                    else curr_block_len;

                // Merge sort until we reach the end of one of the merge arrays.
                // TODO-ZEN: Can we combine this with other merge sort code?
                while (left < left_end and right < right_end) {
                    if (cmp.lessThan(blocks[right], blocks[left])) {
                        if (comptime mode == .inline_buffer) {
                            const tmp = blocks[right];
                            blocks[right] = blocks[buffer_idx];
                            blocks[buffer_idx] = tmp;
                        } else {
                            comptime assert(mode == .external_buffer);
                            blocks[buffer_idx] = blocks[right];
                            if (DEBUG_SET_UNDEFINED) blocks[right] = undefined;
                        }
                        right += 1;
                    } else {
                        if (comptime mode == .inline_buffer) {
                            const tmp = blocks[left];
                            blocks[left] = blocks[buffer_idx];
                            blocks[buffer_idx] = tmp;
                        } else {
                            comptime assert(mode == .external_buffer);
                            blocks[buffer_idx] = blocks[left];
                            if (DEBUG_SET_UNDEFINED) blocks[left] = undefined;
                        }
                        left += 1;
                    }
                    buffer_idx += 1;
                }

                // TODO-ZEN: I think we can get rid of all of this cleanup,
                // but I'm not totally sure how yet.
    
                // At this point, only one of the arrays is empty.  Check if
                // it's the current one.  If so, we have junk buffer that moved into
                // the right array, which is now on the right of the current
                // array.  We need to move the remaining parts of the current
                // array to the right of the junk buffer.
                // TODO-OPT: I don't think we actually need to do this if we
                // use smarter iterators.
                if (left < left_end and curr_block_from_left_subarray) {
                    moveFrontPastJunk(T, blocks[left..right_end], left_end - left, mode);
                } else if (right < right_end and !curr_block_from_left_subarray) {
                    moveFrontPastJunk(T, blocks[right..left_end], right_end - right, mode);
                } else {
                    // Our "current" block is now the block that was "next", so
                    // update the subarray to match.
                    curr_block_from_left_subarray = next_block_from_left_subarray;
                }

                // Update the current block to point to the remaining items.
                // One of the following two terms must be zero.
                curr_block_len = (right_end - right) + (left_end - left);
            } else {
                // mode == .no_buffer
                // In place merge sort.  This is pretty expensive, so make
                // sure that the blocks aren't already sorted, just in case.
                // TODO-ZEN: There must be a way to merge these cases. They
                // are EXACTLY the same except one calls binarySearchLeft
                // and the other calls binarySearchRight.
                // ... and the lessThan check is different.
                if (curr_block_from_left_subarray) {
                    if (cmp.lessThan(blocks[next_block], blocks[next_block-1])) {
                        var rest = blocks[next_block - curr_block_len .. next_block + block_len];
                        while (curr_block_len > 0) {
                            // find the insert index in the right list
                            const insert_idx = curr_block_len + binarySearchLeft(T, rest[curr_block_len..], rest[0], cmp);
                            // move the left list to that index
                            rotate(T, rest[0..insert_idx], curr_block_len);

                            // If we moved it to the end of the right list, we need
                            // to grab the next chunk.  Stop merging here.
                            if (insert_idx == rest.len) {
                                curr_block_len = rest.len;
                                break;
                            }

                            // leave one item here
                            curr_block_len -= 1;
                            // TODO-OPT: Probably worth doing a greedy check
                            // here to see if we can immediately cement more items.
                            rest = rest[insert_idx - curr_block_len..];
                        } else {
                            // the loop terminated normally, meaning the left list ran out.
                            // leave the rest of the right list as the curr block.
                            curr_block_len = rest.len;
                            curr_block_from_left_subarray = next_block_from_left_subarray;
                        }
                    } else {
                        curr_block_len = block_len;
                        curr_block_from_left_subarray = next_block_from_left_subarray;
                    }
                } else {
                    if (!cmp.lessThan(blocks[next_block-1], blocks[next_block])) {
                        var rest = blocks[next_block - curr_block_len .. next_block + block_len];
                        while (curr_block_len > 0) {
                            // find the insert index in the right list
                            const insert_idx = curr_block_len + binarySearchRight(T, rest[curr_block_len..], rest[0], cmp);
                            // move the left list to that index
                            rotate(T, rest[0..insert_idx], curr_block_len);

                            // If we moved it to the end of the right list, we need
                            // to grab the next chunk.  Stop merging here.
                            if (insert_idx == rest.len) {
                                curr_block_len = rest.len;
                                break;
                            }

                            // leave one item here
                            curr_block_len -= 1;
                            // TODO-OPT: Probably worth doing a greedy check
                            // here to see if we can immediately cement more items.
                            rest = rest[insert_idx - curr_block_len..];
                        } else {
                            // the loop terminated normally, meaning the left list ran out.
                            // leave the rest of the right list as the curr block.
                            curr_block_len = rest.len;
                            curr_block_from_left_subarray = next_block_from_left_subarray;
                        }
                    } else {
                        curr_block_len = block_len;
                        curr_block_from_left_subarray = next_block_from_left_subarray;
                    }
                } // curr_block_from_left_subarray
            } // mode != .no_buffer
        }

        // After all that, move to the next block.
        next_block += block_len;
    }

    // At this point, we still have one partial array left to the right of the junk buffer.
    // curr_block here points to the start of that partial array.
    var curr_block = next_block - curr_block_len;

    // The trailer is the special case set of items at the very end of the array
    // that cannot be part of the normal merge process.  This is because they are
    // either part of the elements at the very end of the array that do not fit
    // into a block, or they are blocks from the left array which conflict with
    // the elements at the very end (see countLastMergeBlocks).
    if (trailer_len != 0) {
        if (curr_block_from_left_subarray) {
            // If the current block is from the left subarray, then everything
            // that remains except the final items is from the left subarray,
            // and is already sorted.  So we can safely extend the current
            // block all the way up to the last block, and then merge.
            curr_block_len += block_len * trailer_blocks;
        } else {
            // If the current block is from the right subarray, we know that
            // the remaining items are less than the first item after the blocks.
            // But we also know that the smallest item in each remaining block
            // is greater than the first item after the blocks (because that's
            // the condition required for the block to be part of the trailer).
            // So we know that everything remaining in our current buffer is
            // sorted, and no items to the right of it will be part of it.
            // This means we can move the remaining items directly into the
            // sorted part of the array.
            swapWithPrecedingJunk(T, blocks.ptr + curr_block, junk_len, curr_block_len, mode);
            curr_block = next_block;

            // Everything after this point must come from the left array, for
            // the same reasons as in the other case.  We can fall back to a merge.
            curr_block_len = block_len * trailer_blocks;
            curr_block_from_left_subarray = true;
        }

        // In either case above, there are only two sorted arrays left - the remaining items from the left
        // side blocks that were incompatible with the trailer items, and the trailer items.
        // Use a merge sort.  We can use the buffer here because the trailer is shorter
        // than a block.
        mergeIntoPrecedingJunk(T, blocks.ptr + curr_block, junk_len, curr_block_len, trailer_len - block_len * trailer_blocks, mode, cmp);
    } else {
        // If there's no trailer (the common case), any remaining items are
        // sorted.  We just need to move the buffer across them, so that the
        // next iteration can use it.
        swapWithPrecedingJunk(T, blocks.ptr + curr_block, junk_len, curr_block_len, mode);
    }
}

/// Merges two arrays, using the preceding junk buffer to accelerate the operation.
/// Picks an implementation based on the buffer mode.
inline fn mergeIntoPrecedingJunk(comptime T: type, data_ptr: [*]T, junk_len: usize, left_len: usize, right_len: usize, comptime mode: BufferMode, cmp: anytype) void {
    switch (comptime mode) {
    .no_buffer => lazyMerge(T, data_ptr[0..left_len + right_len], left_len, cmp),
    .inline_buffer   => mergeForwards       (T, data_ptr, junk_len, left_len, right_len, cmp),
    .external_buffer => mergeForwardExternal(T, data_ptr, junk_len, left_len, right_len, cmp),
    }
}

/// Swaps a data block with part of the junk buffer.  Uses one of several
/// implementations, depending on the buffer mode.  The segment of junk
/// and the segment of data must not overlap.  After this call the data
/// at data_ptr will be moved to data_ptr - junk_len, and will be the same
/// length.  The mode determines what happens to the data in the junk buffer.
inline fn swapWithPrecedingJunk(comptime T: type, data_ptr: [*]T, junk_len: usize, swap_len: usize, comptime mode: BufferMode) void {
    switch (comptime mode) {
    .no_buffer => assert(junk_len == 0), // no junk buffer, everything is where it needs to be.
    // TODO-OPT: This preserves the order of the junk buffer.
    // There may be an opportunity to speed it up by giving up
    // that constraint.
    .inline_buffer   =>   blockSwap(T, data_ptr - junk_len, data_ptr, swap_len),
    .external_buffer => {
        copyNoAlias(T, data_ptr - junk_len, data_ptr, swap_len);
        setUndefined(T, data_ptr[0..swap_len]);
    },
    }
}

/// Moves data past the junk that follows it, moving the junk back to
/// the beginning.  Optimized for the buffer mode.
inline fn moveFrontPastJunk(comptime T: type, array: []T, data_len: usize, comptime mode: BufferMode) void {
    switch (mode) {
    .no_buffer => {}, // everything is where it needs to be
    .inline_buffer   => moveFrontToBack       (T, array, data_len),
    .external_buffer => moveFrontToClobberBack(T, array, data_len),
    }
}

/// This function accepts an array made up of three parts:
/// a sliding buffer, a sorted left half, and a sorted right half, in that order.
/// It merges the left and right halves into a single sorted buffer at the beginning,
/// while rotating the sliding buffer to the end.  The sliding buffer may be reordered
/// during this process.
fn mergeForwards(comptime T: type, data_start: [*]T, buffer_len: usize, left_len: usize, right_len: usize, cmp: anytype) void {
    // The buffer must be at least as large as the right array,
    // to prevent overwriting the left array.
    assert(buffer_len >= right_len);

    // we will do everything relative to the start of the buffer.
    const array = data_start - buffer_len;

    // tracking iterators for our three sections
    var buffer: usize = 0;
    var left = buffer_len;
    const left_end = left + left_len;
    var right = left_end;
    const right_end = right + right_len;

    // Pretty standard merge sort, but merge into the buffer.
    // While doing this, move the buffer data into the merged out slots.
    // Loop until the entire right side is consumed.
    while (right < right_end) {
        // TODO-OPT: This could be made branchless, test that and see if it's faster.
        if (left >= left_end or cmp.lessThan(array[right], array[left])) {
            const tmp = array[buffer];
            array[buffer] = array[right];
            array[right] = tmp;
            right += 1;
        } else {
            const tmp = array[buffer];
            array[buffer] = array[left];
            array[left] = tmp;
            left += 1;
        }
        buffer += 1;
    }

    // If anything remains on the left side, move it directly to the end of the list.
    // We only need to do this if there is more buffer in the way, otherwise it is
    // already at the end of the list.
    if (buffer != left) {
        // TODO-OPT: This can alias if right_len < buffer_len.
        // We usually know statically at the call site if that
        // is the case, is it worth bifurcating codegen?
        moveBackToFront(T, array[buffer..left_end], left_end - left);
    }
}

/// Like mergeForwards, this function accepts an array made up of three parts:
/// a sorted left half, a sorted right half, and a sliding buffer, in that order.
/// It merges the left and right halves into a single sorted buffer at the end,
/// while rotating the sliding buffer to the beginning.  The sliding buffer may be
/// reordered during this process.
fn mergeBackwards(comptime T: type, array: [*]T, left_len: usize, right_len: usize, buffer_len: usize, cmp: anytype) void {
    // The buffer must be at least as large as the left array,
    // to prevent overwriting the right array.
    // At the end we assume that the remainder of the right
    // buffer does not alias the final junk buffer.  This
    // happens when the left array is at least as large as
    // the junk buffer.  So they must be exactly equal.
    assert(buffer_len == left_len);

    // Iterators.  These are empty, that is they point to the slot after the next element.
    const left_end: usize = 0;
    var left = left_len;
    const right_end = left;
    var right = right_end + right_len;
    var buffer = right + buffer_len;

    while (left > left_end) {
        buffer -= 1;
        // TODO-OPT: This could be made branchless, test that and see if it's faster.
        if (right == right_end or cmp.lessThan(array[right-1], array[left-1])) {
            left -= 1;
            const tmp = array[left];
            array[left] = array[buffer];
            array[buffer] = tmp;
        } else {
            right -= 1;
            const tmp = array[right];
            array[right] = array[buffer];
            array[buffer] = tmp;
        }
    }

    // If anything remains on the right side, move it directly to the beginning of the list.
    // We only need to do this if there is more buffer in the way, otherwise it is
    // already at the beginning of the list.
    // TODO-OPT: This preserves the order of the junk buffer, but we don't actually need that.
    if (right != buffer) {
        const remain = right - right_end;
        blockSwap(T, array + right_end, array + (buffer - remain), remain);
    }
}

/// This function accepts an array made up of three parts:
/// a scratch buffer, a sorted left half, and a sorted right half, in that order.
/// It merges the left and right halves into a single sorted buffer at the beginning,
/// leaving the memory at the end undefined.
fn mergeForwardExternal(comptime T: type, data_ptr: [*]T, buffer_len: usize, left_len: usize, right_len: usize, cmp: anytype) void {
    // The buffer must be at least as large as the right array,
    // to prevent overwriting the left array.
    assert(buffer_len >= right_len);

    // We will do everything relative to the start of the buffer
    const array = data_ptr - buffer_len;

    // tracking iterators for our three sections
    var buffer: usize = 0;
    var left = buffer_len;
    const left_end = left + left_len;
    var right = left_end;
    const right_end = right + right_len;

    // Pretty standard merge sort, but merge into the buffer.
    // While doing this, move the buffer data into the merged out slots.
    // Loop until the entire right side is consumed.
    while (right < right_end) {
        // TODO-OPT: This could be made branchless, test that and see if it's faster.
        if (left >= left_end or cmp.lessThan(array[right], array[left])) {
            array[buffer] = array[right];
            if (DEBUG_SET_UNDEFINED) array[right] = undefined;
            right += 1;
        } else {
            array[buffer] = array[left];
            if (DEBUG_SET_UNDEFINED) array[left] = undefined;
            left += 1;
        }
        buffer += 1;
    }

    // If anything remains on the left side, move it directly to the end of the list.
    // We only need to do this if there is more buffer in the way, otherwise it is
    // already at the end of the list.
    if (buffer != left) {
        // TODO-OPT: This can alias if right_len < buffer_len.
        // We usually know statically at the call site if that
        // is the case, is it worth bifurcating codegen?
        moveBackToClobberFront(T, array[buffer..left_end], left_end - left);
    }
}

/// Like mergeForwards, this function accepts an array made up of three parts:
/// a sorted left half, a sorted right half, and a sliding buffer, in that order.
/// It merges the left and right halves into a single sorted buffer at the end,
/// clobbering the data at the beginning.
fn mergeBackwardExternal(comptime T: type, array: [*]T, left_len: usize, right_len: usize, buffer_len: usize, cmp: anytype) void {
    // The buffer must be at least as large as the left array,
    // to prevent overwriting the right array.
    // At the end we assume that the remainder of the right
    // buffer does not alias the final junk buffer.  This
    // happens when the left array is at least as large as
    // the junk buffer.  So they must be exactly equal.
    assert(buffer_len == left_len);

    // Iterators.  These are empty, that is they point to the slot after the next element.
    const left_end: usize = 0;
    var left = left_len;
    const right_end = left;
    var right = right_end + right_len;
    var buffer = right + buffer_len;

    while (left > left_end) {
        buffer -= 1;
        // TODO-OPT: This could be made branchless, test that and see if it's faster.
        if (right == right_end or cmp.lessThan(array[right-1], array[left-1])) {
            left -= 1;
            array[buffer] = array[left];
        } else {
            right -= 1;
            array[buffer] = array[right];
        }
    }

    // If anything remains on the right side, move it directly to the beginning of the list.
    // We only need to do this if there is more buffer in the way, otherwise it is
    // already at the beginning of the list.
    // TODO-OPT: This preserves the order of the junk buffer, but we don't actually need that.
    if (right != buffer) {
        const remain = right - right_end;
        copyNoAlias(T, array + (buffer - remain), array + right_end, remain);
    }
    setUndefined(T, array[0..buffer_len]);
}

/// This function performs an iterative fully in-place merge sort of the array,
/// starting with a fully unsorted list and working its way up.  We use it
/// in the case where the array has very few unique items.  (specifically, fewer
/// than four).
/// TODO-OPT: There might be better sorts for this case.  Counting sort
/// would need extra storage though, and quicksort is not stable, so
/// those are out.  But we could at least use external storage maybe.
fn lazyStableSort(comptime T: type, array: []T, cmp: anytype) void {
    // sort pairs in-place
    var i: usize = 1;
    while (i < array.len) : (i += 2) {
        if (cmp.lessThan(array[i], array[i-1])) {
            const tmp = array[i-1];
            array[i-1] = array[i];
            array[i] = tmp;
        }
    }

    // iteratively do merge sort with larger sets of items.
    var merge_size: usize = 2;
    while (merge_size < array.len) : (merge_size *= 2) {
        var full_merge = merge_size * 2;

        // Merge pairs of sorted blocks
        var merge_index: usize = 0;
        while (merge_index + full_merge <= array.len) : (merge_index += full_merge) {
            lazyMerge(T, array[merge_index..][0..full_merge], merge_size, cmp);
        }

        // Check for a partial block at the end
        if (merge_index + merge_size < array.len) {
            lazyMerge(T, array[merge_index..], merge_size, cmp);
        }
    }
}

/// This function performs an in-place merge sort, without using a junk buffer.
/// It is much slower than mergeForward and mergeForwardExternal, so those should
/// be preferred if possible.
/// TODO-OPT: This can absolutely use external storage if available.
fn lazyMerge(comptime T: type, array: []T, left_len: usize, cmp: anytype) void {
    // For performance, always sort the shorter array into the longer one.
    // TODO-OPT: The reference implementation has a tight loop to recognize
    // when multiple keys are already in order and avoid unnecessary binary
    // search calls.  This is probably worth doing, since the relevant items
    // are cached and it's a quick check.
    const right_len = array.len - left_len;
    if (left_len <= right_len) {
        // If left is smaller, iteratively find insertion points in the right
        // half and move the left array to that index with `rotate`.
        var rest = array;
        var left_remain = left_len;
        while (rest.len > left_remain and left_remain > 0) {
            // find the insertion index
            const insert_idx = binarySearchLeft(T, rest[left_remain..], rest[0], cmp) + left_remain;
            // move the left array to that index
            rotate(T, rest[0..insert_idx], left_remain);
            // leave the smallest element here
            left_remain -= 1;
            rest = rest[insert_idx - left_remain..];
        }
    } else {
        // If right is smaller, iteratively find insertion points in the left
        // half and move the right array to that index with `rotate`.
        var rest = array;
        var right_remain = right_len;
        while (rest.len > right_remain and right_remain > 0) {
            // find the insertion index
            const left_remain = rest.len - right_remain;
            const insert_idx = binarySearchRight(T, rest[0..left_remain], rest[rest.len-1], cmp);
            // move the right array to that index
            const insert_len = left_remain - insert_idx;
            rotate(T, rest[insert_idx..], insert_len);
            // leave the largest element here
            right_remain -= 1;
            rest = rest[0..insert_idx + right_remain];
        }
    }
}

/// A standard linear scan insertion sort.  Picks items from the
/// unsorted right half and moves them to the sorted left half
/// until the entire array is sorted.
fn insertSort(comptime T: type, array: []T, cmp: anytype) void {
    // items to the left of i are sorted
    var i: usize = 1;
    while (i < array.len) : (i += 1) {
        var left = i;
        const item = array[i];
        // scan left to find the insertion point,
        // copying greater elements to the right.
        while (left > 0 and cmp.lessThan(item, array[left-1])) {
            array[left] = array[left-1];
            left -= 1;
        }
        // insert the item.
        array[left] = item;
    }
}

/// Finds the index of the left-most value in the sorted array
/// that is greater than or equal to the target.  If there is no
/// such element, the length of the array is returned.
fn binarySearchLeft(comptime T: type, array: []const T, target: T, cmp: anytype) usize {
    var left: usize = 0;
    var right = array.len;
    // TODO-OPT: consider using a duffs device branchless search.
    while (left < right) {
        // this is equivalent to (right - left)/2, but avoids overflow.
        // TODO-OPT: may not be worth it though? analyze the possibility
        // for overflow here and consider not having it.
        const middle = left + (right - left) / 2;
        if (cmp.lessThan(array[middle], target)) {
            left = middle + 1;
        } else {
            right = middle;
        }
    }
    return left;
}

/// Finds the index of the left-most value in the sorted array
/// that is strictly greater than the target.  If there is no
/// such element, the length of the array is returned.
fn binarySearchRight(comptime T: type, array: []const T, target: T, cmp: anytype) usize {
    var left: usize = 0;
    var right = array.len;
    // TODO-OPT: consider using a duffs device branchless search.
    while (left < right) {
        // this is equivalent to (right - left)/2, but avoids overflow.
        // TODO-OPT: may not be worth it though? analyze the possibility
        // for overflow here and consider not having it.
        const middle = left + (right - left) / 2;
        if (cmp.lessThan(target, array[middle])) {
            right = middle;
        } else {
            left = middle + 1;
        }
    }
    return right;
}

/// Moves a set of buffer_len items from the beginning of the passed array
/// to the end.  The order of the moved items is preserved.  Displaced
/// items are moved to the front, but their order is not preserved.
fn moveFrontToBack(
    comptime T: type,
    array: []T,
    buffer_len: usize,
) void {
    // TODO-OPT: Use a stack buffer to accelerate this, or use SSE
    var front = buffer_len;
    var back = array.len;
    while (front > 0) {
        front -= 1; back -= 1;
        const tmp = array[front];
        array[front] = array[back];
        array[back] = tmp;
    }
}

/// Moves buffer_len items from the start of the array to the back,
/// clobbering any displaced items at the back.
fn moveFrontToClobberBack(
    comptime T: type,
    array: []T,
    buffer_len: usize,
) void {
    // TODO-OPT: Use a stack buffer to accelerate this, or use SSE
    var front = buffer_len;
    var back = array.len;
    while (front > 0) {
        front -= 1; back -= 1;
        array[back] = array[front];
    }
    setUndefined(T, array[0..back]);
}

/// Moves a set of buffer_len items from the end of the passed array
/// to the beginning.  The order of the moved items is preserved.  Displaced
/// items are moved to the back, but their order is not preserved.
fn moveBackToFront(
    comptime T: type,
    array: []T,
    buffer_len: usize,
) void {
    // TODO-OPT: Use a stack buffer to accelerate this, or use SSE
    var front: usize = 0;
    var back = array.len - buffer_len;
    while (back < array.len) : ({front += 1; back += 1;}) {
        const tmp = array[front];
        array[front] = array[back];
        array[back] = tmp;
    }
}

/// Moves buffer_len items from the back of the array to the start,
/// clobbering any displaced items at the start.
fn moveBackToClobberFront(
    comptime T: type,
    array: []T,
    buffer_len: usize,
) void {
    // TODO-OPT: Use a stack buffer to accelerate this, or use SSE
    var front: usize = 0;
    var back = array.len - buffer_len;
    while (back < array.len) : ({front += 1; back += 1;}) {
        array[front] = array[back];
    }
    setUndefined(T, array[front..]);
}

/// Swaps an array around a pivot point.
/// Example:
///   [0123 S 456789]
///   [4567 S 012389] // block swap L
///   4567[0123 S 89] // move forward 4
///   4567[0189 S 23] // block swap R
///   4567[01 S 89]23 // move back 2
///   4567[89 S 01]23 // block swap L
///   456789[01 S ]23 // move forward 2
///   left_len == remain.len, exit loop
///   4567890123
fn rotate(comptime T: type, array: []T, pivot: usize) void {
    // TODO-OPT: This is optimized for rotations where the pivot is
    // far from either end of the array.  If the pivot is within a
    // certain threshold of the end of the array (say, 16 elements),
    // we should instead copy the elements onto the stack and use a memmove.
    // This is not purely theoretical.  In some cases, this function is
    // used to rotate exactly one element.  Those cases are pathologically
    // slow with this implementation.
    var remain = array;
    var left_len = pivot;
    while (left_len > 0 and left_len < remain.len) {
        if (left_len + left_len <= remain.len) {
            blockSwap(T, remain.ptr, remain.ptr + left_len, left_len);
            remain = remain[left_len..];
        } else {
            const right_len = remain.len - left_len;
            blockSwap(T, remain.ptr + (left_len - right_len), remain.ptr + left_len, right_len);
            remain = remain[0..left_len];
            left_len -= right_len;
        }
    }
}

/// Swaps left[0..block_len] with right[0..block_len].  The two arrays must not overlap.
fn blockSwap(comptime T: type, noalias left: [*]T, noalias right: [*]T, block_len: usize) void {
    assertNoAlias(T, left, block_len, right, block_len);

    var idx: usize = 0;
    while (idx < block_len) : (idx += 1) {
        // TODO-OPT: optimization of this loop is highly dependent on the size of T.
        // The left and right halves of the array are guaranteed not to alias,
        // but the compiler may not realize this. We could explicitly use a
        // vectorized memswap here instead to go faster.
        const tmp = right[idx];
        right[idx] = left[idx];
        left[idx] = tmp;
    }
}

/// Copies count items from src to dest. src and dest must not alias.
fn copyNoAlias(comptime T: type, noalias dest: [*]T, noalias src: [*]const T, count: usize) void {
    assertNoAlias(T, dest, count, src, count);
    @memcpy(@ptrCast([*]u8, dest), @ptrCast([*]const u8, src), count * @sizeOf(T));
}

/// Asserts that two regions of memory do not overlap.
inline fn assertNoAlias(comptime T: type, noalias a: [*]const T, a_len: usize, noalias b: [*]const T, b_len: usize) void {
    // TODO-ZIG: when arePointersComparable is implemented, do this.
    // if (comptime @arePointersComparable(a, b)) {
        assert(a_len == 0 or b_len == 0 or
               @ptrToInt(a + a_len) <= @ptrToInt(b) or
               @ptrToInt(b + b_len) <= @ptrToInt(a));
    // }
}

/// Returns an empty mutable slice containing T.
/// The pointer is not undefined, but dereferencing it is UB.
/// TODO-ZIG: In the current compiler implementation, the pointer
/// actually may be undefined.  This is a problem because it breaks
/// optionals.  But hopefully that's irrelevant here.
fn emptySlice(comptime T: type) []T {
    var x = [_]T{};
    return &x;
}

inline fn setUndefined(comptime T: type, data: []T) void {
    if (DEBUG_SET_UNDEFINED) {
        for (data) |*v| v.* = undefined;
    }
}


// --------------------------------- Tests ---------------------------------

// mark Tests as referenced so its' tests get compiled.
comptime { _ = Tests; }

pub const runAllTests = Tests.runAll;

const Tests = struct {
    const testing = std.testing;
    const print = std.debug.print;

    fn runAll() void {
        const tests = .{
            "emptySlice",
            "copyNoAlias",
            "blockSwap",
            "rotate",
            "moveBackToFront",
            "moveFrontToBack",
            "binarySearchLeft",
            "insertSort",
            "mergeForwards",
            "mergeBackwards",
            "mergeForwardExternal",
            "lazyMerge",
            "lazyStableSort",
            "collectKeys",
            "pairwiseSwaps",
            "pairwiseWrites",
            "buildInPlace",
            "buildBlocksExternal",
            "mergeBlocks_noTrailer",
            "mergeBlocks_withTrailer",
            "mergeBlocks_noTrailerLazy",
            "mergeBlocks_withTrailerLazy",
            "mergeBlocks_noTrailerExternal",
            "mergeBlocks_withTrailerExternal",
            "combineBlocksInPlace",
            "combineBlocksInPlace_lazy",
            "sort_inPlace_enoughKeys",
            "sort_inPlace_notEnoughKeys",
            "sort_external_enoughKeys",
            "sort_external_notEnoughKeys",
        };

        print("Running tests...\n", .{});
        inline for (tests) |fn_name| {
            print("{}...\n", .{fn_name});
            @field(@This(), "test_"++fn_name)();
        }
        print("All {} tests passed.\n", .{tests.len});
    }

    test "sort_inPlace_enoughKeys" { test_sort_inPlace_enoughKeys(); }
    fn test_sort_inPlace_enoughKeys() void {
        var array = [_]u32{
            17, 30,  8, 14, 11,  3, 12, 24,
            33,  2,  1, 36, 37, 23,  6, 38,
             5, 13, 26, 16, 31, 15,  0, 20,
            35, 19, 18, 28, 34, 32, 25,  7,
            21,  9, 29,  4, 10, 27, 40, 39,
            22,  
        };

        sort(u32, &array, {}, asc_ignoreBottomBitFn);

        const sorted = [_]u32{
             1,  0,  3,  2,  5,  4,  6,  7,
             8,  9, 11, 10, 12, 13, 14, 15,
            17, 16, 19, 18, 20, 21, 23, 22,
            24, 25, 26, 27, 28, 29, 30, 31,
            33, 32, 35, 34, 36, 37, 38, 39,
            40,
        };

        testing.expectEqualSlices(u32, &sorted, &array);
    }

    test "sort_inPlace_notEnoughKeys" { test_sort_inPlace_notEnoughKeys(); }
    fn test_sort_inPlace_notEnoughKeys() void {
        var array = [_]u32{
            17,  0,  8, 14, 11,  3, 12, 14,
             3,  2,  1,  6,  7, 13,  6,  8,
             5, 13, 16, 16,  1, 15,  0, 20,
             5, 19, 18, 18,  4,  2, 15,  7,
            11,  9, 19,  4, 10, 17, 10,  9,
            12,
        };

        sort(u32, &array, {}, asc_ignoreBottomBitFn);

        const sorted = [_]u32{
             0,  1,  1,  0,  3,  3,  2,  2,
             5,  5,  4,  4,  6,  7,  6,  7,
             8,  8,  9,  9, 11, 11, 10, 10,
            12, 13, 13, 12, 14, 14, 15, 15,
            17, 16, 16, 17, 19, 18, 18, 19,
            20,
        };

        testing.expectEqualSlices(u32, &sorted, &array);
    }

    test "sort_external_enoughKeys" { test_sort_external_enoughKeys(); }
    fn test_sort_external_enoughKeys() void {
        var buffer: [44]u32 = undefined;
        for (buffer[1..]) |_, i| {
            std.mem.set(u32, &buffer, 0xFFFFFFFF);

            var array = [_]u32{
                17, 30,  8, 14, 11,  3, 12, 24,
                33,  2,  1, 36, 37, 23,  6, 38,
                 5, 13, 26, 16, 31, 15,  0, 20,
                35, 19, 18, 28, 34, 32, 25,  7,
                21,  9, 29,  4, 10, 27, 40, 39,
                22,  
            };

            // use canaries that will be sorted to the wrong place
            // if they are observed.
            buffer[i+1] = 1;
            buffer[0] = 0xEA7F00D5;

            sortExternal(u32, &array, {}, asc_ignoreBottomBitFn, buffer[1..i+1]);

            const sorted = [_]u32{
                1,  0,  3,  2,  5,  4,  6,  7,
                8,  9, 11, 10, 12, 13, 14, 15,
                17, 16, 19, 18, 20, 21, 23, 22,
                24, 25, 26, 27, 28, 29, 30, 31,
                33, 32, 35, 34, 36, 37, 38, 39,
                40,
            };

            testing.expectEqual(@as(u32, 1), buffer[i+1]);
            testing.expectEqual(@as(u32, 0xEA7F00D5), buffer[0]);
            testing.expectEqualSlices(u32, &sorted, &array);
        }
    }

    test "sort_external_notEnoughKeys" { test_sort_external_notEnoughKeys(); }
    fn test_sort_external_notEnoughKeys() void {
        var buffer: [44]u32 = undefined;
        buffer[0] = 0xEA7F00D5;
        for (buffer[1..]) |_, i| {
            std.mem.set(u32, &buffer, 0xFFFFFFFF);

            var array = [_]u32{
                17,  0,  8, 14, 11,  3, 12, 14,
                3,  2,  1,  6,  7, 13,  6,  8,
                5, 13, 16, 16,  1, 15,  0, 20,
                5, 19, 18, 18,  4,  2, 15,  7,
                11,  9, 19,  4, 10, 17, 10,  9,
                12,
            };

            // use canaries that will be sorted to the wrong place
            // if they are observed.
            buffer[i+1] = 1;
            buffer[0] = 0xEA7F00D5;

            sortExternal(u32, &array, {}, asc_ignoreBottomBitFn, buffer[1..i+1]);

            const sorted = [_]u32{
                0,  1,  1,  0,  3,  3,  2,  2,
                5,  5,  4,  4,  6,  7,  6,  7,
                8,  8,  9,  9, 11, 11, 10, 10,
                12, 13, 13, 12, 14, 14, 15, 15,
                17, 16, 16, 17, 19, 18, 18, 19,
                20,
            };

            testing.expectEqual(@as(u32, 1), buffer[i+1]);
            testing.expectEqual(@as(u32, 0xEA7F00D5), buffer[0]);
            testing.expectEqualSlices(u32, &sorted, &array);
        }
    }

    test "collectKeys" { test_collectKeys(); }
    fn test_collectKeys() void {
        // test with enough keys
        var test1 = [_]u32{
            17, 30,  8, 14, 11,  3, 12, 24,
            33,  2,  1, 36, 37, 23,  6, 38,
            5, 13, 26, 16, 31, 15,  0, 20,
            35, 19, 18, 28, 34, 32, 25,  7,
            21,  9, 29,  4, 10, 27, 40, 39,
            22,  
        };

        const found_keys_1 = collectKeys(u32, &test1, 14, asc_ignoreBottomBit);
        // We should find all 14 keys in this array.
        testing.expectEqual(@as(usize, 14), found_keys_1);

        // Keys are not necessarily ordered, but are stable.
        // order them to check.
        insertSort(u32, test1[0..found_keys_1], asc_ignoreBottomBit);

        const test1_result = [_]u32{
            1,  3,  6,  8, 11, 12, 14, 17, 
            23, 24, 30, 33, 36, 38,
                                    2, 37,
            5, 13, 26, 16, 31, 15,  0, 20,
            35, 19, 18, 28, 34, 32, 25,  7,
            21,  9, 29,  4, 10, 27, 40, 39,
            22,
        };

        testing.expectEqualSlices(u32, &test1_result, &test1);

        // test with not enough keys
        var test2 = [_]u32{
            5, 4, 3, 4, 7, 4, 4, 2, 6, 2, 11, 6, 10, 9,
        };

        const found_keys_2 = collectKeys(u32, &test2, 10, asc_ignoreBottomBit);
        testing.expectEqual(@as(usize, 5), found_keys_2);

        insertSort(u32, test2[0..found_keys_2], asc_ignoreBottomBit);
        const test2_result = [_]u32{
            3, 5, 7, 9, 11,
            4, 4, 4, 4, 2, 6, 2, 6, 10,
        };
        testing.expectEqualSlices(u32, &test2_result, &test2);
    }

    test "buildInPlace" { test_buildInPlace(); }
    fn test_buildInPlace() void {
        // We're going to go from sorted blocks of two to blocks of 8.
        // This will do one forward merge pass and one reverse merge pass.
        var buffer = [_]u32{
            // two keys at the beginning
            1<<20, 1<<21,

            // in order
            2, 4, 6, 8,
            10, 12, 14, 16, 
            // reversed           
            14, 16, 10, 12,
            6, 8, 2, 4,
            // mixed 1
            2, 4, 10, 12,
            6, 8, 14, 16,
            // mixed 2
            14, 16, 6, 8,
            10, 12, 2, 4,
            // mixed 3
            6, 16, 8, 14,
            2, 12, 4, 10,
            // stability
            8, 10, 2, 4,
            3, 5, 7, 9,
            // stability 2
            7, 9, 3, 5,
            2, 4, 8, 10,
            // stability 3
            4, 5, 2, 3,
            8, 9, 6, 7,

            // trailer
            6, 8, 2, 4,
            5, 10, 7,

            // two keys at the end from the first pass
            1<<22, 1<<23,
        };

        const key_sum = sum(u32, buffer[0..2]) + sum(u32, buffer[buffer.len-2..]);

        // N.B. block size is 4, to produce chunks of size 8.
        buildInPlace(u32, &buffer, 2, 4, asc_ignoreBottomBit);

        const sorted = [_]u32{
            2, 4, 6, 8, 10, 12, 14, 16, // 0
            2, 4, 6, 8, 10, 12, 14, 16, // 8
            2, 4, 6, 8, 10, 12, 14, 16, // 16
            2, 4, 6, 8, 10, 12, 14, 16, // 24
            2, 4, 6, 8, 10, 12, 14, 16, // 32
            2, 3, 4, 5, 7, 8, 9, 10,    // 40
            3, 2, 5, 4, 7, 9, 8, 10,    // 48
            2, 3, 4, 5, 6, 7, 8, 9,     // 56
            2, 4, 5, 6, 7, 8, 10,       // 64
        };

        testing.expectEqual(key_sum, sum(u32, buffer[0..4]));
        testing.expectEqualSlices(u32, &sorted, buffer[4..]);
    }

    test "buildBlocksExternal" { test_buildBlocksExternal(); }
    fn test_buildBlocksExternal() void {
        var external_buffer: [10]u32 = undefined;
        for (external_buffer[1..9]) |_, i| {
            if (i < 2) continue;
            // We're going to go from sorted blocks of two to blocks of 8.
            // This will do one forward merge pass and one reverse merge pass.
            var buffer = [_]u32{
                // four keys at the beginning
                1<<20, 1<<21, 1<<22, 1<<23,

                // in order
                2, 4, 6, 8,
                10, 12, 14, 16, 
                // reversed           
                16, 14, 12, 10,
                8, 6, 4, 2,
                // mixed 1
                2, 4, 10, 12,
                6, 8, 14, 16,
                // mixed 2
                16, 14, 6, 8,
                10, 12, 4, 2,
                // mixed 3
                16, 6, 8, 14,
                12, 2, 4, 10,
                // stability
                8, 10, 2, 4,
                3, 5, 9, 7, 
                // stability 2
                7, 9, 5, 3,
                2, 4, 8, 10,
                // stability 3
                5, 4, 3, 2,
                9, 8, 7, 6,

                // trailer
                6, 8, 4, 2,
                5, 10, 7,
            };

            external_buffer[0] = 0xBADF00D5;
            external_buffer[i+1] = 0;

            // N.B. block size is 4, to produce chunks of size 8.
            buildBlocksExternal(u32, &buffer, 4, external_buffer[1..i+1], asc_ignoreBottomBit);

            // verify canaries
            testing.expectEqual(@as(u32, 0xBADF00D5), external_buffer[0]);
            testing.expectEqual(@as(u32, 0), external_buffer[i+1]);

            const sorted = [_]u32{
                // to preserve stability, the keys must be
                // unmodified at the beginning.
                1<<20, 1<<21, 1<<22, 1<<23,

                2, 4, 6, 8, 10, 12, 14, 16, // 0
                2, 4, 6, 8, 10, 12, 14, 16, // 8
                2, 4, 6, 8, 10, 12, 14, 16, // 16
                2, 4, 6, 8, 10, 12, 14, 16, // 24
                2, 4, 6, 8, 10, 12, 14, 16, // 32
                2, 3, 4, 5, 7, 8, 9, 10,    // 40
                3, 2, 5, 4, 7, 9, 8, 10,    // 48
                3, 2, 5, 4, 7, 6, 9, 8,     // 56
                2, 4, 5, 6, 7, 8, 10,       // 64
            };

            if (i >= 4) {
                // keys must be stable if we have an ideal buffer
                testing.expectEqualSlices(u32, &sorted, &buffer);
            } else {
                // otherwise we just need the data to be preserved,
                // order is not important.
                testing.expectEqual(sum(u32, sorted[0..4]), sum(u32, buffer[0..4]));
                testing.expectEqualSlices(u32, sorted[4..], buffer[4..]);
            }
        }
    }

    test "pairwiseSwaps" { test_pairwiseSwaps(); }
    fn test_pairwiseSwaps() void {
        var buffer = [_]u32{
            // two keys at the beginning
            1<<20, 1<<21,

            // odd number of keys
            2, 3, // stability 1
            3, 2, // stability 2
            2, 4, // in order
            4, 2, // out of order
            0, // last item
        };

        const key_sum = sum(u32, buffer[0..2]);

        pairwiseSwaps(u32, &buffer, asc_ignoreBottomBit);

        const sorted = [_]u32 {
            2, 3, // stability preserved
            3, 2, // stability preserved
            2, 4, // kept in order
            2, 4, // swapped into order
            0, // last item preserved
        };

        testing.expectEqualSlices(u32, &sorted, buffer[0..buffer.len-2]);
        testing.expectEqual(key_sum, sum(u32, buffer[buffer.len-2..]));
    }

    test "pairwiseWrites" { test_pairwiseWrites(); }
    fn test_pairwiseWrites() void {
        var buffer = [_]u32{
            // two keys at the beginning
            1<<20, 1<<21,

            // odd number of keys
            2, 3, // stability 1
            3, 2, // stability 2
            2, 4, // in order
            4, 2, // out of order
            0, // last item
        };

        const key_sum = sum(u32, buffer[0..2]);

        pairwiseWrites(u32, &buffer, asc_ignoreBottomBit);

        const sorted = [_]u32 {
            2, 3, // stability preserved
            3, 2, // stability preserved
            2, 4, // kept in order
            2, 4, // swapped into order
            0, // last item preserved
        };

        testing.expectEqualSlices(u32, &sorted, buffer[0..buffer.len-2]);
        // we don't care what's at the end of the array
    }

    test "combineBlocksInPlace" { test_combineBlocksInPlace(); }
    fn test_combineBlocksInPlace() void {
        // for this test, the block size is 4.
        // we will merge four subarrays of four blocks into two subarrays of eight blocks.
        // this is the initial state:
        var buffer = [73]u32{
            // canary 0
            0xdeadb0a7,
            // 8 keys for our max 8 blocks
            1<<20, 1<<21, 1<<22, 1<<23,
            1<<24, 1<<25, 1<<26, 1<<27,
            // canary 1
            0xdeadbeef,

            // one block of junk
            1<<12, 1<<13, 1<<14, 1<<15,

            // subarray 1
            // four blocks of left list, sorted
            2, 4, 6, 8,
            10, 10, 10, 10,
            10, 12, 12, 20,
            22, 30, 60, 100,
            // four blocks of right list, sorted
            3, 3, 7, 7,
            7, 9, 9, 11,
            11, 15, 19, 25,
            35, 37, 39, 41,

            // subarray 2, partial
            // four blocks of left list, sorted
            2, 4, 6, 8,
            10, 10, 10, 10,
            12, 12, 12, 20,
            22, 30, 60, 100,
            // two and a half blocks of right list, sorted
            1, 3, 3, 5,
            7, 7, 7, 7,
            11, 50,

            // end canary
            0xcafebabe,
        };

        // references to chunks of the buffer
        const canary0 = &buffer[0];
        const keys: []u32 = buffer[1..9];
        const canary1 = &buffer[9];
        const data: []u32 = buffer[10..72];
        const canary2 = &buffer[72];

        const key_sum = sum(u32, keys);
        const junk_sum = sum(u32, data[0..4]);

        // do the combine
        combineBlocks(u32, buffer[1..72], 13, 4 * 4, 4, .inline_buffer, emptySlice(u32), asc_ignoreBottomBit);

        const sorted_data = [_]u32{
            // subarray 0
            2, 3, 3, 4,
            6, 7, 7, 7,
            8, 9, 9, 10,
            10, 10, 10, 10,
            11, 11, 12, 12,
            15, 19, 20, 22,
            25, 30, 35, 37,
            39, 41, 60, 100,
            // subarray 1
            1, 2, 3, 3,
            4, 5, 6, 7,
            7, 7, 7, 8,
            10, 10, 10, 10,
            11, 12, 12, 12,
            20, 22, 30, 50,
            60, 100,
        };

        // the canaries should be untouched
        testing.expectEqual(@as(u32, 0xdeadb0a7), canary0.*);
        testing.expectEqual(@as(u32, 0xdeadbeef), canary1.*);
        testing.expectEqual(@as(u32, 0xcafebabe), canary2.*);

        // the keys must all exist but may be in any order
        testing.expectEqual(key_sum, sum(u32, keys));

        // the junk buffer should be before the data, but may be reordered.
        testing.expectEqual(junk_sum, sum(u32, data[0..4]));

        // the data should be sorted
        testing.expectEqualSlices(u32, &sorted_data, data[4..]);
    }

    test "combineBlocksInPlace_lazy" { test_combineBlocksInPlace_lazy(); }
    fn test_combineBlocksInPlace_lazy() void {
        // for this test, the block size is 4.
        // we will merge four subarrays of four blocks into two subarrays of eight blocks.
        // this is the initial state:
        var buffer = [69]u32{
            // canary 0
            0xdeadb0a7,
            // 8 keys for our max 8 blocks
            1<<20, 1<<21, 1<<22, 1<<23,
            1<<24, 1<<25, 1<<26, 1<<27,
            // canary 1
            0xdeadbeef,

            // subarray 1
            // four blocks of left list, sorted
            2, 4, 6, 8,
            10, 10, 10, 10,
            10, 12, 12, 20,
            22, 30, 60, 100,
            // four blocks of right list, sorted
            3, 3, 7, 7,
            7, 9, 9, 11,
            11, 15, 19, 25,
            35, 37, 39, 41,

            // subarray 2, partial
            // four blocks of left list, sorted
            2, 4, 6, 8,
            10, 10, 10, 10,
            12, 12, 12, 20,
            22, 30, 60, 100,
            // two and a half blocks of right list, sorted
            1, 3, 3, 5,
            7, 7, 7, 7,
            11, 50,

            // end canary
            0xcafebabe,
        };

        // references to chunks of the buffer
        const canary0 = &buffer[0];
        const keys: []u32 = buffer[1..9];
        const canary1 = &buffer[9];
        const data: []u32 = buffer[10..68];
        const canary2 = &buffer[68];

        const key_sum = sum(u32, keys);

        // do the combine
        combineBlocks(u32, buffer[1..68], 9, 4 * 4, 4, .no_buffer, emptySlice(u32), asc_ignoreBottomBit);

        const sorted_data = [_]u32{
            // subarray 0
            2, 3, 3, 4,
            6, 7, 7, 7,
            8, 9, 9, 10,
            10, 10, 10, 10,
            11, 11, 12, 12,
            15, 19, 20, 22,
            25, 30, 35, 37,
            39, 41, 60, 100,
            // subarray 1
            1, 2, 3, 3,
            4, 5, 6, 7,
            7, 7, 7, 8,
            10, 10, 10, 10,
            11, 12, 12, 12,
            20, 22, 30, 50,
            60, 100,
        };

        // the canaries should be untouched
        testing.expectEqual(@as(u32, 0xdeadb0a7), canary0.*);
        testing.expectEqual(@as(u32, 0xdeadbeef), canary1.*);
        testing.expectEqual(@as(u32, 0xcafebabe), canary2.*);

        // the keys must all exist but may be in any order
        testing.expectEqual(key_sum, sum(u32, keys));

        // the data should be sorted
        testing.expectEqualSlices(u32, &sorted_data, data);
    }

    test "mergeBlocks_noTrailer" { test_mergeBlocks_noTrailer(); }
    fn test_mergeBlocks_noTrailer() void {
        test_mergeBlocks_noTrailerMode(.inline_buffer);
    }

    test "mergeBlocks_withTrailer" { test_mergeBlocks_withTrailer(); }
    fn test_mergeBlocks_withTrailer() void {
        test_mergeBlocks_withTrailerMode(.inline_buffer);
    }

    test "mergeBlocks_noTrailerLazy" { test_mergeBlocks_noTrailerLazy(); }
    fn test_mergeBlocks_noTrailerLazy() void {
        test_mergeBlocks_noTrailerMode(.no_buffer);
    }

    test "mergeBlocks_withTrailerLazy" { test_mergeBlocks_withTrailerLazy(); }
    fn test_mergeBlocks_withTrailerLazy() void {
        test_mergeBlocks_withTrailerMode(.no_buffer);
    }

    test "mergeBlocks_noTrailerExternal" { test_mergeBlocks_noTrailerExternal(); }
    fn test_mergeBlocks_noTrailerExternal() void {
        test_mergeBlocks_noTrailerMode(.external_buffer);
    }

    test "mergeBlocks_withTrailerExternal" { test_mergeBlocks_withTrailerExternal(); }
    fn test_mergeBlocks_withTrailerExternal() void {
        test_mergeBlocks_withTrailerMode(.external_buffer);
    }

    fn test_mergeBlocks_noTrailerMode(comptime mode: BufferMode) void {
        // for this test, the block size is 4.
        // we have 8 blocks total from two lists of 4.
        // this is the initial state:
        var buffer = [47]u32{
            // canary 0
            0xdeadb0a7,
            // 8 keys for our 8 blocks
            1000, 1001, 1002, 1003,
            1004, 1005, 1006, 1007,
            // canary 1
            0xdeadbeef,
            // one block of junk
            1<<12, 1<<13, 1<<14, 1<<15,
            // four blocks of left list, sorted
            2, 4, 6, 8,
            10, 10, 10, 10,
            10, 12, 12, 20,
            22, 30, 60, 100,
            // four blocks of right list, sorted
            3, 3, 7, 7,
            7, 9, 9, 11,
            11, 15, 19, 25,
            35, 37, 39, 41,
            // end canary
            0xcafebabe,
        };

        const junk_sum = sum(u32, buffer[10..14]);

        // references to chunks of the buffer
        const canary0 = &buffer[0];
        const keys: []u32 = buffer[1..9];
        const canary1 = &buffer[9];
        const data: []u32 = buffer[10..46];
        const canary2 = &buffer[46];

        // First, selection sort the blocks (not including the junk buffer)
        const median_key = blockSelectSort(u32, keys.ptr, data.ptr + 4, 4, 8, 4, asc_ignoreBottomBit);

        // Now the buffer should look like this:
        const selected_buffer = [47]u32{
            // canary 0
            0xdeadb0a7,
            // 8 keys, permuted in the same way as the blocks
            1000, 1004, 1005, 1001,
            1002, 1006, 1003, 1007,
            // canary 1
            0xdeadbeef,
            // one block of junk
            1<<12, 1<<13, 1<<14, 1<<15,
            // eight blocks from the two lists, sorted by starting value
            2, 4, 6, 8,
            3, 3, 7, 7,
            7, 9, 9, 11,
            10, 10, 10, 10,
            10, 12, 12, 20,
            11, 15, 19, 25,
            22, 30, 60, 100,
            35, 37, 39, 41,
            // end canary
            0xcafebabe,
        };
        testing.expectEqualSlices(u32, &selected_buffer, &buffer);
        // The median key has moved to index 1.
        testing.expectEqual(@as(usize, 1), median_key);

        // merge the blocks together
        mergeBlocks(u32, keys.ptr, median_key, data.ptr + 4, 8, 4, 0, 0, mode, asc_ignoreBottomBit);

        const sorted_data = [32]u32{
            2, 3, 3, 4,
            6, 7, 7, 7,
            8, 9, 9, 10,
            10, 10, 10, 10,
            11, 11, 12, 12,
            15, 19, 20, 22,
            25, 30, 35, 37,
            39, 41, 60, 100,
        };

        // the canaries and keys should be untouched
        testing.expectEqual(@as(u32, 0xdeadb0a7), canary0.*);
        testing.expectEqual(@as(u32, 0xdeadbeef), canary1.*);
        testing.expectEqual(@as(u32, 0xcafebabe), canary2.*);
        testing.expectEqualSlices(u32, selected_buffer[1..9], keys);

        switch (mode) {
            .no_buffer => {
                // the junk should be untouched
                testing.expectEqualSlices(u32, &[_]u32{ 1<<12, 1<<13, 1<<14, 1<<15 }, data[0..4]);
                // the data should be sorted at the end
                testing.expectEqualSlices(u32, &sorted_data, data[4..36]);
            },
            .inline_buffer => {
                // the data should be sorted at the beginning
                testing.expectEqualSlices(u32, &sorted_data, data[0..32]);
                // the junk buffer should be after the data, but may be reordered.
                testing.expectEqual(junk_sum, sum(u32, data[32..]));
            },
            .external_buffer => {
                // the data should be sorted at the beginning
                testing.expectEqualSlices(u32, &sorted_data, data[0..32]);
                // we don't care about the contents of the junk buffer
            }
        }
    }

    fn test_mergeBlocks_withTrailerMode(comptime mode: BufferMode) void {
        // for this test, the block size is 4.
        // we have 6 and a half blocks total, 
        // this is the initial state:
        var buffer = [39]u32{
            // canary 0
            0xdeadb0a7,
            // 6 keys for our 6 blocks
            1000, 1001, 1002, 1003,
            1004, 1005,
            // canary 1
            0xdeadbeef,
            // one block of junk
            1<<12, 1<<13, 1<<14, 1<<15,
            // four blocks of left list, sorted
            2, 4, 6, 8,
            10, 10, 10, 10,
            12, 12, 12, 20,
            22, 30, 60, 100,
            // two and a half blocks of right list, sorted
            1, 3, 3, 5,
            7, 7, 7, 7,
            11, 50,
            // end canary
            0xcafebabe,
        };

        const junk_sum = sum(u32, buffer[8..12]);

        // references to chunks of the buffer
        const canary0 = &buffer[0];
        const keys: []u32 = buffer[1..7];
        const canary1 = &buffer[7];
        const data: []u32 = buffer[8..38];
        const canary2 = &buffer[38];

        // First, selection sort the blocks (not including the junk buffer)
        const median_key = blockSelectSort(u32, keys.ptr, data.ptr + 4, 4, 6, 4, asc_ignoreBottomBit);

        // Now this is the buffer:
        const selected_buffer = [_]u32{
            // canary 0
            0xdeadb0a7,
            // 6 keys for our 6 blocks, permuted
            1004, 1000, 1005, 1001, 1002, 1003,
            // canary 1
            0xdeadbeef,
            // one block of junk
            1<<12, 1<<13, 1<<14, 1<<15,
            // all six blocks, sorted by first value
            1, 3, 3, 5,
            2, 4, 6, 8,
            7, 7, 7, 7,
            10, 10, 10, 10,
            12, 12, 12, 20, // these two are unfit to participate in the normal sort
            22, 30, 60, 100,
            // trailers, not sorted
            11, 50,
            // end canary
            0xcafebabe,
        };

        testing.expectEqualSlices(u32, &selected_buffer, &buffer);
        // 1004 is now in index 0
        testing.expectEqual(@as(usize, 0), median_key);

        const unfit_blocks = countLastMergeBlocks(u32, data[4..], 6, 4, asc_ignoreBottomBit);
        testing.expectEqual(@as(usize, 2), unfit_blocks);

        // merge the blocks together
        const trailer_len = unfit_blocks * 4 + 2;
        mergeBlocks(u32, keys.ptr, median_key, data.ptr + 4, 6 - unfit_blocks, 4, unfit_blocks, trailer_len, mode, asc_ignoreBottomBit);

        const sorted_data = [_]u32{
            1, 2, 3, 3,
            4, 5, 6, 7,
            7, 7, 7, 8,
            10, 10, 10, 10,
            11, 12, 12, 12,
            20, 22, 30, 50,
            60, 100,
        };

        // the canaries and keys should be untouched
        testing.expectEqual(@as(u32, 0xdeadb0a7), canary0.*);
        testing.expectEqual(@as(u32, 0xdeadbeef), canary1.*);
        testing.expectEqual(@as(u32, 0xcafebabe), canary2.*);
        testing.expectEqualSlices(u32, selected_buffer[1..7], keys);

        switch (mode) {
            .no_buffer => {
                // the junk should be untouched
                testing.expectEqualSlices(u32, &[_]u32{ 1<<12, 1<<13, 1<<14, 1<<15 }, data[0..4]);
                // the data should be sorted at the end
                testing.expectEqualSlices(u32, &sorted_data, data[4..30]);
            },
            .inline_buffer => {
                // the data should be sorted at the beginning
                testing.expectEqualSlices(u32, &sorted_data, data[0..26]);
                // the junk buffer should be after the data, but may be reordered.
                testing.expectEqual(junk_sum, sum(u32, data[26..]));
            },
            .external_buffer => {
                // the data should be sorted at the beginning
                testing.expectEqualSlices(u32, &sorted_data, data[0..26]);
                // we don't care about the contents of the junk buffer
            }
        }
    }

    test "mergeForwards" { test_mergeForwards(); }
    fn test_mergeForwards() void {
        var buffer = [18]u32 {
            // start canary
            0xdeadbeef,
            // 5 item junk buffer
            1<<10, 1<<11, 1<<12, 1<<13, 1<<14,
            // 6 items in left list
            2, 4, 4, 6, 32, 32,
            // 5 items in right list
            3, 5, 9, 11, 15,
            // end canary
            0xcafebabe,
        };

        const junk_total = sum(u32, buffer[1..6]);
        mergeForwards(u32, buffer[6..17], 5, 6, 5, asc_ignoreBottomBit);

        testing.expectEqual(@as(u32, 0xdeadbeef), buffer[0]);
        testing.expectEqualSlices(u32, &[_]u32{ 2, 3, 4, 4, 5, 6, 9, 11, 15, 32, 32 }, buffer[1..12]);
        testing.expectEqual(junk_total, sum(u32, buffer[12..17]));
        testing.expectEqual(@as(u32, 0xcafebabe), buffer[17]);
    }

    test "mergeBackwards" { test_mergeBackwards(); }
    fn test_mergeBackwards() void {
        var buffer = [18]u32 {
            // start canary
            0xdeadbeef,
            // 5 items in left list
            3, 5, 9, 11, 15,
            // 6 items in right list
            2, 4, 4, 6, 32, 32,
            // 5 item junk buffer
            1<<10, 1<<11, 1<<12, 1<<13, 1<<14,
            // end canary
            0xcafebabe,
        };

        const junk_total = sum(u32, buffer[12..17]);
        mergeBackwards(u32, buffer[1..17], 5, 6, 5, asc_ignoreBottomBit);

        testing.expectEqual(@as(u32, 0xdeadbeef), buffer[0]);
        testing.expectEqual(junk_total, sum(u32, buffer[1..6]));
        testing.expectEqualSlices(u32, &[_]u32{ 3, 2, 5, 4, 4, 6, 9, 11, 15, 32, 32 }, buffer[6..17]);
        testing.expectEqual(@as(u32, 0xcafebabe), buffer[17]);
    }

    test "mergeForwardExternal" { test_mergeForwardExternal(); }
    fn test_mergeForwardExternal() void {
        var buffer = [18]u32 {
            // start canary
            0xdeadbeef,
            // 5 item junk buffer
            1<<10, 1<<11, 1<<12, 1<<13, 1<<14,
            // 6 items in left list
            2, 4, 4, 6, 32, 32,
            // 5 items in right list
            3, 5, 9, 11, 15,
            // end canary
            0xcafebabe,
        };

        mergeForwards(u32, buffer[6..17], 5, 6, 5, asc_ignoreBottomBit);

        testing.expectEqual(@as(u32, 0xdeadbeef), buffer[0]);
        testing.expectEqualSlices(u32, &[_]u32{ 2, 3, 4, 4, 5, 6, 9, 11, 15, 32, 32 }, buffer[1..12]);
        // we don't care what's in the new junk buffer
        testing.expectEqual(@as(u32, 0xcafebabe), buffer[17]);
    }

    test "lazyStableSort" { test_lazyStableSort(); }
    fn test_lazyStableSort() void {
        var array = [_]u32{
            17, 30,  8, 14, 11,  3, 12, 24,
            33,  2,  1, 36, 37, 23,  6, 38,
             5, 13, 26, 16, 31, 15,  0, 20,
            35, 19, 18, 28, 34, 32, 25,  7,
            21,  9, 29,  4, 10, 27, 40, 39,
            22,  
        };

        lazyStableSort(u32, &array, asc_ignoreBottomBit);

        const sorted = [_]u32{
             1,  0,  3,  2,  5,  4,  6,  7,
             8,  9, 11, 10, 12, 13, 14, 15,
            17, 16, 19, 18, 20, 21, 23, 22,
            24, 25, 26, 27, 28, 29, 30, 31,
            33, 32, 35, 34, 36, 37, 38, 39,
            40,
        };

        testing.expectEqualSlices(u32, &sorted, &array);
    }

    test "lazyMerge" { test_lazyMerge(); }
    fn test_lazyMerge() void {
        // lazyMerge has separate implementations depending on
        // which half is smaller, make sure we test both.
        var left_smaller = [_]u32{
            2, 8, 8, 16,
            5, 7, 9, 11, 13, 15,
        };
        lazyMerge(u32, &left_smaller, 4, asc_ignoreBottomBit);
        testing.expectEqualSlices(u32, &[_]u32{ 2, 5, 7, 8, 8, 9, 11, 13, 15, 16 }, &left_smaller);

        var right_smaller = [_]u32{
            5, 7, 9, 11, 13, 15,
            2, 8, 8, 16,
        };
        lazyMerge(u32, &right_smaller, 6, asc_ignoreBottomBit);
        testing.expectEqualSlices(u32, &[_]u32{ 2, 5, 7, 9, 8, 8, 11, 13, 15, 16 }, &right_smaller);
    }

    test "insertSort" { test_insertSort(); }
    fn test_insertSort() void {
        var test_1 = [_]u32{ 8, 7, 6, 4, 2, 3, 1 };
        insertSort(u32, &test_1, asc_ignoreBottomBit);
        testing.expectEqualSlices(u32, &[_]u32{ 1, 2, 3, 4, 7, 6, 8 }, &test_1);

        // just make sure this doesn't crash
        insertSort(u32, emptySlice(u32), asc_ignoreBottomBit);
    }

    test "binarySearchLeft" { test_binarySearchLeft(); }
    fn test_binarySearchLeft() void {
        const sorted = [_]u32{ 2, 3, 4, 5, 4, 6, 11 };
        testing.expectEqual(@as(usize, 0), binarySearchLeft(u32, &sorted, 0, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 0), binarySearchLeft(u32, &sorted, 1, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 0), binarySearchLeft(u32, &sorted, 2, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 0), binarySearchLeft(u32, &sorted, 3, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 2), binarySearchLeft(u32, &sorted, 4, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 2), binarySearchLeft(u32, &sorted, 5, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 5), binarySearchLeft(u32, &sorted, 6, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 5), binarySearchLeft(u32, &sorted, 7, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 6), binarySearchLeft(u32, &sorted, 8, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 6), binarySearchLeft(u32, &sorted, 9, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 6), binarySearchLeft(u32, &sorted, 10, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 6), binarySearchLeft(u32, &sorted, 11, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 7), binarySearchLeft(u32, &sorted, 12, asc_ignoreBottomBit));
        testing.expectEqual(@as(usize, 7), binarySearchLeft(u32, &sorted, 200, asc_ignoreBottomBit));

        testing.expectEqual(@as(usize, 0), binarySearchLeft(u32, emptySlice(u32), 200, asc_ignoreBottomBit));
    }

    test "moveFrontToBack" { test_moveFrontToBack(); }
    fn test_moveFrontToBack() void {
        // use unique bits so we can sum the items to find if they exist.
        const init_array = [_]u32{ 1, 2, 4, 8, 16, 32, 64, 128, 256 };

        // test with buffer smaller than half
        var array = init_array;
        moveFrontToBack(u32, array[1..8], 3);
        testing.expectEqual(@as(u32, 1), array[0]);
        // we don't care about the order of these items but they all need to be there.
        testing.expectEqual(sum(u32, init_array[4..8]), sum(u32, array[1..5]));
        testing.expectEqualSlices(u32, &[_]u32{ 2, 4, 8, 256 }, array[5..]);

        // test with buffer larger than half
        array = init_array;
        moveFrontToBack(u32, array[1..8], 5);
        testing.expectEqual(@as(u32, 1), array[0]);
        // we don't care about the order of these items but they all need to be there.
        testing.expectEqual(sum(u32, init_array[6..8]), sum(u32, array[1..3]));
        testing.expectEqualSlices(u32, &[_]u32{ 2, 4, 8, 16, 32, 256 }, array[3..]);

        // test with buffer length zero
        array = init_array;
        moveFrontToBack(u32, array[1..8], 0);
        testing.expectEqualSlices(u32, &init_array, &array);

        // test with full length buffer
        array = init_array;
        moveFrontToBack(u32, array[1..8], 7);
        testing.expectEqualSlices(u32, &init_array, &array);

        // test with empty slice
        moveFrontToBack(u32, emptySlice(u32), 0);
    }

    test "moveBackToFront" { test_moveBackToFront(); }
    fn test_moveBackToFront() void {
        const init_array = [_]u32{ 1, 2, 4, 8, 16, 32, 64, 128, 256 };

        // test with buffer smaller than half
        var array = init_array;
        moveBackToFront(u32, array[1..8], 3);
        testing.expectEqualSlices(u32, &[_]u32{ 1, 32, 64, 128 }, array[0..4]);
        // we don't care about the order of these items but they all need to be there.
        testing.expectEqual(sum(u32, init_array[1..5]), sum(u32, array[4..8]));
        testing.expectEqual(@as(u32, 256), array[8]);

        // test with buffer larger than half
        array = init_array;
        moveBackToFront(u32, array[1..8], 5);
        testing.expectEqualSlices(u32, &[_]u32{ 1, 8, 16, 32, 64, 128 }, array[0..6]);
        // we don't care about the order of these items but they all need to be there.
        testing.expectEqual(sum(u32, init_array[1..3]), sum(u32, array[6..8]));
        testing.expectEqual(@as(u32, 256), array[8]);

        // test with buffer length zero
        array = init_array;
        moveBackToFront(u32, array[1..8], 0);
        testing.expectEqualSlices(u32, &init_array, &array);

        // test with full length buffer
        array = init_array;
        moveBackToFront(u32, array[1..8], 7);
        testing.expectEqualSlices(u32, &init_array, &array);

        // test with empty slice
        moveBackToFront(u32, emptySlice(u32), 0);
    }

    test "rotate" { test_rotate(); }
    fn test_rotate() void {
        var array = [_]u32{ 0, 1, 2, 3, 4, 5, 6, 7, 8 };
        rotate(u32, array[1..8], 3);
        testing.expectEqualSlices(u32, &[_]u32{ 0, 4, 5, 6, 7, 1, 2, 3, 8 }, &array);
    }

    test "blockSwap" { test_blockSwap(); }
    fn test_blockSwap() void {
        var array = [_]u32{ 0, 1, 2, 3, 4, 5, 6, 7, 8 };
        blockSwap(u32, @as([*]u32, &array) + 1, @as([*]u32, &array) + 5, 3);
        testing.expectEqualSlices(u32, &[_]u32{ 0, 5, 6, 7, 4, 1, 2, 3, 8 }, &array);
    }

    test "copyNoAlias" { test_copyNoAlias(); }
    fn test_copyNoAlias() void {
        var array = [_]u32{ 0, 1, 2, 3, 4, 5, 6, 7, 8 };
        copyNoAlias(u32, @as([*]u32, &array) + 1, @as([*]u32, &array) + 5, 3);
        testing.expectEqualSlices(u32, &[_]u32{ 0, 5, 6, 7, 4, 5, 6, 7, 8 }, &array);
    }

    test "emptySlice" { test_emptySlice(); }
    fn test_emptySlice() void {
        test_emptySliceType(u32);
        test_emptySliceType(struct{x: u32, y: f32});
        test_emptySliceType(void);
    }

    fn test_emptySliceType(comptime T: type) void {
        const a = emptySlice(T);
        testing.expectEqual([]T, @TypeOf(a));
        testing.expectEqual(@as(usize, 0), a.len);
        // TODO-ZIG: The compiler currently doesn't do this properly.
        //testing.expect(@ptrToInt(a.ptr) != 0);
    }

    fn sum(comptime T: type, slice: []const T) T {
        var total: T = 0;
        for (slice) |item| total += item;
        return total;
    }

    // A comparison function for sorting in ascending order,
    // ignoring the bottom bit of both operands.  The bottom
    // bit can be used to check stability.
    fn asc_ignoreBottomBitFn(ctx: void, a: u32, b: u32) bool {
        return (a >> 1) < (b >> 1);
    }

    const asc_ignoreBottomBit = struct {
        //! This struct just cleans up the parameter lists of inner functions.
        context: void,

        pub inline fn lessThan(self: @This(), lhs: u32, rhs: u32) bool {
            // TODO-API: do some tests to see if a compare function
            // can actually be performant here
            return asc_ignoreBottomBitFn(self.context, lhs, rhs);
        }

        pub inline fn compare(self: @This(), lhs: u32, rhs: u32) std.math.Order {
            // TODO-OPT: use an actual compare function here
            if (asc_ignoreBottomBitFn(self.context, lhs, rhs)) return .lt;
            if (asc_ignoreBottomBitFn(self.context, rhs, lhs)) return .gt;
            return .eq;
        }
    } { .context = {} };
};
