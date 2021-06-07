#include <stdlib.h>
#include "grail_sort.h"

#define ARRAY_LENGTH 65536

typedef struct {
    int value;
    int key;
} GrailPair;

int main() {
    GrailPair* array = malloc(ARRAY_LENGTH * sizeof(GrailPair));

    free(array);
    return 0;
}
