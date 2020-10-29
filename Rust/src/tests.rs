#[cfg(test)]
mod tests {
    use crate::grailpair::GrailPair;
    use crate::grailsort::*;
    use crate::sortable::Sortable;
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

    #[test]
    fn insert_sort_random_sizes_random_values() {
        for _ in 0..100 {
            let mut rng = thread_rng();
            let len = rng.gen_range(2, 512);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_insertion_sort(&mut set, 0, len);
            verify_sort(&set);
        }
    }

    #[test]
    fn collect_keys_random_sizes_random_values() {
        for _ in 0..100 {
            let mut rng = thread_rng();
            let len = rng.gen_range(2, 262144);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();

            let (keys_found, ideal_keys, _key_len, _block_len) =
                match bufferless_common_sort_to_collect(&mut set, len) {
                    GrailStage::Collect {
                        keys_found,
                        ideal_keys,
                        key_len,
                        block_len,
                    } => (keys_found, ideal_keys, key_len, block_len),
                    _ => panic!("No call other than collect_keys should have returned"),
                };

            for i in 1..keys_found {
                assert!(
                    set[i] > set[i - 1],
                    "Collected Values Out Of Order: {:?}, {:?}, ({}, {})",
                    set[i - 1],
                    set[i],
                    i - 1,
                    i
                );
                assert!(
                    set[i] != set[i - 1],
                    "Collected Values are Equal, {:?}, {:?}, ({}, {})",
                    set[i - 1],
                    set[i],
                    i - 1,
                    i
                );
            }
            assert!(keys_found <= ideal_keys, "Too Many Keys Collected");
        }
    }

    #[test]
    fn build_blocks_random_sizes_random_values() {
        for _ in 0..100 {
            let mut rng = thread_rng();
            let len = rng.gen_range(2, 262144);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            let (_strategy, _keys_found, _key_len, buffer_end, subarray_len, _ideal_buffer, _block_len) =
                match bufferless_common_sort_to_build(&mut set, len) {
                    GrailStage::Build {
                        strategy,
                        keys_found,
                        key_len,
                        buffer_end,
                        subarray_len,
                        ideal_buffer,
                        block_len,
                    } => (
                        strategy,
                        keys_found,
                        key_len,
                        buffer_end,
                        subarray_len,
                        ideal_buffer,
                        block_len,
                    ),
                    _ => panic!("No call other than build_blocks should have returned"),
                };
            let mut cursor = buffer_end + 1;
            while cursor < len {
                if (cursor - buffer_end) % subarray_len != 0 {
                    assert!(
                        set[cursor] >= set[cursor - 1],
                        "Built Fragment Out Of Order: {:?}, {:?}, ({}, {})",
                        set[cursor - 1],
                        set[cursor],
                        cursor - 1,
                        cursor
                    );
                    if set[cursor] == set[cursor - 1] {
                        assert!(
                            set[cursor].value > set[cursor - 1].value,
                            "Buit Fragment Is Unstable!: {:?}, {:?}, ({}, {})",
                            set[cursor - 1],
                            set[cursor],
                            cursor - 1,
                            cursor
                        );
                    }
                }
                cursor += 1;
            }
        }
    }

    #[test]
    fn combine_blocks_random_sizes_random_values() {
        for _ in 0..100 {
            let mut rng = thread_rng();
            let len = rng.gen_range(2, 262144);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            let buffer_end = match bufferless_common_sort_to_combine(&mut set, len) {
                GrailStage::Combine { buffer_end } => buffer_end,
                _ => panic!("No call other than build_blocks should have returned"),
            };

            let mut cursor = buffer_end + 1; 
            while cursor < len {
                assert!(
                    set[cursor] >= set[cursor - 1],
                    "Built Fragment Out Of Order: {:?}, {:?}, ({} {})",
                    set[cursor - 1],
                    set[cursor],
                    cursor - 1,
                    cursor
                );
                if set[cursor] == set[cursor - 1] {
                    assert!(
                        set[cursor].value > set[cursor - 1].value,
                        "Built Fragment Is Unstable!: {:?}, {:?}, ({}, {})",
                        set[cursor - 1],
                        set[cursor],
                        cursor - 1,
                        cursor
                    );
                }
                cursor += 1;
            }
        }
    }

    #[test]
    fn final_insertion_random_sizes_random_values() {
        for _ in 0..100 {
            let mut rng = thread_rng();
            let len = rng.gen_range(2, 262144);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            let buffer_end = match bufferless_common_sort_to_final_insert(&mut set, len) {
                GrailStage::FinalInsert { buffer_end } => buffer_end,
                _ => panic!("No call other than build_blocks should have returned"),
            };

            let mut cursor = 1; 
            while cursor < buffer_end {
                assert!(
                    set[cursor] >= set[cursor - 1],
                    "Built Fragment Out Of Order: {:?}, {:?}, ({} {})",
                    set[cursor - 1],
                    set[cursor],
                    cursor - 1,
                    cursor
                );
                if set[cursor] == set[cursor - 1] {
                    assert!(
                        set[cursor].value > set[cursor - 1].value,
                        "Built Fragment Is Unstable!: {:?}, {:?}, ({}, {})",
                        set[cursor - 1],
                        set[cursor],
                        cursor - 1,
                        cursor
                    );
                }
                cursor += 1;
            }
        }
    }

    //NOTE: There is no test for the final grail_lazy_merge call,
    //as verifying such is equivalent to verifying the actual sort, which every other test does.

