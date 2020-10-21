use std::fmt;

//Creates a trait alias Sortable to combine the requirement for Partial Ordering, Partial Equality,
//and Copyable values into a single Trait.
//NOTE: Trait Aliasing as a proper feature is currently unstable, so this will not be required in
//later version of Rust, and be its own official feature in the language itself.
pub trait Sortable: Ord + Copy + fmt::Debug {}
impl<T: Ord + Copy + fmt::Debug> Sortable for T {}