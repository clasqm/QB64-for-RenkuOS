#!/bin/sh
gcc -c ../../src/minimp3.c -o temp/minimp3.o
ar rcs src.a temp/minimp3.o