    #[allow(dead_code)]
    enum GrailStage {
        Collect {
            keys_found: usize,
            ideal_keys: usize,
            key_len: usize,
            block_len: usize,
        },
        Build {
            strategy: Strategy,
            keys_found: usize,
            key_len: usize,
            buffer_end: usize,
            subarray_len: usize,
            ideal_buffer: bool,
            block_len: usize,
        },
        Combine {
            buffer_end: usize,
        },
        FinalInsert {
            buffer_end: usize,
        },
        FinalLazy {
            buffer_end: usize,
        },
    }
    #[allow(dead_code)]
    enum Strategy {
        IdealBuffer,
        PartialBuffer,
        LazyStable,
    }

    #[allow(dead_code)]
    fn bufferless_common_sort_to_collect<T: Sortable>(set: &mut [T], length: usize) -> GrailStage {
        let mut block_len = 1;
        while block_len * block_len < length {
            block_len *= 2;
        }

        let key_len = ((length - 1) / block_len) + 1;

        let ideal_keys = key_len + block_len;

        let keys_found = grail_collect_keys(set, 0, length, ideal_keys);

        GrailStage::Collect {
            keys_found,
            ideal_keys,
            key_len,
            block_len,
        }
    }

    #[allow(dead_code)]
    fn bufferless_common_sort_to_build<T: Sortable>(set: &mut [T], length: usize) -> GrailStage {
        let (keys_found, ideal_keys, mut key_len, mut block_len) =
            match bufferless_common_sort_to_collect(set, length) {
                GrailStage::Collect {
                    keys_found,
                    ideal_keys,
                    key_len,
                    block_len,
                } => (keys_found, ideal_keys, key_len, block_len),
                _ => panic!("Incorrect stage encountered during grailsort test execution"),
            };

        let ideal_buffer;
        let strategy;

        if keys_found < ideal_keys {
            if keys_found < 4 {
                grail_lazy_stable_sort(set, 0, length);
                strategy = Strategy::LazyStable;
                return GrailStage::Build {
                    strategy,
                    keys_found,
                    key_len,
                    buffer_end: 0,
                    subarray_len: 0,
                    ideal_buffer: false,
                    block_len: 0,
                };
            } else {
                key_len = block_len;
                block_len = 0;

                ideal_buffer = false;
                strategy = Strategy::PartialBuffer;

                while key_len > keys_found {
                    key_len /= 2;
                }
            }
        } else {
            ideal_buffer = true;
            strategy = Strategy::IdealBuffer;
        }

        let buffer_end = block_len + key_len;
        let subarray_len = if ideal_buffer { block_len } else { key_len };

        grail_build_blocks(
            set,
            &mut None,
            buffer_end,
            length - buffer_end,
            subarray_len,
        );

        GrailStage::Build {
            strategy,
            keys_found,
            key_len,
            buffer_end,
            subarray_len,
            ideal_buffer,
            block_len,
        }
    }

    #[allow(dead_code)]
    fn bufferless_common_sort_to_combine<T: Sortable>(set: &mut [T], length: usize) -> GrailStage {
        let (_strategy, keys_found, key_len, buffer_end, mut subarray_len, ideal_buffer, block_len) =
            match bufferless_common_sort_to_build(set, length) {
                GrailStage::Build {
                    strategy,
                    keys_found,
                    key_len,
                    buffer_end,
                    subarray_len,
                    ideal_buffer,
                    block_len,
                } => (
                    strategy,
                    keys_found,
                    key_len,
                    buffer_end,
                    subarray_len,
                    ideal_buffer,
                    block_len,
                ),
                _ => panic!("Incorrect stage encountered during grailsort test execution"),
            };

        while length - buffer_end > 2 * subarray_len {
            subarray_len *= 2;
            let mut current_block_len = block_len;
            let mut scrolling_buffer = ideal_buffer;
            if !ideal_buffer {
                let half_key_len = key_len / 2;
                if half_key_len * half_key_len >= 2 * subarray_len {
                    current_block_len = half_key_len;
                    scrolling_buffer = true;
                } else {
                    let block_keys_sum = (subarray_len * keys_found) / 2;
                    let min_keys = calc_min_keys(key_len, block_keys_sum);

                    current_block_len = (2 * subarray_len) / min_keys;
                }
            }
            grail_combine_blocks(
                set,
                &mut None,
                0,
                buffer_end,
                length - buffer_end,
                subarray_len,
                current_block_len,
                scrolling_buffer,
            );
        }
        GrailStage::Combine { buffer_end }
    }

    #[allow(dead_code)]
    fn bufferless_common_sort_to_final_insert<T: Sortable>(
        set: &mut [T],
        length: usize,
    ) -> GrailStage {
        let buffer_end = match bufferless_common_sort_to_combine(set, length) {
            GrailStage::Combine { buffer_end } => buffer_end,
            _ => panic!("Incorrect stage encountered during grailsort test execution"),
        };
        grail_insertion_sort(set, 0, buffer_end);
        GrailStage::FinalInsert { buffer_end }
    }

    #[allow(dead_code)]
    fn bufferless_common_sort_to_final_merge<T: Sortable>(
        set: &mut [T],
        length: usize,
    ) -> GrailStage {
        let buffer_end = match bufferless_common_sort_to_final_insert(set, length) {
            GrailStage::FinalInsert { buffer_end } => buffer_end,
            _ => panic!("Incorrect stage encountered during grailsort test execution"),
        };
        grail_lazy_merge(set, 0, buffer_end, length - buffer_end);
        GrailStage::FinalLazy { buffer_end }
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
