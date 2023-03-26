/*
 * MIT License
 * 
 * Copyright (c) 2013 Andrey Astrelin
 * Copyright (c) 2020 The Holy Grail Sort Project
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
 * The Holy Grail Sort Project
 * Project Manager:      Summer Dragonfly
 * Project Contributors: 666666t
 *                       Anonymous0726
 *                       aphitorite
 *                       Control
 *                       dani_dlg
 *                       DeveloperSort
 *                       EilrahcF
 *                       Enver
 *                       Gaming32
 *                       lovebuny
 *                       Morwenn
 *                       MP
 *                       phoenixbound
 *                       Spex_guy
 *                       thatsOven
 *                       _fluffyy
 *
 * Special thanks to "The Studio" Discord community!
 */

// REWRITTEN GRAILSORT FOR V - A heavily refactored C/C++-to-V version of
//                             Andrey Astrelin's GrailSort.h, aiming to be as
//                             readable and intuitive as possible.
//
// ** Written and maintained by The Holy Grail Sort Project
//
// Primary author: thatsOven
//
// Current status: Working (Passing all tests so far, more testing will be performed)

module grailsort

[inline]
[direct_array_access]
fn arraycopy[T](from_array []T, from_idx int, mut to_array []T, to_idx int, len int) {
    for i in 0 .. len {
        to_array[to_idx + i] = from_array[from_idx + i]
    }
}

[inline]
fn compare[T](a T, b T) i8 {
    return i8(a > b) - i8(a < b)
}

const (
    static_ext_buf_len = 512
)

enum Subarray {
    left
    right
}

struct GrailSort[T] {
    mut:
    oop         bool
    ext_buf     []T
    ext_buf_len int
    curr_blen   int
    curr_borig  Subarray
}

[inline]
[direct_array_access]
fn swap[T](mut array []T, a int, b int) {
    tmp     := array[a]
    array[a] = array[b]
    array[b] = tmp
}

[inline]
[direct_array_access]
fn block_swap[T](mut array []T, a int, b int, len int) {
    for i in 0 .. len {
        swap(mut array, a + i, b + i)
    }
}

[inline]
[direct_array_access]
fn rotate[T](mut array []T, s int, lls int, rls int) {
    mut a  := s
    mut ll := lls
    mut rl := rls

    for ll > 0 && rl > 0 {
        if ll <= rl {
            block_swap(mut array, a, a + ll, ll)
            a  += ll
            rl -= ll
        } else {
            block_swap(mut array, a + ll - rl, a + ll, rl)
            ll -= rl
        }
    }
}

fn insert_sort[T](mut array []T, a int, len int) {
    for i in 1 .. len {
        mut l := a + i - 1
        mut r := a + i

        for l >= a && array[l] > array[r] {
            swap(mut array, l, r)
            l--
            r--
        }
    }
}

[direct_array_access]
fn binsearch_left[T](array []T, a int, len int, target T) int {
    mut l := 0
    mut r := len

    for l < r {
        m := l + ((r - l) / 2)

        if array[a + m] < target {
            l = m + 1
        } else {
            r = m
        }
    }

    return l
}

[direct_array_access]
fn binsearch_right[T](array []T, a int, len int, target T) int {
    mut l := 0
    mut r := len

    for l < r {
        m := l + ((r - l) / 2)

        if array[a + m] > target {
            r = m
        } else {
            l = m + 1
        }
    }

    return r
}

fn collect_keys[T](mut array []T, a int, len int, ideal int) int {
    mut found := 1
    mut first := 0
    mut curr  := 1

    for curr < len && found < ideal {
        pos := binsearch_left(array, a + first, found, array[a + curr])

        if pos == found || array[a + curr] != array[a + first + pos] {
            rotate(mut array, a + first, found, curr - (first + found))
            first = curr - found
            rotate(mut array, a + first + pos, found - pos, 1)
            found++
        }

        curr++
    }

    rotate(mut array, a, first, found)
    return found
}

