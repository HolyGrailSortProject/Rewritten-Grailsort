import rand
import math
import arrays
import benchmark
import grailsort

const (
	prepare_iters = 64
	prepare_len   = 65536
	n_tests       = 128
	test_per_len  = 8
	min_len       = 15
	max_len       = 1 << 20
)

pub struct Value {
	pub:
	value int

	pub mut:
	key int
}

fn (a Value) < (b Value) bool {
	return a.value < b.value
}

fn (a Value) == (b Value) bool {
	return a.value == b.value
}

fn gen_array(len int, unique int) ![]Value {
	mut array := []Value{}

	for i in 0 .. unique {
		for _ in 0 .. len / unique {
			array << Value {
				value: i
			}
		}
	}

	for i in 0 .. array.len {
		r := rand.int_in_range(i, array.len)!
		tmp     := array[i]
		array[i] = array[r]
		array[r] = tmp
	}

	for i in 0 .. array.len {
		array[i].key = i
	}

	return array
}

fn get_test_array(len int) ![]Value {
	return gen_array(len, len / 4)!
}

fn get_few_unique_test_array(len int) ![]Value {
	return gen_array(len, rand.int_in_range(min_len, int(f64_max(math.sqrt(len) / 4, f64(min_len + 1))))!)!
}

fn check(array []Value, reference []Value) bool {
	for i in 1 .. array.len {
		if array[i - 1] > array[i] {
			println("Indices ${i - 1} and ${i} are out of order.")
			return false
		} 

		if array[i - 1] == array[i] && array[i - 1].key > array[i].key {
			println("Indices ${i - 1} and ${i} are unstable.")
			return false
		}

		if array[i] != reference[i] {
			println("Index ${i} does not match reference.")
			return false
		}
	}

	return true
}

fn prepare(len int) !grailsort.GrailSort[Value] {
	mut array     := get_test_array(len)!
	mut reference := []Value{len: array.len}
	arrays.copy(mut reference, array)
	reference.sort()

	mut grail := grailsort.grailsort[Value]()
	
	println("Preparing...")
	for _ in 0 .. prepare_iters {
		mut test_array := []Value{len: array.len}

		arrays.copy(mut test_array, array)
		grail.sort_inplace(mut test_array, 0, len)

		arrays.copy(mut test_array, array)
		grail.sort_static_oop(mut test_array, 0, len)

		arrays.copy(mut test_array, array)
		grail.sort_dynamic_oop(mut test_array, 0, len)
	}

	return grail
}

fn test(
	mut bench &benchmark.Benchmark, mut array []Value, 
	mut test_array []Value, reference []Value,
	mut grail &grailsort.GrailSort[Value]
) {
	arrays.copy(mut test_array, array)
	bench.step()
	grail.sort_inplace(mut test_array, 0, test_array.len)
	bench.ok()

	if check(test_array, reference) {
		println(bench.step_message_ok("Grail In-Place"))
	} else {
		panic(bench.step_message_fail("Grail In-Place"))
	}

	arrays.copy(mut test_array, array)
	bench.step()
	grail.sort_static_oop(mut test_array, 0, test_array.len)
	bench.ok()

	if check(test_array, reference) {
		println(bench.step_message_ok("Grail OOP with Static buffer"))
	} else {
		panic(bench.step_message_fail("Grail In-Place"))
	}

	arrays.copy(mut test_array, array)
	bench.step()
	grail.sort_dynamic_oop(mut test_array, 0, test_array.len)
	bench.ok()

	if check(test_array, reference) {
		println(bench.step_message_ok("Grail OOP with Dynamic buffer"))
	} else {
		panic(bench.step_message_fail("Grail In-Place"))
	}
}

fn test_all(
	mut bench &benchmark.Benchmark, mut array []Value,
	mut grail &grailsort.GrailSort[Value]
) {
	println("------------------\nLength: ${array.len}")

	mut test_array := []Value{len: array.len}
	mut reference  := []Value{len: array.len}

	arrays.copy(mut reference, array)
	bench.step()
	reference.sort()
	bench.ok()
	println(bench.step_message_ok("Default V sorter"))

	for _ in 0 .. test_per_len {
		test(mut bench, mut array, mut test_array, reference, mut grail)
	}
}

fn main() {
	mut grail := prepare(prepare_len) or {
		panic(err)
	}

	mut bench := benchmark.new_benchmark()
	mut array := []Value{}

	for _ in 0 .. n_tests {
		bench = benchmark.new_benchmark()
		array = get_test_array(rand.int_in_range(min_len, max_len) or {
			panic(err)
		}) or {
			panic(err)
		}

		test_all(mut bench, mut array, mut grail)
	}

	println("Testing few unique.")

	for _ in 0 .. n_tests {
		bench = benchmark.new_benchmark()
		array = get_few_unique_test_array(rand.int_in_range(min_len, max_len) or {
			panic(err)
		}) or {
			panic(err)
		}

		test_all(mut bench, mut array, mut grail)
	}
}