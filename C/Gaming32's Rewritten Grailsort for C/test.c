#include <stdlib.h>
#include <time.h>

#include "grail_sort.h"

// #define ARRAY_LENGTH 65536
#define ARRAY_LENGTH 16

// #define RANDOM_LIMIT ARRAY_LENGTH
// #define RANDOM_LIMIT RAND_MAX
#define RANDOM_LIMIT 3

#define RANDOM_SEED time(NULL)

typedef struct {
    int value;
    int key;
} GrailPair;

int compare_qsort(const void* a, const void* b) {
    return *(int*)(a) - *(int*)(b);
}

int compare_grailsort(const void* a, const void* b) {
    return ((GrailPair*)(a))->value - ((GrailPair*)(b))->value;
}

void printGrailArray(GrailPair* array) {
    printf("[%i", array->value);
    for (size_t i = 1; i < ARRAY_LENGTH; i++) {
        printf(", %i", array[i].value);
    }
    printf("]\n");
}

int main() {
    srand(RANDOM_SEED);

    GrailPair* array = malloc(ARRAY_LENGTH * sizeof(GrailPair));
    for (size_t i = 0; i < ARRAY_LENGTH; i++) {
        array[i].value = (int)(rand() / (double)RAND_MAX * RANDOM_LIMIT);
    }

    size_t* counts = malloc(RAND_MAX * sizeof(size_t));
    for (size_t i = 0; i < RAND_MAX; i++) {
        counts[i] = 0;
    }
    for (size_t i = 0; i < ARRAY_LENGTH; i++) {
        array[i].key = counts[i]++;
    }
    free(counts);

    int* copy = malloc(ARRAY_LENGTH * sizeof(int));
    for (size_t i = 0; i < ARRAY_LENGTH; i++) {
        copy[i] = array[i].value;
    }
    qsort(copy, ARRAY_LENGTH, sizeof(int), compare_qsort);

    printGrailArray(array);
    grailSortInPlace(array, ARRAY_LENGTH, sizeof(GrailPair), compare_grailsort);
    printGrailArray(array);

    free(array);
    return 0;
}
