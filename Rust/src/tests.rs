#[cfg(test)]
mod tests {
    use crate::grailpair::GrailPair;
    use crate::grailsort::*;
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
    fn bufferless_grail_by_value_random_sizes_random_values() {
        for _ in 0..12 {
            let mut rng = thread_rng();
            let len = rng.gen_range(17, 524288);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort_by(&mut set, len, |a, b| a.value.cmp(&b.value));
            verify_sort_values(&set);
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
    fn static_buffer_grail_by_value_random_sizes_random_values() {
        for _ in 0..12 {
            let mut rng = thread_rng();
            let len = rng.gen_range(17, 524288);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort_by_with_static_buffer(&mut set, len, |a, b| a.value.cmp(&b.value));
            verify_sort_values(&set);
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
    fn dynamic_buffer_grail_by_value_random_sizes_random_values() {
        for _ in 0..12 {
            let mut rng = thread_rng();
            let len = rng.gen_range(17, 524288);
            let mut set: Vec<GrailPair> = (0..len)
                .map(|x| GrailPair {
                    key: rng.gen_range(0, len as isize),
                    value: x as isize,
                })
                .collect();
            grail_sort_by_with_dynamic_buffer(&mut set, len, |a, b| a.value.cmp(&b.value));
            verify_sort_values(&set);
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
    fn verify_sort_values(set: &[GrailPair]) {
        for i in 1..set.len() {
            assert!(
                set[i].value >= set[i - 1].value,
                "indices {} and {} out of order; ({}, {})",
                i - 1,
                i,
                set[i - 1].value,
                set[i].value
            );
        }
    }
}
