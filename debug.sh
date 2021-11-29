#!/bin/bash

MBR_IMG="crossword.img"
if [ -n "$1" ]
then
	MBR_IMG=$1
fi

( qemu-system-i386 -S -s -fda $MBR_IMG ) &
gdb

#wait -n
#pkill -P $$
