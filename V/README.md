# Running tests
To perform testing, execute the `grailsort` folder:
```
v run grailsort
```
or, inside the folder:
```
v run .
```

# Usage
```v
import grailsort

...

mut grail := grailsort.grailsort[Type]()
grail.sort_inplace(mut anArray, start, stop)
grail.sort_static_oop(mut anArray, start, stop)
grail.sort_dynamic_oop(mut anArray, start, stop)
```