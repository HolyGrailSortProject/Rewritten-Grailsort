static void FUNC(grailBlockSwap)(VAR* a, VAR* b, size_t blockLen) {
    for (size_t i = 0; i < blockLen; i++) {
        VAR tmp = *a;
        *a++ = *b;
        *b++ = tmp;
    }
}

static void FUNC(grailRotate)(VAR* start, size_t leftLen, size_t rightLen) {
    while (leftLen > 0 && rightLen > 0) {
        if (leftLen <= rightLen) {
            FUNC(grailBlockSwap)(start, start + leftLen, leftLen);
            start    += leftLen;
            rightLen -= leftLen;
        } else {
            FUNC(grailBlockSwap)(start + leftLen - rightLen, start + leftLen, rightLen);
            leftLen -= rightLen;
        }
    }
}

// Variant of Insertion Sort that utilizes swaps instead of overwrites.
// Also known as "Optimized Gnomesort".
static void FUNC(grailInsertSort)(VAR* start, VAR* end, GRAILCMP cmp) {
    for (VAR* item = start + 1; item < end; item++) {
        VAR* left = item - 1;
        VAR* right = item;

        while (left >= start && cmp(left, right) > 0) {
            VAR tmp = *left;
            *left-- = *right;
            *right-- = tmp;
        }
    }
}

static size_t FUNC(grailBinarySearchLeft)(VAR* start, size_t length, VAR* target, GRAILCMP cmp) {
    size_t  left = 0;
    size_t right = length;

    while (left < right) {
        // equivalent to (left + right) / 2 with added overflow protection
        size_t middle = left + ((right - left) / 2);

        if (cmp(start + middle, target) < 0) {
            left = middle + 1;
        } else {
            right = middle;
        }
    }
    return left;
}

static size_t FUNC(grailBinarySearchRight)(VAR* start, size_t length, VAR* target, GRAILCMP cmp) {
    size_t  left = 0;
    size_t right = length;

    while (left < right) {
        size_t middle = left + ((right - left) / 2);

        if (cmp(start + middle, target) > 0) {
            right = middle;
        } else {
            left = middle + 1;
        }
    }

    return right;
}

// cost: 2 * length + idealKeys^2 / 2
static size_t FUNC(grailCollectKeys)(VAR* start, VAR* end, size_t idealKeys, GRAILCMP cmp) {
    size_t keysFound = 1;         // by itself, the first item in the array is our first unique key
    VAR*    firstKey = start;     // the first item in the array is at the first position in the array
    VAR*     currKey = start + 1; // the index used for finding potentially unique items ("keys") in the array

    while (currKey < end && keysFound < idealKeys) {

        // Find the location in the key-buffer where our current key can be inserted in sorted order.
        // If the key at insertPos is equal to currKey, then currKey isn't unique and we move on.
        size_t insertPos = FUNC(grailBinarySearchLeft)(firstKey, keysFound, currKey, cmp);

        if (insertPos == keysFound || cmp(currKey, firstKey + insertPos) != 0) {

            FUNC(grailRotate)(firstKey, keysFound, currKey - (firstKey + keysFound));

            firstKey = currKey - keysFound;

            // FUNC(grailRotate)(firstKey + insertPos, keysFound - insertPos, 1);
            VAR tmp = firstKey[keysFound];
            memmove(firstKey + insertPos + 1, firstKey + insertPos, sizeof(VAR) * (keysFound - insertPos));
            firstKey[insertPos] = tmp;

            keysFound++;
        }

        currKey++;
    }

    FUNC(grailRotate)(start, firstKey - start, keysFound);
    return keysFound;
}

static void FUNC(grailLazyMerge)(VAR* start, size_t leftLen, size_t rightLen, GRAILCMP cmp) {
    if (leftLen < rightLen) {
        VAR* middle = start + leftLen;

        while (leftLen != 0) {
            size_t mergeLen = FUNC(grailBinarySearchLeft)(middle, rightLen, start, cmp);

            if (mergeLen != 0) {
                FUNC(grailRotate)(start, leftLen, mergeLen);

                start    += mergeLen;
                middle   += mergeLen;
                rightLen -= mergeLen;
            }

            if (rightLen == 0) {
                break;
            } else {
                do {
                    start++;
                    leftLen--;
                } while (leftLen != 0 && cmp(start, middle) <= 0);
            }
        }
    } else {
        VAR* end = start + leftLen + rightLen - 1;

        while (rightLen != 0) {
            size_t mergeLen = FUNC(grailBinarySearchRight)(start, leftLen, end, cmp);

            if (mergeLen != leftLen) {
                FUNC(grailRotate)(start + mergeLen, leftLen - mergeLen, rightLen);

                end    -= leftLen - mergeLen;
                leftLen = mergeLen;
            }

            if (leftLen == 0) {
                break;
            } else {
                VAR* middle = start + leftLen;
                do {
                    rightLen--;
                    end--;
                } while (rightLen != 0 && cmp(middle - 1, end) <= 0);
            }
        }
    }
}

static void FUNC(grailLazyStableSort)(VAR* start, size_t length, GRAILCMP cmp) {
    VAR* end = start + length;
    for (VAR *left = start, *right = start + 1; right < end; left += 2, right += 2) {
        if (cmp(left, right) > 0) {
            VAR tmp = *left;
            *left = *right;
            *right = tmp;
        }
    }
    for (size_t mergeLen = 2; mergeLen < length; mergeLen *= 2) {
        size_t fullMerge = 2 * mergeLen;

        size_t mergeIndex;
        size_t mergeEnd = length - fullMerge + 1;

        for (mergeIndex = 0; mergeIndex <= mergeEnd; mergeIndex += fullMerge) {
            FUNC(grailLazyMerge)(start + mergeIndex, mergeLen, mergeLen, cmp);
        }

        size_t leftOver = length - mergeIndex;
        if (leftOver > mergeLen) {
            FUNC(grailLazyMerge)(start + mergeIndex, mergeLen, leftOver - mergeLen, cmp);
        }
    }
}

static void FUNC(grailCommonSort)(VAR* start, size_t length, VAR* extBuffer, size_t extBufferLen, GRAILCMP cmp) {
    VAR* end = start + length;
    if (length < 16) {
        FUNC(grailInsertSort)(start, end, cmp);
        return;
    }

    size_t blockLen = 1;

    // find the smallest power of two greater than or equal to
    // the square root of the input's length
    while (blockLen * blockLen < length) {
        blockLen <<= 1;
    }

    // '((a - 1) / b) + 1' is actually a clever and very efficient
    // formula for the ceiling of (a / b)
    //
    // credit to Anonymous0726 for figuring this out!
    size_t keyLen = ((length - 1) / blockLen) + 1;

    // Grailsort is hoping to find `2 * sqrt(n)` unique items
    // throughout the array
    size_t idealKeys = keyLen + blockLen;

    size_t keysFound = FUNC(grailCollectKeys)(start, end, idealKeys, cmp);

    bool idealBuffer;
    if (keysFound < idealKeys) {
        if (keysFound < 4) {
            FUNC(grailLazyStableSort)(start, length, cmp);
            return;
        }
    }
}
