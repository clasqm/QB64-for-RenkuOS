#!/bin/sh
gcc -c ../../src/resample.c -o temp/resample.o
ar rcs src.a temp/resample.o
