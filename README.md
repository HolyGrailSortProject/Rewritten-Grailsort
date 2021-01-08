# The Rewritten Grailsort repo
A diverse array of heavily refactored versions of Andrey Astrelin's GrailSort.h, aiming to be as readable and intuitive as possible. *Owned and maintained by The Holy Grail Sort Project.*

# Current implementations featured in our repo:
* Summer Dragonfly et al.'s Rewritten Grailsort for **Java** (ALL TESTS PASSING / POTENTIALLY FIXED) 
* 666666t's Rewritten Grailsort for **Rust**
* thatsOven's Rewritten Grailsort for **Python**
* Enver's Rewritten Grailsort for **JavaScript**
* Summer Dragonfly's *Simple* Rewritten Grailsort for **C**
* _fluffyy's Rewritten Grailsort for **Python**
* DeveloperSort's Minor Edits to Summer... et al.'s Rewritten Grailsort for **Java**
* *more to come!*

# What is Grailsort?
__TL;DR__: Grailsort is a complicated variant of Mergesort that manages to cram all the extra space usually needed by Mergesorts *inside* the array with a bit of magic involving square roots and unequal numbers!

**The full story**: Grailsort is an *in-place, stable, worst-case O(n log n) time* variant of Mergesort and implementation of 'Block Merge Sort'.

The algorithm starts by attempting to collect (2 * sqrt(n)) unique elements at the beginning of the array. One-half of this collection serves as an internal buffer that traverses through the list, merging subarrays of increasing length each iteration. When the length of these subarrays no longer fits inside the buffer, the subarrays are then broken down into blocks of size sqrt(n) and swapped to approximate places, using the other half of said unique elements as 'keys' to tag potential swaps of equal elements. Afterwards, the internal buffer is left to finish a 'local merge' of said blocks together. This entire process continues as a bottom-up merge until all subarrays are combined, and finally the collection of unique elements are merged back into the rest of the array without a buffer.

Choosing the length O(sqrt(n)) for blocks and key-buffers allows for assistance from simple O(n^2) algorithms, including Insertion and Selection Sort, whose time complexities equate to O(sqrt(n)^2), simplifying down to an optimal O(n) time. 'Situationally optimal' complexities are of particular importance when an array to be sorted does not have (2 * sqrt(n)) unique elements. Without enough 'keys', Grailsort may not have either a large enough buffer for 'local merges' or enough 'block swapping' tags to guarantee stability, or both. In these cases, normally suboptimal in-place merge sorts based on rotations are instead used to still achieve a stable and O(n log n) worst-case sort, without using any extra space.

# Why rewrite it?
Andrey Astrelin was a genius when it came to not only understanding and implementing the ideas behind Grailsort, but also with writing extremely compact code.

Unfortunately, Andrey's original implementation is incredibly hard to read and intuit... Don't believe us? Go ahead and take a look for yourself: https://github.com/Mrrl/GrailSort/blob/master/GrailSort.h. In fact, Grailsort was being considered as one of the included sorting algorithms for the Rust programming language, but the contributors agreed that the lack of documentation was daunting (https://github.com/rust-lang/rust/issues/19221 and https://github.com/rust-lang/rfcs/pull/956#issuecomment-78504506).

But then you might ask, "why bother with Grailsort? We've already found the best sorting algorithms you can get in computer science; the problem of sorting is already solved...".

Well hold on, now! When has it ever been a bad idea to "think deeply about simple things"? Our team has learned a lot about sorting and algorithms in general by spending many hours collectively uncovering the secrets behind Grailsort, some of which are extremely clever and deep. It's a passion project for us, after all, and we would like to share it with other programmers and computer enthusiasts out there.

Not only that, our team has found a ton of potential in Grailsort, and so did the researchers who wrote its original paper back in the late 1980s! According to *Fast Stable Merging and Sorting in Constant Extra Space* written by Huang and Langston,

> "...[Grailsort guarantees] a worst-case key-comparison and record-exchange grand total not greater than 2.5*n*log2*n*. [Grailsort's] worst-case total compares favourably with   *average-case* key-comparison and record-exchange totals for popular *unstable* methods: quick-sort's average-case figure is a little more than 1.4*n*log2*n*; heap-sort's is     about 2.3*n*log2*n*."
  
The paper is linked in this repo for reference.

Now, there *are* some glaring flaws with Grailsort, but they're now easier than ever to study and optimize! This is only the beginning of our little project, and we hope you enjoy our hard work. :)

# Helpful resources
- Original implementation of Grailsort: https://github.com/Mrrl/GrailSort
- Rough English translation of Mr. Astrelin's Grailsort blog post: https://translate.google.com/translate?sl=auto&tl=en&u=https%3A%2F%2Fhabr.com%2Fen%2Fpost%2F205290%2F
- Academic paper that Grailsort is based off of: http://comjnl.oxfordjournals.org/content/35/6/643.full.pdf (*Also uploaded to this repo!*)
- Grailsort animations I've made for research purposes: https://www.youtube.com/playlist?list=PL5w_-zMAJC8sF-bThVsDGthPcxJktuUNm
- Official version of Wikisort, a similar algorithm also based off of "Block Merge Sort": https://github.com/BonzaiThePenguin/WikiSort
- Academic paper that Wikisort is based off of: https://github.com/BonzaiThePenguin/WikiSort/blob/master/tamc2008.pdf
- Official Wikipedia for Block (Merge) Sort: https://en.wikipedia.org/wiki/Block_sort
- *Full documentation/educational lessons on Grailsort and Block Merge Sorting coming soon!!*

Visit our **Discord guild** for **project updates** and **behind-the-scenes content**: https://discord.com/invite/2xGkKC2

# The Holy Grail Sort Project
 * Project Manager:
   * Summer Dragonfly / MusicTheorist
 * Project Contributors:
   * 666666t
   * Anonymous0726
   * aphitorite
   * dani_dlg
   * DeveloperSort
   * EilrahcF
   * Enver
   * lovebuny
   * Morwenn
   * MP
   * phoenixbound
   * thatsOven
   * _fluffyy
 * Special thanks to "The Studio" Discord community!

# Dedicated to Mr. Andrey Astrelin, 1969 - 2017
http://superliminal.com/andrey/biography.html

Rest in Peace Andrey Astrelin