[direct_array_access]
fn pairwise_swaps[T](mut array []T, a int, len int) {
    mut l := 0
    mut i := 1
    for ; i < len; i += 2 {
        l  = a + i - 1
        r := a + i

        if array[l] > array[r] {
            swap(mut array, l - 2, r)
            swap(mut array, r - 2, l)
        } else {
            swap(mut array, l - 2, l)
            swap(mut array, r - 2, r)
        }
    }

    l = a + i - 1
    if l < a + len {
        swap(mut array, l - 2, l)
    }
}

[direct_array_access]
fn pairwise_writes[T](mut array []T, a int, len int) {
    mut l := 0
    mut i := 1
    for ; i < len; i += 2 {
        l  = a + i - 1
        r := a + i

        if array[l] > array[r] {
            array[l - 2] = array[r]
            array[r - 2] = array[l]
        } else {
            array[l - 2] = array[l]
            array[r - 2] = array[r]
        }
    }

    l = a + i - 1
    if l < a + len {
        array[l - 2] = array[l]
    }
}

[direct_array_access]
fn merge_forwards[T](mut array []T, a int, ll int, rl int, offs int) {
    mut buf := a - offs
    mut l   := a
    m       := a + ll
    mut r   := m
    end     := m + rl

    for r < end {
        if l == m || array[l] > array[r] {
            swap(mut array, buf, r)
            r++
        } else {
            swap(mut array, buf, l)
            l++
        }
        buf++
    }

    if buf != l {
        block_swap(mut array, buf, l, m - l)
    }
}

[direct_array_access]
fn merge_backwards[T](mut array []T, a int, ll int, rl int, offs int) {
    end     := a - 1
    mut l   := end + ll
    m       := l
    mut r   := m + rl
    mut buf := r + offs

    for l > end {
        if r == m || array[l] > array[r] {
            swap(mut array, buf, l)
            l--
        } else {
            swap(mut array, buf, r)
            r--
        }
        buf--
    }

    if r != buf {
        for r > m {
            swap(mut array, buf, r)
            buf--
            r--
        }
    }
}

[direct_array_access]
fn merge_lazy[T](mut array []T, s int, lls int, rls int) {
    mut a  := s
    mut ll := lls
    mut rl := rls

    if ll < rl {
        mut m := a + ll

        for ll != 0 {
            m_len := binsearch_left(array, m, rl, array[a])

            if m_len != 0 {
                rotate(mut array, a, ll, m_len)

                a  += m_len
                m  += m_len
                rl -= m_len
            }

            if rl == 0 {
                break
            } else {
                for {
                    a++
                    ll--

                    if ll == 0 || array[a] > array[m] {
                        break
                    }
                }
            }
        }
    } else {
        mut end := a + ll + rl - 1

        for rl != 0 {
            m_len := binsearch_right(array, a, ll, array[end])

            if m_len != ll {
                rotate(mut array, a + m_len, ll - m_len, rl)

                end -= ll - m_len
                ll = m_len
            }

            if ll == 0 {
                break
            } else {
                m := a + ll
                for {
                    rl--
                    end--

                    if rl == 0 || array[m - 1] > array[end] {
                        break
                    }
                }
            }
        }
    }
}

[direct_array_access]
fn merge_oop[T](mut array []T, a int, ll int, rl int, offs int) {
    mut buf := a - offs
    mut l   := a
    m       := a + ll
    mut r   := m
    end     := m + rl

    for r < end {
        if l == m || array[l] > array[r] {
            array[buf] = array[r]
            r++
        } else {
            array[buf] = array[l]
            l++
        }
        buf++
    }

    if buf != l {
        for l < m {
            array[buf] = array[l]
            buf++
            l++
        }
    }
}

[direct_array_access]
fn build_inplace[T](mut array []T, s int, len int, curr_len int, buf_len int) {
    mut a := s
    
    mut full_merge := 0
    mut m_idx      := 0
    for m_len := curr_len; m_len < buf_len; m_len *= 2 {
        full_merge = 2 * m_len
        m_end     := a + len - full_merge
        offs      := m_len
        m_idx      = a

        for ; m_idx <= m_end; m_idx += full_merge {
            merge_forwards(mut array, m_idx, m_len, m_len, offs)
        } 

        leftover := len - (m_idx - a)

        if leftover > m_len {
            merge_forwards(mut array, m_idx, m_len, leftover - m_len, offs)
        } else {
            rotate(mut array, m_idx - m_len, m_len, leftover)
        }

        a -= m_len
    }

    full_merge  = 2 * buf_len
    last_block := len % full_merge
    last_offs  := a + len - last_block

    if last_block <= buf_len {
        rotate(mut array, last_offs, last_block, buf_len)
    } else {
        merge_backwards(mut array, last_offs, buf_len, last_block - buf_len, buf_len)
    }

    for m_idx = last_offs - full_merge; m_idx >= a; m_idx -= full_merge {
        merge_backwards(mut array, m_idx, buf_len, buf_len, buf_len)
    }
}

