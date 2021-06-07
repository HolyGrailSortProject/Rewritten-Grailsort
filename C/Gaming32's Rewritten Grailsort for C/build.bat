if %1.==debug. (
    gcc -Wall -Og -g test.c -o grail_test_dbg.exe
) else (
    gcc -O3 test.c -o grail_test.exe
)
