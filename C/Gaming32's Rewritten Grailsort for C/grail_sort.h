#ifndef GRAILSORT_H
#define GRAILSORT_H

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <errno.h>

#ifdef __INTELLISENSE__
    #pragma diag_suppress 28 // This suppresses the "expression must have a constant value" on line 181
#endif

#define GRAIL_STATIC_EXT_BUFFER_LEN 512

typedef int GRAILCMP (const void *a, const void *b);

#define swap_two(array, swap)  \
{  \
	if (cmp(array, array + 1) > 0)  \
	{  \
		swap = array[1]; array[1] = array[0]; array[0] = swap;  \
	}  \
}

#define swap(type, a, b) {type c = *(a); *(a) = *(b); *(b) = c;}

//////////////////////////////////////////////////////////
//┌────────────────────────────────────────────────────┐//
//│                █████┐    ██████┐ ██████┐████████┐  │//
//│               ██┌──██┐   ██┌──██┐└─██┌─┘└──██┌──┘  │//
//│               └█████┌┘   ██████┌┘  ██│     ██│     │//
//│               ██┌──██┐   ██┌──██┐  ██│     ██│     │//
//│               └█████┌┘   ██████┌┘██████┐   ██│     │//
//│                └────┘    └─────┘ └─────┘   └─┘     │//
//└────────────────────────────────────────────────────┘//
//////////////////////////////////////////////////////////

#undef VAR
#undef FUNC
#undef STRUCT

#define VAR char
#define FUNC(NAME) NAME##8
#define STRUCT(NAME) struct NAME##8

#include "grail_sort.c"

//////////////////////////////////////////////////////////
//┌────────────────────────────────────────────────────┐//
//│           ▄██┐   █████┐    ██████┐ ██████┐████████┐│//
//│          ████│  ██┌───┘    ██┌──██┐└─██┌─┘└──██┌──┘│//
//│          └─██│  ██████┐    ██████┌┘  ██│     ██│   │//
//│            ██│  ██┌──██┐   ██┌──██┐  ██│     ██│   │//
//│          ██████┐└█████┌┘   ██████┌┘██████┐   ██│   │//
//│          └─────┘ └────┘    └─────┘ └─────┘   └─┘   │//
//└────────────────────────────────────────────────────┘//
//////////////////////////////////////////////////////////

#undef VAR
#undef FUNC
#undef STRUCT

#define VAR short
#define FUNC(NAME) NAME##16
#define STRUCT(NAME) struct NAME##16

#include "grail_sort.c"

//////////////////////////////////////////////////////////
// ┌───────────────────────────────────────────────────┐//
// │       ██████┐ ██████┐    ██████┐ ██████┐████████┐ │//
// │       └────██┐└────██┐   ██┌──██┐└─██┌─┘└──██┌──┘ │//
// │        █████┌┘ █████┌┘   ██████┌┘  ██│     ██│    │//
// │        └───██┐██┌───┘    ██┌──██┐  ██│     ██│    │//
// │       ██████┌┘███████┐   ██████┌┘██████┐   ██│    │//
// │       └─────┘ └──────┘   └─────┘ └─────┘   └─┘    │//
// └───────────────────────────────────────────────────┘//
//////////////////////////////////////////////////////////

#undef VAR
#undef FUNC
#undef STRUCT

#define VAR int
#define FUNC(NAME) NAME##32
#define STRUCT(NAME) struct NAME##32

#include "grail_sort.c"

//////////////////////////////////////////////////////////
// ┌───────────────────────────────────────────────────┐//
// │        █████┐ ██┐  ██┐   ██████┐ ██████┐████████┐ │//
// │       ██┌───┘ ██│  ██│   ██┌──██┐└─██┌─┘└──██┌──┘ │//
// │       ██████┐ ███████│   ██████┌┘  ██│     ██│    │//
// │       ██┌──██┐└────██│   ██┌──██┐  ██│     ██│    │//
// │       └█████┌┘     ██│   ██████┌┘██████┐   ██│    │//
// │        └────┘      └─┘   └─────┘ └─────┘   └─┘    │//
// └───────────────────────────────────────────────────┘//
//////////////////////////////////////////////////////////

#undef VAR
#undef FUNC
#undef STRUCT

