/*
 * Grailsort.h
 *
 *  Created on: Oct 25, 2020
 *      Author: John
 */

#include <stdbool.h>

#ifndef GRAILSORT_H_
#define GRAILSORT_H_

#define GRAIL_STATIC_EXT_BUF_LEN 512

long comps;

typedef struct GrailPair {
    int key;
    int val;
} GrailPair;

typedef enum GrailSortSubarray {
    GRAILSORT_SUBARRAY_LEFT  = 0,
    GRAILSORT_SUBARRAY_RIGHT = 1
} GrailSortSubarray;

static inline int grail_compare(const GrailPair* a, const GrailPair* b) {
    comps++;

    if      (a->key < b->key) return -1;
    else if (a->key > b->key) return  1;
    else                      return  0;
}

static inline void grail_swap(GrailPair* a, GrailPair* b) {
    GrailPair temp = *a;
                *a = *b;
                *b = temp;
}

static inline void grail_block_swap(GrailPair* a, GrailPair* b, int block_len) {
    for(int i = 0; i < block_len; i++) {
        grail_swap(a + i, b + i);
    }
}

static inline void grail_in_place_buffer_reset(GrailPair* array, int start, int reset_len, int buffer_len) {
    for(int index = start + reset_len - 1; index >= start; index--) {
        grail_swap(array + index, array + (index - buffer_len));
    }
}

static inline void grail_out_of_place_buffer_reset(GrailPair* array, int start, int reset_len, int buffer_len) {
    for(int index = start + reset_len - 1; index >= start; index--) {
        *(array + index) = *(array + (index - buffer_len));
    }
}

static inline void grail_in_place_buffer_rewind(GrailPair* array, int start, int left_overs, int buffer) {
    while(left_overs > start) {
        left_overs--;
        buffer--;
        grail_swap(array + buffer, array + left_overs);
    }
}

static inline void grail_out_of_place_buffer_rewind(GrailPair* array, int start, int left_overs, int buffer) {
    while(left_overs > start) {
        left_overs--;
        buffer--;
        *(array + buffer) = *(array + left_overs);
    }
}

static inline GrailSortSubarray grail_get_subarray(GrailPair* current_key, GrailPair* median_key) {
    if(grail_compare(current_key, median_key) < 0) {
        return GRAILSORT_SUBARRAY_LEFT;
    }
    else {
        return GRAILSORT_SUBARRAY_RIGHT;
    }
}

static inline int calc_min_keys(int num_keys, long long block_keys_sum) {
    int min_keys = 1;
    while(min_keys < num_keys && block_keys_sum != 0) {
        min_keys *= 2;
        block_keys_sum /= 8;
    }
    return min_keys;
}

void grail_rotate(GrailPair* array, int start, int left_len, int right_len);
void grail_insert_sort(GrailPair* array, int start, int length);

int  grail_binary_search_left(GrailPair* array, int start, int length, GrailPair target);
int  grail_binary_search_right(GrailPair* array, int start, int length, GrailPair target);
int  grail_collect_keys(GrailPair* array, int start, int length, int ideal_keys);

void grail_pairwise_swaps(GrailPair* array, int start, int length);
void grail_pairwise_writes(GrailPair* array, int start, int length);

void grail_merge_forwards(GrailPair* array, int start, int left_len, int right_len, int buffer_offset);
void grail_merge_backwards(GrailPair* array, int start, int left_len, int right_len, int buffer_offset);
void grail_merge_out_of_place(GrailPair* array, int start, int left_len, int right_len, int buffer_offset);

void grail_build_in_place(GrailPair* array, int start, int length, int current_merge, int buffer_len);
void grail_build_out_of_place(GrailPair* array, int start, int length, int buffer_len, GrailPair* ext_buffer, int extern_len);
void grail_build_blocks(GrailPair* array, int start, int length, int buffer_len, GrailPair* ext_buffer, int ext_buf_len);

int  grail_block_select_sort(GrailPair* array, int keys, int start, int median_key, int block_count, int block_len);
int  grail_count_final_left_blocks(GrailPair* array, int offset, int block_count, int block_len);

void grail_smart_merge(GrailPair* array, int start, int* left_len, GrailSortSubarray* left_origin, int right_len, int buffer_offset);
void grail_smart_lazy_merge(GrailPair* array, int start, int* left_len, GrailSortSubarray* left_origin, int right_len);
void grail_smart_merge_out_of_place(GrailPair* array, int start, int* left_len, GrailSortSubarray* left_origin, int right_len, int buffer_offset);

void grail_merge_blocks(GrailPair* array, int keys, int median_key, int start, int block_count, int block_len, int final_left_blocks, int final_len);
void grail_lazy_merge_blocks(GrailPair* array, int keys, int median_key, int start, int block_count, int block_len, int final_left_blocks, int final_len);
void grail_merge_blocks_out_of_place(GrailPair* array, int keys, int median_key, int start, int block_count, int block_len, int final_left_blocks, int final_len);

void grail_combine_in_place(GrailPair* array, int keys, int start, int length, int subarray_len, int block_len, int merge_count, int last_subarray, bool buffer);
void grail_combine_out_of_place(GrailPair* array, int keys, int start, int length, int subarray_len, int block_len, int merge_count, int last_subarray, GrailPair* ext_buffer);
void grail_combine_blocks(GrailPair* array, int keys, int start, int length, int subarray_len, int block_len, bool buffer, GrailPair* ext_buffer, int ext_buf_len);

void grail_lazy_merge(GrailPair* array, int start, int left_len, int right_len);
void grail_lazy_stable_sort(GrailPair* array, int start, int length);

void grail_common_sort(GrailPair* array, int start, int length, GrailPair* ext_buffer, int ext_buf_len);

void grail_sort_in_place(GrailPair* array, int start, int length);
void grail_sort_static_OOP(GrailPair* array, int start, int length);
void grail_sort_dynamic_OOP(GrailPair* array, int start, int length);

#endif /* GRAILSORT_H_ */
