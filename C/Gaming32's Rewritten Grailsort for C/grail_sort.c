void FUNC(grailInsertSort)(VAR* start, VAR* end, GRAILCMP cmp) {
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

void FUNC(grailCommonSort)(VAR* start, size_t length, VAR* extBuffer, size_t extBufferLen, GRAILCMP cmp) {
    VAR* end = start + length;
    if (length < 16) {
        FUNC(grailInsertSort)(start, end, cmp);
        return;
    }
}
