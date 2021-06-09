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

static size_t FUNC(grailCollectKeys)(VAR* start, VAR* end, size_t idealKeys, GRAILCMP cmp) {
    size_t keysFound = 1;
    VAR*    firstKey = start;
    VAR*     currKey = start + 1;

    while (currKey < end && keysFound < idealKeys) {
        size_t insertPos = FUNC(grailBinarySearchLeft)(firstKey, keysFound, currKey, cmp);

        if (insertPos == keysFound || cmp(currKey, firstKey + insertPos) != 0) {
            FUNC(grailRotate)(firstKey, keysFound, currKey - (firstKey + keysFound));

            firstKey = currKey - keysFound;

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

static void FUNC(grailPairwiseSwaps)(VAR* start, size_t length, GRAILCMP cmp) {
    VAR tmp;
    size_t index;
    for (index = 1; index < length; index += 2) {
        VAR*  left = start + index - 1;
        VAR* right = start + index;

        if (cmp(left, right) > 0) {
            tmp = left[-2];
            left[-2] = *right;
            *right = tmp;

            tmp = right[-2];
            right[-2] = *left;
            *left = tmp;
        } else {
            tmp = left[-2];
            left[-2] = *left;
            *left = tmp;

            tmp = right[-2];
            right[-2] = *right;
            *right = tmp;
        }
    }

    VAR* left = start + index - 1;
    if (left < start + length) {
        tmp = left[-2];
        left[-2] = *left;
        *left = tmp;
    }
}

static void FUNC(grailPairwiseWrites)(VAR* start, size_t length, GRAILCMP cmp) {
    size_t index;
    for (index = 1; index < length; index += 2) {
        VAR*  left = start + index - 1;
        VAR* right = start + index;

        if (cmp(left, right) > 0) {
            left[ -2] = *right;
            right[-2] = *left;
        } else {
            left[ -2] = *left;
            right[-2] = *right;
        }
    }

    VAR* left = start + index - 1;
    if (left < start + length) {
        left[-2] = *left;
    }
}

static void FUNC(grailMergeForwards)(VAR* start, size_t leftLen, size_t rightLen, size_t bufferOffset, GRAILCMP cmp) {
    VAR* buffer = start  - bufferOffset;
    VAR*   left = start;
    VAR* middle = start  + leftLen;
    VAR*  right = middle;
    VAR*    end = middle + rightLen;

    VAR tmp;
    while (right < end) {
        if (left == middle || cmp(left, right) > 0) {
            tmp = *buffer;
            *buffer++ = *right;
            *right++ = tmp;
        } else {
            tmp = *buffer;
            *buffer++ = *left;
            *left++ = tmp;
        }
    }

    if (buffer != left) {
        FUNC(grailBlockSwap)(buffer, left, middle - left);
    }
}

static void FUNC(grailMergeBackwards)(VAR* start, size_t leftLen, size_t rightLen, size_t bufferOffset, GRAILCMP cmp) {
    VAR*    end = start - 1;
    VAR*   left = end   + leftLen;
    VAR* middle = left;
    VAR*  right = middle + rightLen;
    VAR* buffer = right + bufferOffset;

    VAR tmp;
    while (left > end) {
        if (right == middle || cmp(left, right) > 0) {
            tmp = *buffer;
            *buffer-- = *left;
            *left-- = tmp;
        } else {
            tmp = *buffer;
            *buffer-- = *right;
            *right-- = tmp;
        }
    }

    if (right != buffer) {
        while (right > middle) {
            tmp = *buffer;
            *buffer-- = *right;
            *right-- = tmp;
        }
    }
}

static void FUNC(grailMergeOutOfPlace)(VAR* start, size_t leftLen, size_t rightLen, size_t bufferOffset, GRAILCMP cmp) {
    VAR* buffer = start  - bufferOffset;
    VAR*   left = start;
    VAR* middle = start  + leftLen;
    VAR* right = middle;
    VAR*   end = middle + rightLen;

    while (right < end) {
        if (left == middle || cmp(left, right) > 0) {
            *buffer++ = *right++;
        } else {
            *buffer++ = *left++;
        }
    }

    if (buffer != left) {
        while (left < middle) {
            *buffer++ = *left++;
        }
    }
}

static void FUNC(grailBuildInPlace)(VAR* start, size_t length, size_t currentLen, size_t bufferLen, GRAILCMP cmp) {
    for (size_t mergeLen = currentLen; mergeLen < bufferLen; mergeLen *= 2) {
        size_t fullMerge = 2 * mergeLen;

        VAR* mergeIndex;
        VAR* mergeEnd = start + length - fullMerge;
        size_t bufferOffset = mergeLen;

        for (mergeIndex = start; mergeIndex <= mergeEnd; mergeIndex += fullMerge) {
            FUNC(grailMergeForwards)(mergeIndex, mergeLen, mergeLen, bufferOffset, cmp);
        }

        size_t leftOver = length - (mergeIndex - start);

        if (leftOver > mergeLen) {
            FUNC(grailMergeForwards)(mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset, cmp);
        } else {
            FUNC(grailRotate)(mergeIndex - mergeLen, mergeLen, leftOver);
        }

        start -= mergeLen;
    }

    size_t fullMerge  = 2 * bufferLen;
    size_t lastBlock  = length & (fullMerge - 1); // equivalent to modulo, but faster (only works if fullMerge is a power of 2, which it is)
    VAR*   lastOffset = start + length - lastBlock;

    if (lastBlock <= bufferLen) {
        FUNC(grailRotate)(lastOffset, lastBlock, bufferLen);
    } else {
        FUNC(grailMergeBackwards)(lastOffset, bufferLen, lastBlock - bufferLen, bufferLen, cmp);
    }

    for (VAR* mergeIndex = lastOffset - fullMerge; mergeIndex >= start; mergeIndex -= fullMerge) {
        FUNC(grailMergeBackwards)(mergeIndex, bufferLen, bufferLen, bufferLen, cmp);
    }
}

static void FUNC(grailBuildOutOfPlace)(VAR* start, size_t length, size_t bufferLen, VAR* extBuffer, size_t extLen, GRAILCMP cmp) {
    memcpy(extBuffer, start - extLen, sizeof(VAR) * extLen);

    FUNC(grailPairwiseWrites)(start, length, cmp);
    start -= 2;

    size_t mergeLen;
    for (mergeLen = 2; mergeLen < extLen; mergeLen *= 2) {
        size_t fullMerge = 2 * mergeLen;

        VAR* mergeIndex;
        VAR* mergeEnd = start + length - fullMerge;
        size_t bufferOffset = mergeLen;

        for (mergeIndex = start; mergeIndex <= mergeEnd; mergeIndex += fullMerge) {
            FUNC(grailMergeOutOfPlace)(mergeIndex, mergeLen, mergeLen, bufferOffset, cmp);
        }

        size_t leftOver = length - (mergeIndex - start);

        if (leftOver > mergeLen) {
            FUNC(grailMergeOutOfPlace)(mergeIndex, mergeLen, leftOver - mergeLen, bufferOffset, cmp);
        }
        else {
            memmove(mergeIndex - mergeLen, mergeIndex, sizeof(VAR) * leftOver);
        }

        start -= mergeLen;
    }

    memcpy(start + length, extBuffer, sizeof(VAR) * extLen);
    FUNC(grailBuildInPlace)(start, length, mergeLen, bufferLen, cmp);
}

static void FUNC(grailBuildBlocks)(VAR* start, size_t length, size_t bufferLen, VAR* extBuffer, size_t extBufferLen, GRAILCMP cmp) {
    if (extBuffer != NULL) {
        size_t extLen;

        if (bufferLen < extBufferLen) {
            extLen = bufferLen;
        } else {
            extLen = 1;
            while ((extLen * 2) <= extBufferLen) {
                extLen *= 2;
            }
        }

        FUNC(grailBuildOutOfPlace)(start, length, bufferLen, extBuffer, extLen, cmp);
    } else {
        FUNC(grailPairwiseSwaps)(start, length, cmp);
        FUNC(grailBuildInPlace)(start - 2, length, 2, bufferLen, cmp);
    }
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

    while ((blockLen * blockLen) < length) {
        blockLen *= 2;
    }

    size_t keyLen = ((length - 1) / blockLen) + 1;

    size_t idealKeys = keyLen + blockLen;

    size_t keysFound = FUNC(grailCollectKeys)(start, end, idealKeys, cmp);

    bool idealBuffer;
    if (keysFound < idealKeys) {
        if (keysFound < 4) {
            FUNC(grailLazyStableSort)(start, length, cmp);
            return;
        } else {
            keyLen = blockLen;
            blockLen = 0;
            idealBuffer = false;

            while (keyLen > keysFound) {
                keyLen /= 2;
            }
        }
    } else {
        idealBuffer = true;
    }

    size_t bufferEnd = blockLen + keyLen;
    size_t subarrayLen;
    if (idealBuffer) {
        subarrayLen = blockLen;
    } else {
        subarrayLen = keyLen;
    }

    FUNC(grailBuildBlocks)(start + bufferEnd, length - bufferEnd, subarrayLen, extBuffer, extBufferLen, cmp);
    return;

    while ((length - bufferEnd) > (2 * subarrayLen)) {
        subarrayLen *= 2;

        size_t currentBlockLen = blockLen;
        bool scrollingBuffer = idealBuffer;

        if (!idealBuffer) {
            size_t keyBuffer = keyLen / 2;

            if (keyBuffer >= ((2 * subarrayLen) / keyBuffer)) {
                currentBlockLen = keyBuffer;
                scrollingBuffer = true;
            }
            else {
                currentBlockLen = (2 * subarrayLen) / keyLen;
            }
        }
    }
}