[direct_array_access]
fn (mut this GrailSort[T]) build_oop[T](mut array []T, s int, len int, buf_len int, ext_len int) {
    mut a := s
    
    arraycopy(array, a - ext_len, mut this.ext_buf, 0, ext_len)

    pairwise_writes(mut array, a, len)
    a -= 2

    mut m_len := 2
    for ; m_len < ext_len; m_len *= 2 {
        full_merge := 2 * m_len
        m_end      := a + len - full_merge
        offs       := m_len
        mut m_idx  := a

        for ; m_idx <= m_end; m_idx += full_merge {
            merge_oop(mut array, m_idx, m_len, m_len, offs)
        }

        leftover := len - (m_idx - a)

        if leftover > m_len {
            merge_oop(mut array, m_idx, m_len, leftover - m_len, offs)
        } else {
            arraycopy(array, m_idx, mut array, m_idx - m_len, leftover)
        }

        a -= m_len
    }

    arraycopy(this.ext_buf, 0, mut array, a + len, ext_len)
    build_inplace(mut array, a, len, m_len, buf_len)
}

fn (mut this GrailSort[T]) build_blocks[T](mut array []T, a int, len int, buf_len int) {
    mut ext_len := 1

    if this.oop {
        if buf_len < this.ext_buf_len {
            ext_len = buf_len
        } else {
            for ext_len * 2 <= this.ext_buf_len {
                ext_len *= 2
            }
        }

        this.build_oop(mut array, a, len, buf_len, ext_len)
    } else {
        pairwise_swaps(mut array, a, len)
        build_inplace(mut array, a - 2, len, 2, buf_len)
    }
}

[direct_array_access]
fn block_select_sort[T](mut array []T, first_k int, a int, m_key_s int, block_cnt int, block_len int) int {
    mut m_key := m_key_s
    
    for first_block in 0 .. block_cnt {
        mut select_block := first_block

        for curr_block in first_block + 1 .. block_cnt {
            cmp := compare(
                array[a + (  curr_block * block_len)],
                array[a + (select_block * block_len)]
            )

            if cmp < 0 || (cmp == 0 && array[first_k + curr_block] < array[first_k + select_block]) {
                select_block = curr_block
            }
        }

        if select_block != first_block {
            block_swap(
                mut array, 
                a + ( first_block * block_len), 
                a + (select_block * block_len),
                block_len
            )

            swap(mut array, first_k + first_block, first_k + select_block)

            if m_key == first_block {
                m_key = select_block
            } else if m_key == select_block {
                m_key = first_block
            }
        }
    }

    return m_key
}

[inline]
[direct_array_access]
fn buf_reset_inplace[T](mut array []T, a int, len int, offs int) {
    mut buf := a + len - 1
    mut idx := buf - offs

    for buf >= a {
        swap(mut array, idx, buf)
        buf--
        idx--
    }
}

[inline]
[direct_array_access]
fn buf_reset_oop[T](mut array []T, a int, len int, offs int) {
    mut buf := a + len - 1
    mut idx := buf - offs

    for buf >= a {
        array[buf] = array[idx]
        buf--
        idx--
    }
}

[inline]
[direct_array_access]
fn buf_rewind_inplace[T](mut array []T, a int, lb int, b int) {
    mut left_block := lb
    mut buf        := b
    
    for left_block >= a {
        swap(mut array, buf, left_block)
        left_block--
        buf--
    }
}

[inline]
[direct_array_access]
fn buf_rewind_oop[T](mut array []T, a int, lb int, b int) {
    mut left_block := lb
    mut buf        := b

    for left_block >= a {
        array[buf] = array[left_block]
        left_block--
        buf--
    }
}

