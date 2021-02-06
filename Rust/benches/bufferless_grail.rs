use criterion::{black_box, criterion_group, criterion_main, Criterion};
use grailsort::grailsort::*;
use rand::thread_rng;
use rand::seq::SliceRandom;

pub fn grailsort_bufferless_benchmark(c: &mut Criterion) {
    let len = 50_000;
    let mut rng = thread_rng();
    let mut set: Vec<isize> = (0..len).collect();
    set.shuffle(&mut rng);
    c.bench_function("bufferless grail", |x| x.iter(|| grail_sort(&mut set, black_box(len as usize))));
}

criterion_group!(benches, grailsort_bufferless_benchmark);
criterion_main!(benches);
