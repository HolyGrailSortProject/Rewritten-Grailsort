# Grailsort-Cython

## Compiling

To compile `grailsort.pyx`, you must have a Python development kit with Cython installed (for more info, jump to <a href="#python-development-kit">Python Development Kit</a>). You must also have a C compiler installed.

You can simply use the included build script (`setup.py`) to build the extension easily:

```shell
$ python3 ./setup.py build_ext --inplace
running build_ext
building 'grailsort' extension
creating build/temp.linux-x86_64-3.8
x86_64-linux-gnu-gcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -g -fwrapv -O2 -Wall -g -fstack-protector-strong -Wformat -Werror=format-security -g -fwrapv -O2 -g -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -fPIC -I/usr/include/python3.8 -c grailsort.c -o build/temp.linux-x86_64-3.8/grailsort.o
creating build/lib.linux-x86_64-3.8
x86_64-linux-gnu-gcc -pthread -shared -Wl,-O1 -Wl,-Bsymbolic-functions -Wl,-Bsymbolic-functions -Wl,-z,relro -g -fwrapv -O2 -Wl,-Bsymbolic-functions -Wl,-z,relro -g -fwrapv -O2 -g -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 build/temp.linux-x86_64-3.8/grailsort.o -o build/lib.linux-x86_64-3.8/grailsort.cpython-38-x86_64-linux-gnu.so
copying build/lib.linux-x86_64-3.8/grailsort.cpython-38-x86_64-linux-gnu.so -> 
```

### Python Development Kit

#### Windows

On Windows, Python comes with most of the development tools already installed, however, you still need `wheel` and `setuptools`:

```shell
$ py -m pip install -U wheel setuptools
Requirement already up-to-date: wheel in c:\python39\lib\site-packages (0.36.2)
Requirement already up-to-date: setuptools in c:\python39\lib\site-packages (51.2.0)
```

#### Ubuntu/Debian

On Ubuntu/Debian, you can install the `python3-dev` package from apt:

```shell
$ sudo apt install python3-dev
Reading package lists...
Building dependency tree...
Reading state information...
python3-dev is already the newest version (3.8.2-0ubuntu2).
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
```

## Using from Python

Simply import the `grailsort` module (after compiling it of course) and create an instance of the `GrailSort` class. Currently, the only available API for running the sort is the `grailCommonSort` method of `GrailSort` instances.

`GrailSort.grailCommonSort(self, array: list, start: int, length: int, extBuffer: Union[None, list], extBufferLen: int)`