[inline]
[direct_array_access]
fn get_subarray[T](array []T, curr_key int, m_key int) Subarray {
    if array[curr_key] < array[m_key] {
        return Subarray.left
    } 

    return Subarray.right
}

[inline]
[direct_array_access]
fn count_last_merge_blocks[T](array []T, offs int, block_cnt int, block_len int) int {
    last_r_frag      := offs + (block_cnt * block_len)
    mut prev_l_block := last_r_frag - block_len

    mut to_merge := 0
    for to_merge < block_cnt && array[last_r_frag] < array[prev_l_block] {
        to_merge++
        prev_l_block -= block_len
    }

    return to_merge
}

[direct_array_access]
fn (mut this GrailSort[T]) smart_merge[T](mut array []T, a int, ll int, l_orig Subarray, rl int, offs int) {
    mut buf := a - offs
    mut l   := a
    m       := a + ll
    mut r   := m
    end     := m + rl

    if l_orig == Subarray.left {
        for l < m && r < end {
            if array[l] <= array[r] {
                swap(mut array, buf, l)
                l++
            } else {
                swap(mut array, buf, r)
                r++
            }
            buf++
        }
    } else {
        for l < m && r < end {
            if array[l] < array[r] {
                swap(mut array, buf, l)
                l++
            } else {
                swap(mut array, buf, r)
                r++
            }
            buf++
        }
    }

    if l < m {
        this.curr_blen = m - l
        buf_rewind_inplace(mut array, l, m - 1, end - 1)
    } else {
        this.curr_blen = end - r

        if l_orig == Subarray.left {
            this.curr_borig = Subarray.right
        } else {
            this.curr_borig = Subarray.left
        }
    }
}

[direct_array_access]
fn (mut this GrailSort[T]) smart_merge_lazy[T](mut array []T, s int, lls int, l_orig Subarray, rls int) {
    mut a  := s
    mut rl := rls
    mut ll := lls

    mut m := a + ll

    if l_orig == Subarray.left {
        if array[m - 1] > array[m] {
            for ll != 0 {
                m_len := binsearch_left(array, m, rl, array[a])

                if m_len != 0 {
                    rotate(mut array, a, ll, m_len)

                    a  += m_len
                    m  += m_len
                    rl -= m_len
                }

                if rl == 0 {
                    this.curr_blen = ll
                    return
                } else {
                    for {
                        a++
                        ll--

                        if ll == 0 || array[a] > array[m] {
                            break
                        }
                    }
                }
            }
        }
    } else {
        if array[m - 1] >= array[m] {
            for ll != 0 {
                m_len := binsearch_right(array, m, rl, array[a])

                if m_len != 0 {
                    rotate(mut array, a, ll, m_len)

                    a  += m_len
                    m  += m_len
                    rl -= m_len
                }

                if rl == 0 {
                    this.curr_blen = ll
                    return
                } else {
                    for {
                        a++
                        ll--

                        if ll == 0 || array[a] >= array[m] {
                            break
                        }
                    }
                }
            }
        }
    }

    this.curr_blen = rl
    if l_orig == Subarray.left {
        this.curr_borig = Subarray.right
    } else {
        this.curr_borig = Subarray.left
    }
}

[direct_array_access]
fn (mut this GrailSort[T]) smart_merge_oop[T](mut array []T, a int, ll int, l_orig Subarray, rl int, offs int) {
    mut buf := a - offs
    mut l   := a
    m       := a + ll
    mut r   := m
    end     := m + rl

    if l_orig == Subarray.left {
        for l < m && r < end {
            if array[l] <= array[r] {
                array[buf] = array[l]
                l++
            } else {
                array[buf] = array[r]
                r++
            }
            buf++
        }
    } else {
        for l < m && r < end {
            if array[l] < array[r] {
                array[buf] = array[l]
                l++
            } else {
                array[buf] = array[r]
                r++
            }
            buf++
        }
    }

    if l < m {
        this.curr_blen = m - l
        buf_rewind_oop(mut array, l, m - 1, end - 1)
    } else {
        this.curr_blen = end - r
        if l_orig == Subarray.left {
            this.curr_borig = Subarray.right
        } else {
            this.curr_borig = Subarray.left
        }
    }
}

