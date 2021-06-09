#include <stdlib.h>
#include <stdint.h>
#include <time.h>

#include "grail_sort.h"

#ifdef _WIN32 // or whatever
    #define ZU "%I64i"
#else
    #define ZU "%zu"
#endif

#define ARRAY_LENGTH 16777216
// #define ARRAY_LENGTH 16
// #define ARRAY_LENGTH 128

#define RANDOM_LIMIT RAND_MAX
// #define RANDOM_LIMIT 3

#define RANDOM_SEED time(NULL)

typedef struct {
    int key;
    int value;
} GrailPair;

int compare_qsort(const void* a, const void* b) {
    return *(int*)(a) - *(int*)(b);
}

int compare_grailsort(const void* a, const void* b) {
    return ((GrailPair*)(a))->key - ((GrailPair*)(b))->key;
}

void printGrailArray(GrailPair* array) {
    printf("[%i", array->key);
    for (size_t i = 1; i < ARRAY_LENGTH; i++) {
        printf(", %i", array[i].key);
    }
    printf("]\n");
}

size_t validateArrayWithCopy(GrailPair* initial, int* copy) {
    for (size_t i = 0; i < ARRAY_LENGTH; i++) {
        if (initial[i].key != copy[i]) {
            return i;
        }
    }
    return SIZE_MAX;
}

// assumes array is sorted
size_t validateArrayStable(GrailPair* array) {
    for (size_t i = 1; i < ARRAY_LENGTH; i++) {
        if (array[i].key < array[i - 1].key) {
            return i;
        }
    }
    return SIZE_MAX;
}

int main() {
    srand(RANDOM_SEED);

    printf("Initializing array...\n");
    GrailPair* array = malloc(ARRAY_LENGTH * sizeof(GrailPair));
    for (size_t i = 0; i < ARRAY_LENGTH; i++) {
        // array[i].key = (int)(rand() / (double)RAND_MAX * RANDOM_LIMIT);
        array[i].key = rand();
    }

    printf("Initializing empty counts...\n");
    size_t* counts = malloc((RAND_MAX + 1) * sizeof(size_t));
    for (size_t i = 0; i < RAND_MAX + 1; i++) {
        counts[i] = 0;
    }

    printf("Initializing stability values...\n");
    for (size_t i = 0; i < ARRAY_LENGTH; i++) {
        array[i].value = counts[array[i].key]++;
    }
    free(counts);

    printf("Copying array...\n");
    int* copy = malloc(ARRAY_LENGTH * sizeof(int));
    for (size_t i = 0; i < ARRAY_LENGTH; i++) {
        copy[i] = array[i].key;
    }

    printf("Sorting copy...\n\n");
    qsort(copy, ARRAY_LENGTH, sizeof(int), compare_qsort);

    printf("Sorting %i items...\n", ARRAY_LENGTH);
    clock_t start = clock();
    grailSortInPlace(array, ARRAY_LENGTH, sizeof(GrailPair), compare_grailsort);
    clock_t end = clock();
    printf("Done sorting in ~%f seconds.\n", (double)(end - start) / CLOCKS_PER_SEC);

    printf("Validating...\n");
    size_t validation = validateArrayWithCopy(array, copy);
    if (validation < SIZE_MAX) {
        printf("Sorted validation failed! array["ZU"] != copy["ZU"]\n", validation, validation);
        return 1;
    }
    printf("Sorted validation success!\n");

    validation = validateArrayStable(array);
    if (validation < SIZE_MAX) {
        printf("Stability validation failed! array["ZU"] > array["ZU"]\n", validation - 1, validation);
        return 2;
    }
    printf("Stability validation success!\n");

    free(array);
    free(copy);
    return 0;
}
