This C++14 Rewritten Grailsort is mostly a mechanical rewrite of Summer Dragonfly's Java implementation.
It provides the following two function templatess to run grailsort with or without an additional buffer:

```cpp
template<
    typename RandomAccessIterator,
    typename Compare = std::less<>
>
void grailsort(RandomAccessIterator first, RandomAccessIterator last, Compare comp={});

template<
    typename RandomAccessIterator1,
    typename RandomAccessIterator2,
    typename Compare = std::less<>
>
void grailsort(RandomAccessIterator1 first, RandomAccessIterator1 last,
               RandomAccessIterator2 buff_first, RandomAccessIterator2 buff_last,
               Compare comp={});
```

This C++ port is really just a mechnical rewrite and  has not been optimized in any specific way, so it
should not perform better than the original C implementation.