[direct_array_access]
fn (mut this GrailSort[T]) merge_blocks[T](mut array []T, first_k int, m_key int, a int, block_cnt int, block_len int, last_merge_blocks int, last_len int) {
    mut buf        := 0
    mut curr_block := 0
    mut next_block := a + block_len

    this.curr_blen  = block_len
    this.curr_borig = get_subarray(array, first_k, m_key)

    for k_idx in 1 .. block_cnt {
        curr_block  = next_block - this.curr_blen
        next_borig := get_subarray(array, first_k + k_idx, m_key)

        if next_borig == this.curr_borig {
            buf = curr_block - block_len
            block_swap(mut array, buf, curr_block, this.curr_blen)
            this.curr_blen = block_len
        } else {
            this.smart_merge(
                mut array, curr_block, this.curr_blen, 
                this.curr_borig, block_len, block_len
            )
        }

        next_block += block_len
    }

    curr_block = next_block - this.curr_blen
    buf        = curr_block - block_len

    if last_len != 0 {
        if this.curr_borig == Subarray.right {
            block_swap(mut array, buf, curr_block, this.curr_blen)

            curr_block      = next_block
            this.curr_blen  = block_len * last_merge_blocks
            this.curr_borig = Subarray.left
        } else {
            this.curr_blen += block_len * last_merge_blocks
        }

        merge_forwards(mut array, curr_block, this.curr_blen, last_len, block_len)
    } else {
        block_swap(mut array, buf, curr_block, this.curr_blen)
    }
}

[direct_array_access]
fn (mut this GrailSort[T]) merge_blocks_lazy[T](mut array []T, first_k int, m_key int, a int, block_cnt int, block_len int, last_merge_blocks int, last_len int) {
    mut curr_block := 0
    mut next_block := a + block_len

    this.curr_blen  = block_len
    this.curr_borig = get_subarray(array, first_k, m_key)

    for k_idx in 1 .. block_cnt {
        curr_block  = next_block - this.curr_blen
        next_borig := get_subarray(array, first_k + k_idx, m_key)

        if next_borig == this.curr_borig {
            this.curr_blen = block_len
        } else {
            this.smart_merge_lazy(
                mut array, curr_block, this.curr_blen, 
                this.curr_borig, block_len
            )
        }

        next_block += block_len
    }

    curr_block = next_block - this.curr_blen

    if last_len != 0 {
        if this.curr_borig == Subarray.right {
            curr_block      = next_block
            this.curr_blen  = block_len * last_merge_blocks
            this.curr_borig = Subarray.left
        } else {
            this.curr_blen += block_len * last_merge_blocks
        }

        merge_lazy(mut array, curr_block, this.curr_blen, last_len)
    }
}

[direct_array_access]
fn (mut this GrailSort[T]) merge_blocks_oop[T](mut array []T, first_k int, m_key int, a int, block_cnt int, block_len int, last_merge_blocks int, last_len int) {
    mut buf        := 0
    mut curr_block := 0
    mut next_block := a + block_len

    this.curr_blen  = block_len
    this.curr_borig = get_subarray(array, first_k, m_key)

    for k_idx in 1 .. block_cnt {
        curr_block  = next_block - this.curr_blen
        next_borig := get_subarray(array, first_k + k_idx, m_key)

        if next_borig == this.curr_borig {
            buf = curr_block - block_len

            arraycopy(array, curr_block, mut array, buf, this.curr_blen)
            this.curr_blen = block_len
        } else {
            this.smart_merge_oop(
                mut array, curr_block, this.curr_blen, 
                this.curr_borig, block_len, block_len
            )
        }

        next_block += block_len
    }

    curr_block = next_block - this.curr_blen
    buf        = curr_block - block_len

    if last_len != 0 {
        if this.curr_borig == Subarray.right {
            arraycopy(array, curr_block, mut array, buf, this.curr_blen)

            curr_block      = next_block
            this.curr_blen  = block_len * last_merge_blocks
            this.curr_borig = Subarray.left
        } else {
            this.curr_blen += block_len * last_merge_blocks
        }

        merge_oop(mut array, curr_block, this.curr_blen, last_len, block_len)
    } else {
        arraycopy(array, curr_block, mut array, buf, this.curr_blen)
    }
}

