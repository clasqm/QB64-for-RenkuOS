#!/bin/sh
g++ -c -w -Wall ../../src/Gamepad_haiku.c -o temp/Gamepad_haiku.o
g++ -c -w -Wall ../../src/Gamepad_private.c -o temp/Gamepad_private.o
ar rcs src.a temp/Gamepad_private.o temp/Gamepad_haiku.o
