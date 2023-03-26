# Running tests
To perform testing, execute the `grailsort` folder:
```
v run grailsort
```
or, inside the folder:
```
v run .
```
you can also compile it using the `-prod` option for significantly better performance:
```
v -prod .
./grailsort
```
# Usage
```v
import grailsort

...

mut grail := grailsort.grailsort[Type]()
grail.sort_inplace(mut anArray, start, length)
grail.sort_static_oop(mut anArray, start, length)
grail.sort_dynamic_oop(mut anArray, start, length)
```