#define VAR long long
#define FUNC(NAME) NAME##64
#define STRUCT(NAME) struct NAME##64

#include "grail_sort.c"

//////////////////////////////////////////////////////////
//┌────────────────────────────────────────────────────┐//
//│  ▄██┐  ██████┐  █████┐    ██████┐ ██████┐████████┐ │//
//│ ████│  └────██┐██┌──██┐   ██┌──██┐└─██┌─┘└──██┌──┘ │//
//│ └─██│   █████┌┘└█████┌┘   ██████┌┘  ██│     ██│    │//
//│   ██│  ██┌───┘ ██┌──██┐   ██┌──██┐  ██│     ██│    │//
//│ ██████┐███████┐└█████┌┘   ██████┌┘██████┐   ██│    │//
//│ └─────┘└──────┘ └────┘    └─────┘ └─────┘   └─┘    │//
//└────────────────────────────────────────────────────┘//
//////////////////////////////////////////////////////////

#undef VAR
#undef FUNC
#undef STRUCT

#define VAR long double
#define FUNC(NAME) NAME##128
#define STRUCT(NAME) struct NAME##128

#include "grail_sort.c"


/////////////////////////////////////////////////////////////////////////////////
//┌───────────────────────────────────────────────────────────────────────────┐//
//│    ██████╗ ██████╗  █████╗ ██╗██╗     ███████╗ ██████╗ ██████╗ ████████╗  │//
//│   ██╔════╝ ██╔══██╗██╔══██╗██║██║     ██╔════╝██╔═══██╗██╔══██╗╚══██╔══╝  │//
//│   ██║  ███╗██████╔╝███████║██║██║     ███████╗██║   ██║██████╔╝   ██║     │//
//│   ██║   ██║██╔══██╗██╔══██║██║██║     ╚════██║██║   ██║██╔══██╗   ██║     │//
//│   ╚██████╔╝██║  ██║██║  ██║██║███████╗███████║╚██████╔╝██║  ██║   ██║     │//
//│    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝     │//
//└───────────────────────────────────────────────────────────────────────────┘//
/////////////////////////////////////////////////////////////////////////////////


void grailCommonSort(void *array, size_t nelements, void *extBuffer, size_t extBufferLen, size_t elemsize, GRAILCMP *cmp)
{
	if (nelements < 2)
	{
		return;
	}

	switch (elemsize)
	{
		case sizeof(char):
			return grailCommonSort8(array, nelements, extBuffer, extBufferLen, cmp);

		case sizeof(short):
			return grailCommonSort16(array, nelements, extBuffer, extBufferLen, cmp);

		case sizeof(int):
			return grailCommonSort32(array, nelements, extBuffer, extBufferLen, cmp);

		case sizeof(long long):
			return grailCommonSort64(array, nelements, extBuffer, extBufferLen, cmp);

#ifndef _WIN32
		case sizeof(long double):
			return grailCommonSort128(array, nelements, extBuffer, extBufferLen, cmp);
#endif

		default:
			return assert(elemsize == sizeof(char) || elemsize == sizeof(short) || elemsize == sizeof(int) || elemsize == sizeof(long long) || elemsize == sizeof(long double));
	}
}

void grailSortInPlace(void *array, size_t nelements, size_t elemsize, GRAILCMP *cmp) {
    grailCommonSort(array, nelements, NULL, 0, elemsize, cmp);
}

void grailSortStaticOOP(void *array, size_t nelements, size_t elemsize, GRAILCMP *cmp) {
    char buffer[GRAIL_STATIC_EXT_BUFFER_LEN * elemsize];
    grailCommonSort(array, nelements, (void*)buffer, GRAIL_STATIC_EXT_BUFFER_LEN, elemsize, cmp);
}

void grailSortStaticOOP(void *array, size_t nelements, size_t elemsize, GRAILCMP *cmp) {
    size_t bufferLen = 1;
    while (bufferLen * bufferLen < nelements) {
        bufferLen *= 2;
    }
    void* buffer = malloc(bufferLen * elemsize);
    grailCommonSort(array, nelements, buffer, bufferLen, elemsize, cmp);
    free(buffer);
}

#undef VAR
#undef FUNC
#undef STRUCT

#endif