[direct_array_access]
fn (mut this GrailSort[T]) combine_inplace[T](mut array []T, first_k int, a int, len int, sub_len int, block_len int, merge_cnt int, last_subs int, buf bool) {
    full_merge    := 2 * sub_len
    mut block_cnt := full_merge / block_len
    mut offs      := 0
    mut m_key     := 0

    for m_idx in 0 .. merge_cnt {
        offs = a + (m_idx * full_merge)

        insert_sort(mut array, first_k, block_cnt)

        m_key = sub_len / block_len
        m_key = block_select_sort(mut array, first_k, offs, m_key, block_cnt, block_len)

        if buf {
            this.merge_blocks(mut array, first_k, first_k + m_key, offs, block_cnt, block_len, 0, 0)
        } else {
            this.merge_blocks_lazy(mut array, first_k, first_k + m_key, offs, block_cnt, block_len, 0, 0)
        }
    }

    if last_subs != 0 {
        offs = a + (merge_cnt * full_merge)
        block_cnt = last_subs / block_len

        insert_sort(mut array, first_k, block_cnt + 1)

        m_key = sub_len / block_len
        m_key = block_select_sort(mut array, first_k, offs, m_key, block_cnt, block_len)

        last_frag             := last_subs - (block_cnt * block_len)
        mut last_merge_blocks := 0
        if last_frag != 0 {
            last_merge_blocks = count_last_merge_blocks(array, offs, block_cnt, block_len)
        }

        smart_merges := block_cnt - last_merge_blocks
        if smart_merges == 0 {
            ll := last_merge_blocks * block_len

            if buf {
                merge_forwards(mut array, offs, ll, last_frag, block_len)
            } else {
                merge_lazy(mut array, offs, ll, last_frag)
            }
        } else {
            if buf {
                this.merge_blocks(
                    mut array, first_k, first_k + m_key, offs, smart_merges,
                    block_len, last_merge_blocks, last_frag
                )
            } else {
                this.merge_blocks_lazy(
                    mut array, first_k, first_k + m_key, offs, smart_merges,
                    block_len, last_merge_blocks, last_frag
                )
            }
        }
    }

    if buf {
        buf_reset_inplace(mut array, a, len, block_len)
    }
}

[direct_array_access]
fn (mut this GrailSort[T]) combine_oop[T](mut array []T, first_k int, a int, len int, sub_len int, block_len int, merge_cnt int, last_subs int) {
    arraycopy(array, a - block_len, mut this.ext_buf, 0, block_len)

    full_merge    := 2 * sub_len
    mut block_cnt := full_merge / block_len
    mut offs      := 0
    mut m_key     := 0

    for m_idx in 0 .. merge_cnt {
        offs = a + (m_idx * full_merge)

        insert_sort(mut array, first_k, block_cnt)

        m_key = sub_len / block_len
        m_key = block_select_sort(mut array, first_k, offs, m_key, block_cnt, block_len)

        this.merge_blocks_oop(mut array, first_k, first_k + m_key, offs, block_cnt, block_len, 0, 0)
    }

    if last_subs != 0 {
        offs = a + (merge_cnt * full_merge)
        block_cnt = last_subs / block_len

        insert_sort(mut array, first_k, block_cnt + 1)

        m_key = sub_len / block_len
        m_key = block_select_sort(mut array, first_k, offs, m_key, block_cnt, block_len)

        last_frag             := last_subs - (block_cnt * block_len)
        mut last_merge_blocks := 0
        if last_frag != 0 {
            last_merge_blocks = count_last_merge_blocks(array, offs, block_cnt, block_len)
        }

        smart_merges := block_cnt - last_merge_blocks
        if smart_merges == 0 {
            ll := last_merge_blocks * block_len

            merge_oop(mut array, offs, ll, last_frag, block_len)
        } else {
            this.merge_blocks_oop(
                mut array, first_k, first_k + m_key, offs, smart_merges,
                block_len, last_merge_blocks, last_frag
            )
        }
    }

    buf_reset_oop(mut array, a, len, block_len)
    arraycopy(this.ext_buf, 0, mut array, a - block_len, block_len)
}

