from grailsort import GrailSort
import random
import math

LENGTH = 4096
UNIQUE = LENGTH
# UNIQUE = int(math.sqrt(LENGTH))
# UNIQUE = 2


l = []
for i in range(UNIQUE):
    for j in range(LENGTH // UNIQUE):
        l.append(i)
random.shuffle(l)


gs = GrailSort()
gs.grailCommonSort(l, 0, LENGTH, None, 0)


broke = None
for i in range(1, LENGTH):
    if l[i - 1] > l[i]:
        broke = i - 1
        break


if broke is None:
    print('The array was sorted!')
else:
    print('Indices', broke, 'and', broke + 1, 'were out of order!')
