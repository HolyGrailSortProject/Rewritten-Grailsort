use std::cmp::Ordering;
use std::fmt;

//GrailPair is a small struct which can be used for stability testing of the sort.
#[allow(dead_code)]
#[derive(Clone, Copy, Eq, Default)]
pub(crate) struct GrailPair {
    pub key: isize,
    pub value: isize,
}

impl fmt::Debug for GrailPair {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.key)
    }
}

//Manual implementation of Partial and Total Ordering for the GrailPair struct assures that key is the value
//compared between GrailPair objects, rather than the default implementation comparing every field.
impl Ord for GrailPair {
    fn cmp(&self, other: &Self) -> Ordering {
        self.key.cmp(&other.key)
    }
}

impl PartialOrd for GrailPair {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.key.cmp(&other.key))
    }
}

//Manual implementation of Partial Equality serves the same purpose as for Partial Ordering.
impl PartialEq for GrailPair {
    fn eq(&self, other: &Self) -> bool {
        self.key == other.key
    }
}