[direct_array_access]
fn (mut this GrailSort[T]) combine[T](mut array []T, first_k int, a int, l int, sub_len int, block_len int, buf bool) {
    mut len := l

    full_merge    := 2 * sub_len
    merge_cnt     := len / full_merge
    mut last_subs := len - (full_merge * merge_cnt)

    if last_subs <= sub_len {
        len -= last_subs
        last_subs = 0
    }

    if buf && block_len <= this.ext_buf_len {
        this.combine_oop(mut array, first_k, a, len, sub_len, block_len, merge_cnt, last_subs)
    } else {
        this.combine_inplace(mut array, first_k, a, len, sub_len, block_len, merge_cnt, last_subs, buf)
    }
}

fn lazy_stable_sort[T](mut array []T, a int, len int) {
    for i in 1 .. len {
        l := a + i - 1
        r := a + i

        if array[l] > array[r] {
            swap(mut array, l, r)
        }
    }

    for m_len := 2; m_len < len; m_len *= 2 {
        full_merge := 2 * m_len
        m_end      := len - full_merge
        mut m_idx  := 0
        
        for m_idx <= m_end {
            merge_lazy(mut array, a + m_idx, m_len, m_len)

            m_idx += full_merge
        }

        leftover := len - m_idx
        if leftover > m_len {
            merge_lazy(mut array, a + m_idx, m_len, leftover - m_len)
        }
    }
}

fn (mut this GrailSort[T]) sort[T](mut array []T, a int, len int, ext_buf_len int) {
    if len < 16 {
        insert_sort(mut array, a, len)
        return
    }

    mut block_len := 1
    for (block_len * block_len) < len {
        block_len *= 2
    }

    mut key_len   := ((len - 1) / block_len) + 1
    ideal         := key_len + block_len
    found         := collect_keys(mut array, a, len, ideal)
    mut ideal_buf := true

    if found < ideal {
        if found < 4 {
            lazy_stable_sort(mut array, a, len)
            return
        } else {
            key_len   = block_len
            block_len = 0
            ideal_buf = false

            for key_len > found {
                key_len /= 2
            }
        }
    }

    buf_end     := block_len + key_len
    mut sub_len := key_len
    if ideal_buf {
        sub_len = block_len
    }

    if ideal_buf && ext_buf_len != 0 {
        this.ext_buf_len = ext_buf_len
        this.oop         = true
    } else {
        this.oop = false
    }

    this.build_blocks(mut array, a + buf_end, len - buf_end, sub_len)

    for (len - buf_end) > (2  * sub_len) {
        sub_len *= 2

        mut curr_blen     := block_len
        mut scrolling_buf := ideal_buf

        if !ideal_buf {
            key_buf := key_len / 2

            if key_buf >= ((2 * sub_len) / key_buf) {
                curr_blen     = key_buf
                scrolling_buf = true
            } else {
                curr_blen = (2 * sub_len) / key_len
            }
        }

        this.combine(
            mut array, a, a + buf_end, len - buf_end, sub_len, 
            curr_blen, scrolling_buf
        )
    }

    insert_sort(mut array, a, buf_end)
    merge_lazy(mut array, a, buf_end, len - buf_end)
}

pub fn (mut this GrailSort[T]) sort_inplace[T](mut array []T, a int, len int) {
    this.sort(mut array, a, len, 0)
}

pub fn (mut this GrailSort[T]) sort_static_oop[T](mut array []T, a int, len int) {
    this.ext_buf = []T{len: static_ext_buf_len}
    this.sort(mut array, a, len, static_ext_buf_len)
}

pub fn (mut this GrailSort[T]) sort_dynamic_oop[T](mut array []T, a int, len int) {
    mut buf_len := 1
    for (buf_len * buf_len) < len {
        buf_len *= 2
    }

    this.ext_buf = []T{len: buf_len}
    this.sort(mut array, a, len, buf_len)
}

pub fn grailsort[T]() GrailSort[T] {
    return GrailSort[T] {}
}